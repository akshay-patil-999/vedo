import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() => runApp(const VedoApp());

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

  // Use the default client id from google-services.json automatically;
  // no need to hardcode anything here on Android.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _loadApp();
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
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => isLoading = false),
        onWebResourceError: (_) => _loadOffline(),
      ))
      ..loadRequest(Uri.parse('https://member2vedo.github.io/vedo/'));
    setState(() {});
  }

  Future<void> _loadOffline() async {
    final html = await rootBundle.loadString('assets/index.html');
    await controller.loadHtmlString(html,
        baseUrl: 'https://member2vedo.github.io');
  }

  // Triggered when the web page calls: FlutterGoogleAuth.postMessage('login')
  Future<void> _handleGoogleSignInRequest() async {
    try {
      await _googleSignIn.signOut(); // ensure account picker shows every time
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

  // Calls a JS function defined in index.html with the sign-in result.
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