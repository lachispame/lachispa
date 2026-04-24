import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/decoded_invoice.dart';
import '../services/invoice_service.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

class InvoiceConfirmScreen extends StatefulWidget {
  final DecodedInvoice decodedInvoice;
  final int? overrideAmountSats;

  const InvoiceConfirmScreen({
    super.key,
    required this.decodedInvoice,
    this.overrideAmountSats,
  });

  @override
  State<InvoiceConfirmScreen> createState() => _InvoiceConfirmScreenState();
}

class _InvoiceConfirmScreenState extends State<InvoiceConfirmScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  bool _isProcessing = false;

  String get _displayAmount {
    if (widget.overrideAmountSats != null) {
      return '${widget.overrideAmountSats} sats';
    }
    return widget.decodedInvoice.formattedAmount;
  }

  @override
  void dispose() {
    _invoiceService.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;

    // Check if invoice is expired before processing payment
    if (widget.decodedInvoice.isExpired) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invoice_expired_error);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();

      if (authProvider.sessionData == null) {
        throw Exception(AppLocalizations.of(context)!.invalid_session_error);
      }

      final session = authProvider.sessionData!;

      // Verify that a primary wallet is available
      if (walletProvider.primaryWallet == null) {
        throw Exception(AppLocalizations.of(context)!.no_wallet_error);
      }

      final wallet = walletProvider.primaryWallet!;

      // Make payment using wallet's admin key
      final paymentResult = await _invoiceService.sendPayment(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey, // Use wallet's admin key
        bolt11: widget.decodedInvoice.originalInvoice,
        amount: widget.overrideAmountSats,
      );

      print('[INVOICE_CONFIRM] Payment made: $paymentResult');

      // Update balance after payment is completed
      await walletProvider.refreshPrimaryBalance(
        serverUrl: session.serverUrl,
      );

      // Check payment status from response to provide appropriate feedback
      final paymentStatus = paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' || paymentStatus == 'settled' || paymentStatus == 'paid';

      if (isPending) {
        _showPendingSnackBar(AppLocalizations.of(context)!.pending_label);
      } else if (isSuccess) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.payment_success);
      } else {
        _showSuccessSnackBar(AppLocalizations.of(context)!.payment_sent_status(paymentStatus));
      }

      // Return to previous screen after brief delay for user feedback
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      print('[INVOICE_CONFIRM] Error sending payment: $e');
      if (e.toString().contains('AMOUNTLESS_INVOICE_NOT_SUPPORTED')) {
        _showErrorSnackBar(AppLocalizations.of(context)!.amountless_invoice_error);
      } else {
        _showErrorSnackBar('${AppLocalizations.of(context)!.send_error_prefix}$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // White content on saturated status background; not a themable surface.
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: t.statusHealthy.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPendingSnackBar(String message) {
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // White content on saturated status background; not a themable surface.
            const Icon(Icons.schedule, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: t.statusWarning.withValues(alpha: 0.9),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // White content on saturated status background; not a themable surface.
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: t.statusUnhealthy.withValues(alpha: 0.9),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          return Container(
            width: double.infinity,
            height: double.infinity,
            // Send/confirm screens use a 2-stop variant of the brand gradient
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1419),
                  Color(0xFF2D3FE7),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: t.outline,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: t.textPrimary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 0 : 4),

                        Text(
                          AppLocalizations.of(context)!.pay_button_confirm,
                          style: TextStyle(
                            fontSize: isMobile ? 40 : 48,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 32.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isMobile ? 16 : 24),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: t.outline,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          _displayAmount,
                                          style: TextStyle(
                                            fontSize: isMobile ? 36 : 48,
                                            fontWeight: FontWeight.w700,
                                            color: t.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  _buildDescriptionRow(
                                    t,
                                    AppLocalizations.of(context)!.invoice_description_label,
                                    widget.decodedInvoice.description.isEmpty
                                        ? AppLocalizations.of(context)!.no_description_text
                                        : widget.decodedInvoice.description,
                                    icon: Icons.description_outlined,
                                  ),

                                  const SizedBox(height: 16),

                                  _buildInfoRow(
                                    t,
                                    AppLocalizations.of(context)!.invoice_status_label,
                                    widget.decodedInvoice.isExpired ? AppLocalizations.of(context)!.expired_status : AppLocalizations.of(context)!.valid_status,
                                    icon: widget.decodedInvoice.isExpired ? Icons.error_outline : Icons.check_circle_outline,
                                    valueColor: widget.decodedInvoice.isExpired ? t.statusUnhealthy : t.statusHealthy,
                                  ),

                                  const SizedBox(height: 16),

                                  _buildInfoRow(
                                    t,
                                    AppLocalizations.of(context)!.expiry_label,
                                    widget.decodedInvoice.formattedExpiry,
                                    icon: Icons.schedule_outlined,
                                    valueColor: widget.decodedInvoice.isExpired ? t.statusUnhealthy : null,
                                  ),

                                  if (widget.decodedInvoice.paymentHash.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      t,
                                      AppLocalizations.of(context)!.payment_hash_label,
                                      widget.decodedInvoice.shortPaymentHash,
                                      icon: Icons.fingerprint_outlined,
                                    ),
                                  ],

                                  if (widget.decodedInvoice.destination.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      t,
                                      AppLocalizations.of(context)!.recipient_label,
                                      widget.decodedInvoice.destination.length > 20
                                          ? '${widget.decodedInvoice.destination.substring(0, 20)}...'
                                          : widget.decodedInvoice.destination,
                                      icon: Icons.person_outline,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: t.surface,
                                      foregroundColor: t.textPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: t.outline,
                                          width: 1,
                                        ),
                                      ),
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.cancel_button,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: t.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: (!widget.decodedInvoice.isExpired && !_isProcessing)
                                        ? _confirmPayment
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (!widget.decodedInvoice.isExpired && !_isProcessing)
                                          ? t.accentSolid
                                          : t.surface,
                                      foregroundColor: t.accentForeground,
                                      elevation: (!widget.decodedInvoice.isExpired && !_isProcessing) ? 8 : 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: (!widget.decodedInvoice.isExpired && !_isProcessing)
                                              ? t.accentSolid
                                              : t.outline,
                                          width: 1,
                                        ),
                                      ),
                                      shadowColor: (!widget.decodedInvoice.isExpired && !_isProcessing)
                                          ? t.accentSolid.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                    child: _isProcessing
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(t.accentForeground),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(context)!.processing_text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: t.accentForeground,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            widget.decodedInvoice.isExpired ? AppLocalizations.of(context)!.expired_status : AppLocalizations.of(context)!.pay_button,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: (!widget.decodedInvoice.isExpired && !_isProcessing)
                                                  ? t.accentForeground
                                                  : t.textPrimary.withValues(alpha: 0.4),
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(AppTokens t, String label, String value, {IconData? icon, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: t.textPrimary.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: valueColor ?? t.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow(AppTokens t, String label, String value, {IconData? icon, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: t.textPrimary.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: t.outline,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: valueColor ?? t.textPrimary,
              height: 1.4,
            ),
            maxLines: null, // Allows multiple lines
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}
