import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/decoded_invoice.dart';
import '../services/invoice_service.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class InvoiceConfirmScreen extends StatefulWidget {
  final DecodedInvoice decodedInvoice;

  const InvoiceConfirmScreen({
    super.key,
    required this.decodedInvoice,
  });

  @override
  State<InvoiceConfirmScreen> createState() => _InvoiceConfirmScreenState();
}

class _InvoiceConfirmScreenState extends State<InvoiceConfirmScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _invoiceService.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;

    // Check if invoice is expired before processing payment
    if (widget.decodedInvoice.isExpired) {
      _showErrorSnackBar('La factura ha expirado y no se puede pagar');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();

      if (authProvider.sessionData == null) {
        throw Exception('Sin sesión activa');
      }

      final session = authProvider.sessionData!;

      // Verify that a primary wallet is available
      if (walletProvider.primaryWallet == null) {
        throw Exception('No hay wallet principal disponible');
      }

      final wallet = walletProvider.primaryWallet!;

      // Make payment using wallet's admin key
      final paymentResult = await _invoiceService.sendPayment(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey, // Use wallet's admin key
        bolt11: widget.decodedInvoice.originalInvoice,
      );

      print('[INVOICE_CONFIRM] Payment made: $paymentResult');

      // Update balance after payment is completed
      await walletProvider.refreshPrimaryBalance(
        serverUrl: session.serverUrl,
      );

      // Check payment status from response to provide appropriate feedback
      final paymentStatus =
          paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' ||
          paymentStatus == 'settled' ||
          paymentStatus == 'paid';

      if (mounted) {
        if (isPending) {
          _showPendingSnackBar('Pago pendiente - Factura Hold detectada');
        } else if (isSuccess) {
          _showSuccessSnackBar('Pago completado exitosamente');
        } else {
          _showSuccessSnackBar('Pago enviado - Estado: $paymentStatus');
        }
      }

      // Return to previous screen after brief delay for user feedback
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Return to HomeScreen
      }
    } catch (e) {
      if (mounted) {
        print('[INVOICE_CONFIRM] Error sending payment: $e');
        _showErrorSnackBar('Error enviando pago: $e');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.withOpacity(0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPendingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.withOpacity(0.9),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.withOpacity(0.9),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          return Container(
            width: double.infinity,
            height: double.infinity,
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
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
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
                          'Confirmar Pago',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 40 : 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                                          widget.decodedInvoice.formattedAmount,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: isMobile ? 36 : 48,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildDescriptionRow(
                                    'Descripción',
                                    widget.decodedInvoice.description.isEmpty
                                        ? 'Sin descripción'
                                        : widget.decodedInvoice.description,
                                    icon: Icons.description_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Estado',
                                    widget.decodedInvoice.isExpired
                                        ? 'Expirada'
                                        : 'Válida',
                                    icon: widget.decodedInvoice.isExpired
                                        ? Icons.error_outline
                                        : Icons.check_circle_outline,
                                    valueColor: widget.decodedInvoice.isExpired
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Expiración',
                                    widget.decodedInvoice.formattedExpiry,
                                    icon: Icons.schedule_outlined,
                                    valueColor: widget.decodedInvoice.isExpired
                                        ? Colors.red
                                        : null,
                                  ),
                                  if (widget.decodedInvoice.paymentHash
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      'Hash de Pago',
                                      widget.decodedInvoice.shortPaymentHash,
                                      icon: Icons.fingerprint_outlined,
                                    ),
                                  ],
                                  if (widget.decodedInvoice.destination
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      'Destinatario',
                                      widget.decodedInvoice.destination.length >
                                              20
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
                                child: Container(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isProcessing
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.08),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                                child: Container(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        (!widget.decodedInvoice.isExpired &&
                                                !_isProcessing)
                                            ? _confirmPayment
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          (!widget.decodedInvoice.isExpired &&
                                                  !_isProcessing)
                                              ? const Color(0xFF2D3FE7)
                                              : Colors.white.withOpacity(0.08),
                                      foregroundColor: Colors.white,
                                      elevation:
                                          (!widget.decodedInvoice.isExpired &&
                                                  !_isProcessing)
                                              ? 8
                                              : 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: (!widget.decodedInvoice
                                                      .isExpired &&
                                                  !_isProcessing)
                                              ? const Color(0xFF4C63F7)
                                              : Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      shadowColor:
                                          (!widget.decodedInvoice.isExpired &&
                                                  !_isProcessing)
                                              ? const Color(0xFF2D3FE7)
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                    ),
                                    child: _isProcessing
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Enviando...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            widget.decodedInvoice.isExpired
                                                ? 'Expirada'
                                                : 'Pagar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: (!widget.decodedInvoice
                                                          .isExpired &&
                                                      !_isProcessing)
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.4),
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

  Widget _buildInfoRow(String label, String value,
      {IconData? icon, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: valueColor ?? Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow(String label, String value,
      {IconData? icon, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: valueColor ?? Colors.white,
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
