import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wallet_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

// Constants for UI dimensions and styling
class _InvoiceKeyScreenConstants {
  // Padding and spacing
  static const double horizontalContentPadding = 24.0;
  static const double verticalHeaderPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double smallSpacing = 8.0;

  // QR Code sizing
  static const double qrContainerPadding = 20.0;
  static const double qrSize = 220.0;
  static const double qrBorderRadius = 20.0;

  // Container sizing
  static const double keyInfoPadding = 16.0;
  static const double keyInfoBorderRadius = 16.0;
  static const double backButtonRadius = 12.0;

  // Shadow
  static const double shadowBlurRadius = 20.0;
  static const double shadowOffsetY = 10.0;
  static const double shadowAlpha = 0.3;

  // Icon sizing
  static const double warningIconSize = 64.0;
  static const double backButtonIconSize = 24.0;
  static const double infoIconSize = 24.0;
  static const double copyIconSize = 20.0;

  // Snackbar timing
  static const int snackBarDurationSeconds = 2;
}

// Text styles for consistent styling
class _InvoiceKeyScreenStyles {
  static TextStyle titleStyle(AppTokens t) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: t.textPrimary,
      );

  static TextStyle subtitleStyle(AppTokens t) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: t.textPrimary,
      );

  static TextStyle labelStyle(AppTokens t) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: t.textSecondary,
      );

  static TextStyle monoStyle(AppTokens t) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: t.textPrimary,
      );

  static TextStyle bodyStyle(AppTokens t) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: t.textSecondary,
      );
}

class InvoiceKeyScreen extends StatelessWidget {
  const InvoiceKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, t),
              Expanded(
                child: _buildContent(context, t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _InvoiceKeyScreenConstants.horizontalContentPadding,
        vertical: _InvoiceKeyScreenConstants.verticalHeaderPadding,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(
                  _InvoiceKeyScreenConstants.backButtonRadius,
                ),
                border: Border.all(color: t.outline, width: 1),
              ),
              child: Icon(
                Icons.arrow_back,
                color: t.textPrimary,
                size: _InvoiceKeyScreenConstants.backButtonIconSize,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.invoice_key_qr_title ??
                  'Invoice Key QR',
              style: _InvoiceKeyScreenStyles.titleStyle(t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppTokens t) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallet = walletProvider.primaryWallet;
        final inKey = wallet?.inKey ?? '';

        if (wallet == null || inKey.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(
                _InvoiceKeyScreenConstants.horizontalContentPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: _InvoiceKeyScreenConstants.warningIconSize,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)
                            ?.invoice_key_unavailable_title ??
                        'Invoice Key Unavailable',
                    style: _InvoiceKeyScreenStyles.subtitleStyle(t),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)
                            ?.invoice_key_unavailable_subtitle ??
                        'Please create a wallet first',
                    style: _InvoiceKeyScreenStyles.bodyStyle(t),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: _InvoiceKeyScreenConstants.horizontalContentPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildQRCode(t, inKey),
              const SizedBox(
                height: _InvoiceKeyScreenConstants.sectionSpacing,
              ),
              _buildKeyInfo(context, t, inKey),
              const SizedBox(
                height: _InvoiceKeyScreenConstants.sectionSpacing,
              ),
              _buildCopyButton(context, t, inKey),
              const SizedBox(
                height: _InvoiceKeyScreenConstants.sectionSpacing,
              ),
              _buildWarning(context, t),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRCode(AppTokens t, String inKey) {
    return Container(
      padding: const EdgeInsets.all(
        _InvoiceKeyScreenConstants.qrContainerPadding,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(
          _InvoiceKeyScreenConstants.qrBorderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _InvoiceKeyScreenConstants.shadowAlpha,
            ),
            blurRadius: _InvoiceKeyScreenConstants.shadowBlurRadius,
            offset: Offset(
              0,
              _InvoiceKeyScreenConstants.shadowOffsetY,
            ),
          ),
        ],
      ),
      child: QrImageView(
        data: inKey,
        version: QrVersions.auto,
        size: _InvoiceKeyScreenConstants.qrSize,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ),
    );
  }

  Widget _buildKeyInfo(BuildContext context, AppTokens t, String inKey) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        _InvoiceKeyScreenConstants.keyInfoPadding,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(
          _InvoiceKeyScreenConstants.keyInfoBorderRadius,
        ),
        border: Border.all(color: t.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.invoice_key_label ?? 'Invoice Key',
            style: _InvoiceKeyScreenStyles.labelStyle(t),
          ),
          const SizedBox(
            height: _InvoiceKeyScreenConstants.smallSpacing,
          ),
          Text(
            inKey,
            style: _InvoiceKeyScreenStyles.monoStyle(t),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, AppTokens t, String inKey) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _copyToClipboard(context, t, inKey),
        icon: const Icon(Icons.copy, size: 20),
        label: Text(
          AppLocalizations.of(context)!.copy_invoice_key,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accentSolid,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context, AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber,
            size: _InvoiceKeyScreenConstants.infoIconSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.invoice_key_qr_description ??
                  'Use this QR code to receive payments',
              style: _InvoiceKeyScreenStyles.bodyStyle(t),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, AppTokens t, String text) {
    // Validate input
    if (text.isEmpty) {
      _showErrorMessage(context, 'Invoice key cannot be empty');
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.invoice_key_copied ??
              'Invoice key copied to clipboard',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: t.accentSolid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(
          seconds: _InvoiceKeyScreenConstants.snackBarDurationSeconds,
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(
          seconds: _InvoiceKeyScreenConstants.snackBarDurationSeconds,
        ),
      ),
    );
  }
}
