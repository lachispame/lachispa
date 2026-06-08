import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wallet_provider.dart';
import '../l10n/generated/app_localizations.dart';

class InvoiceKeyScreen extends StatefulWidget {
  const InvoiceKeyScreen({super.key});

  @override
  State<InvoiceKeyScreen> createState() => _InvoiceKeyScreenState();
}

class _InvoiceKeyScreenState extends State<InvoiceKeyScreen> {
  bool _isKeyVisible = false;

  String _maskKey(String key) {
    if (key.length <= 8) return '•' * key.length;
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  Future<void> _copyToClipboard(BuildContext context, String key) async {
    try {
      await Clipboard.setData(ClipboardData(text: key));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invoice_key_copied),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invoice_key_copy_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.invoice_key_qr_title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallet = walletProvider.primaryWallet;
        final invoiceKey = (wallet?.readKey ?? '').isEmpty
            ? (wallet?.inKey ?? '')
            : (wallet?.readKey ?? '');

        if (wallet == null || invoiceKey.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.invoice_key_unavailable_title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.invoice_key_unavailable_subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildQRCode(invoiceKey),
              const SizedBox(height: 24),
              _buildKeyInfo(context, invoiceKey),
              const SizedBox(height: 24),
              _buildCopyButton(context, invoiceKey),
              const SizedBox(height: 24),
              _buildWarning(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRCode(String invoiceKey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: invoiceKey,
        version: QrVersions.auto,
        size: 220.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ),
    );
  }

  Widget _buildKeyInfo(BuildContext context, String invoiceKey) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.invoice_key_qr_title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isKeyVisible = !_isKeyVisible;
                  });
                },
                child: Icon(
                  _isKeyVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isKeyVisible ? invoiceKey : _maskKey(invoiceKey),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String invoiceKey) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _copyToClipboard(context, invoiceKey),
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
          backgroundColor: const Color(0xFF4C63F7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildWarning(BuildContext context) {
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
          const Icon(
            Icons.info_outline,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.invoice_key_security_warning,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
