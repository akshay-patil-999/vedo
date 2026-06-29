import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://member2vedo.github.io/vedo/'));
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
                    Text(
                      'Loading Vedo...',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : WebViewWidget(controller: controller),
      ),
    );
  }
}