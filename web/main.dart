import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../lib/firebase_options.dart';

// ---------------------------------------------------------------------------
// PUSH NOTIFICATIONS — background/terminated handler
// Must be a top-level (or static) function, annotated with vm:entry-point so
// Android can invoke it in its own isolate when the app is killed. It can
// stay empty: as long as the Cloud Function sends a `notification: {...}`
// payload (functions/index.js already does), Android shows the system tray
// notification automatically without this handler doing anything.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal — see comment above.
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'vedo_default_channel',
  'Vedo notifications',
  description: 'Timetable, doubts, fees and homework alerts from Vedo.',
  importance: Importance.high,
);

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await _initLocalNotifications();
  runApp(const VedoApp());
}

class VedoApp extends StatelessWidget {
  const VedoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vedo',
      home: VedoWebView(),
    );
  }
}

class VedoWebView extends StatefulWidget {
  const VedoWebView({super.key});

  @override
  State<VedoWebView> createState() => _VedoWebViewState();
}

class _VedoWebViewState extends State<VedoWebView> {
  late final WebViewController controller;
  bool isLoading = true;
  String? _cachedFcmToken;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _loadApp();
    _setupPushNotifications();
  }

  Future<void> _loadApp() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'FlutterGoogleAuth',
        onMessageReceived: (JavaScriptMessage message) {
          _handleGoogleSignInRequest();
        },
      )
      // The web app calls FlutterFcmBridge.postMessage('ready') once it's
      // mounted (and again right after login) to ask for the current FCM
      // token — see the matching useEffect in index.html's AuthProvider.
      ..addJavaScriptChannel(
        'FlutterFcmBridge',
        onMessageReceived: (JavaScriptMessage message) {
          if (_cachedFcmToken != null) _sendTokenToWeb(_cachedFcmToken!);
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => isLoading = false),
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            _loadOffline();
          }
        },
      ))
      ..loadRequest(Uri.parse('https://member2vedo.github.io/vedo/'));
    setState(() {});
  }

  Future<void> _loadOffline() async {
    final html = await rootBundle.loadString('assets/index.html');
    await controller.loadHtmlString(html,
        baseUrl: 'https://member2vedo.github.io');
  }

  // ---------------------------------------------------------------------
  // PUSH NOTIFICATIONS
  // ---------------------------------------------------------------------
  Future<void> _setupPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // Android 13+ shows the POST_NOTIFICATIONS runtime dialog here too;
    // iOS shows its native alert/badge/sound prompt.
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _cachedFcmToken = await messaging.getToken();
    // In case the web page already sent its 'ready' ping before we had a
    // token cached (race on cold start), send it now too.
    if (_cachedFcmToken != null) _sendTokenToWeb(_cachedFcmToken!);

    messaging.onTokenRefresh.listen((newToken) {
      _cachedFcmToken = newToken;
      _sendTokenToWeb(newToken);
    });

    // Foreground messages don't auto-show a system notification on Android,
    // so we show one ourselves.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  Future<void> _sendTokenToWeb(String token) async {
    final js =
        'window.onFlutterFcmToken && window.onFlutterFcmToken(${jsonEncode(token)});';
    try {
      await controller.runJavaScript(js);
    } catch (_) {
      // Web page not ready yet — it will ask again via FlutterFcmBridge.
    }
  }

  // Optional deep-link hook: if index.html defines
  //   window.onFlutterNotificationTap = (path) => { /* navigate */ };
  // tapping a notification routes straight to that screen. Safe no-op
  // otherwise.
  void _handleNotificationTap(RemoteMessage message) {
    final path = message.data['path'];
    if (path == null) return;
    final js =
        'window.onFlutterNotificationTap && window.onFlutterNotificationTap(${jsonEncode(path)});';
    controller.runJavaScript(js).catchError((_) {});
  }

  Future<void> _handleGoogleSignInRequest() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        await _sendResultToWeb(success: false, error: 'cancelled');
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        await _sendResultToWeb(
            success: false, error: 'no_id_token_returned');
        return;
      }

      await _sendResultToWeb(
        success: true,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    } catch (e) {
      await _sendResultToWeb(success: false, error: e.toString());
    }
  }

  Future<void> _sendResultToWeb({
    required bool success,
    String? idToken,
    String? accessToken,
    String? error,
  }) async {
    final payload = jsonEncode({
      'success': success,
      'idToken': idToken,
      'accessToken': accessToken,
      'error': error,
    });
    final js = 'window.onFlutterGoogleAuth && window.onFlutterGoogleAuth($payload);';
    await controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 16),
                    Text('Loading Vedo...',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 14)),
                  ],
                ),
              )
            : WebViewWidget(controller: controller),
      ),
    );
  }
}