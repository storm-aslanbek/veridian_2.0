import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:veridian/services/webview/webview_platform_setup.dart';

class AssauTenderHelperScreen extends StatefulWidget {
  const AssauTenderHelperScreen({super.key});

  @override
  State<AssauTenderHelperScreen> createState() => _AssauTenderHelperScreenState();
}

class _AssauTenderHelperScreenState extends State<AssauTenderHelperScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    ensureWebViewPlatformInitialized();

    final controller = WebViewController();

    if (!kIsWeb) {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
          ),
        );
    }

    controller.loadRequest(Uri.parse('https://assau-tender.online'));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assau Tender Helper'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}