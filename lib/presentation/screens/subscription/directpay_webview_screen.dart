import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DirectPayWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String successPrefix; // e.g. https://YOUR_DOMAIN/payments/success
  final String failedPrefix;  // e.g. https://YOUR_DOMAIN/payments/failed

  const DirectPayWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.successPrefix,
    required this.failedPrefix,
  });

  @override
  State<DirectPayWebViewScreen> createState() => _DirectPayWebViewScreenState();
}

class _DirectPayWebViewScreenState extends State<DirectPayWebViewScreen> {
  late final WebViewController _c;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final url = req.url;

            if (url.startsWith(widget.successPrefix)) {
              _finish(true, url);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(widget.failedPrefix)) {
              _finish(false, url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _finish(bool success, String url) async {
    if (_finishing) return;
    _finishing = true;

    final uri = Uri.parse(url);
    final orderId = uri.queryParameters["orderId"] ?? "";

    Navigator.pop(context, {"success": success, "orderId": orderId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Payment")),
      body: WebViewWidget(controller: _c),
    );
  }
}