import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';

class BoltzScreen extends StatefulWidget {
  const BoltzScreen({super.key});

  @override
  State<BoltzScreen> createState() => _BoltzScreenState();
}

class _BoltzScreenState extends State<BoltzScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      // Only initialize WebView on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = error.description;
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse('https://boltz.exchange/'));
      } else {
        // For web and other platforms, show fallback
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'WebView not supported on this platform';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _launchBoltz() async {
    final Uri url = Uri.parse('https://boltz.exchange/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text(
          'Boltz',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D47),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          if (_controller != null && !_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _controller?.reload();
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1D47),
              Color(0xFF2D3FE7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError || _controller == null) {
      // Fallback UI for unsupported platforms or errors
      return _buildFallbackUI();
    }

    return Stack(
      children: [
        // WebView
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: WebViewWidget(controller: _controller!),
            ),
          ),
        ),
        
        // Loading indicator
        if (_isLoading)
          Container(
            color: const Color(0xFF0F1419).withValues(alpha: 0.9),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3FE7)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.boltz_loading,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackUI() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Boltz logo placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.currency_exchange,
              size: 60,
              color: Color(0xFF2D3FE7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          const Text(
            'Boltz',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            AppLocalizations.of(context)!.boltz_description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.boltz_webview_error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: Colors.orange.shade200,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Launch button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _launchBoltz();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.boltz_error_opening(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3FE7),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.boltz_open_button,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.open_in_browser,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info text
          Text(
            kIsWeb || !(Platform.isAndroid || Platform.isIOS) 
                ? AppLocalizations.of(context)!.boltz_external_browser
                : AppLocalizations.of(context)!.boltz_within_app,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}