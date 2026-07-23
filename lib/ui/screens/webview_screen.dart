import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/neon_button.dart';

/// In-app browser for the Privacy Policy and Support pages. Styled AppBar,
/// loading indicator, error handling with retry, and a locked-down navigation
/// policy that only allows the intended host.
class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool whiteBackground;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.whiteBackground = false,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.whiteBackground ? Colors.white : PrismColors.bg0,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted && err.isForMainFrame == true) {
              setState(() {
                _error = true;
                _loading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            final allowedHost = Uri.parse(widget.url).host;
            final target = Uri.tryParse(request.url);
            if (target != null && target.host == allowedHost) {
              return NavigationDecision.navigate;
            }
            // Block navigation to any other host.
            return NavigationDecision.prevent;
          },
        ),
      );
    _load();
  }

  void _load() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.whiteBackground ? Colors.white : PrismColors.bg0,
      appBar: AppBar(
        backgroundColor: PrismColors.bg1,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeonBack(onTap: () => Navigator.of(context).pop()),
          ),
        ),
        title: Text(widget.title, style: PrismText.title(20)),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: PrismGradients.backdrop),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (!_error) WebViewWidget(controller: _controller),
            if (_loading && !_error)
              const Center(
                child: CircularProgressIndicator(color: PrismColors.cyan),
              ),
            if (_error) _ErrorView(onRetry: _load),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PrismColors.bg0,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: PrismColors.magenta,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text('Could not load page', style: PrismText.title(20)),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: PrismText.body(14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: NeonButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
