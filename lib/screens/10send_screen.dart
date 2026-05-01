import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '11amount_screen.dart';
import '12invoice_confirm_screen.dart';
import '../services/invoice_service.dart';
import '../services/payment_error.dart';
import '../services/nfc_read_service.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/qr_scanner_widget.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

class SendScreen extends StatefulWidget {
  final String? initialPaymentData;

  const SendScreen({super.key, this.initialPaymentData});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _inputController = TextEditingController();
  final InvoiceService _invoiceService = InvoiceService();
  final NfcReadService _nfcReadService = NfcReadService();
  bool _isProcessing = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes for automatic validation
    _inputController.addListener(_onTextChanged);

    // Check NFC availability
    _checkNfcAvailability();

    // Set initial payment data if provided from deep link
    if (widget.initialPaymentData != null) {
      print('[SendScreen] Received initial payment data: ${widget.initialPaymentData}');
      _inputController.text = widget.initialPaymentData!;
      // Auto-process if valid payment data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[SendScreen] Checking if input is valid...');
        if (_hasValidInput()) {
          print('[SendScreen] Valid input detected, processing payment...');
          _processPayment();
        } else {
          print('[SendScreen] Invalid input: ${widget.initialPaymentData}');
        }
      });
    } else {
      print('[SendScreen] No initial payment data provided');
    }
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcReadService.isAvailable();
    if (mounted) {
      setState(() {
        _nfcAvailable = available;
      });
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _invoiceService.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Update button state when text changes
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        _inputController.text = data.text!;
      }
    } catch (e) {
      // Handle paste error silently
    }
  }

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          onScanned: (String scannedData) {
            // Close the scanner
            Navigator.pop(context);

            // Update input field with scanned data
            _inputController.text = scannedData;

            // Process automatically if valid input is detected
            if (_hasValidInput()) {
              _processPayment();
            }
          },
        ),
      ),
    );
  }

  String _cleanLightningInput(String input) {
    String cleaned = input.toLowerCase().trim();
    if (cleaned.startsWith('lightning:')) {
      cleaned = cleaned.substring(10);
    }
    return cleaned;
  }

  bool _hasValidInput() {
    final text = _inputController.text.trim();
    return text.isNotEmpty && (_isValidBolt11(text) || _isValidLNURL(text) || _isValidLightningAddress(text));
  }

  bool _isValidBolt11(String text) {
    // Normalize text by removing common prefixes
    String normalizedText = _cleanLightningInput(text);

    // Basic Lightning BOLT11 invoice validation
    return normalizedText.startsWith('lnbc') ||
        normalizedText.startsWith('lntb') ||
        normalizedText.startsWith('lnbcrt');
  }

  bool _isValidLNURL(String text) {
    // Normalize text by removing common prefixes
    String normalizedText = _cleanLightningInput(text);

    // Basic LNURL validation
    return normalizedText.startsWith('lnurl') ||
        (text.startsWith('http') && text.contains('lnurl'));
  }

  bool _isValidLightningAddress(String text) {
    // Use enhanced validation method from InvoiceService
    return InvoiceService.isValidLightningAddress(text);
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final input = _inputController.text.trim();

      if (_isValidBolt11(input)) {
        await _processBolt11Payment(input);
      } else if (_isValidLNURL(input)) {
        await _processLNURLPayment(input);
      } else if (_isValidLightningAddress(input)) {
        await _processLightningAddressPayment(input);
      }

    } catch (e) {
      if (e is PaymentError) {
        _showErrorSnackBar(_localizePaymentError(e));
      } else {
        _showErrorSnackBar('${AppLocalizations.of(context)!.send_error_prefix}$e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processBolt11Payment(String bolt11) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();

      if (authProvider.sessionData == null) {
        throw Exception(AppLocalizations.of(context)!.invalid_session_error);
      }

      if (walletProvider.primaryWallet == null) {
        throw Exception(AppLocalizations.of(context)!.no_wallet_error);
      }

      final session = authProvider.sessionData!;
      final wallet = walletProvider.primaryWallet!;

      // Clean invoice by removing prefixes if they exist
      String cleanBolt11 = bolt11.trim();
      if (cleanBolt11.toLowerCase().startsWith('lightning:')) {
        cleanBolt11 = cleanBolt11.substring(10);
        print('[SEND_SCREEN] Removed "lightning:" prefix from invoice');
      }

      // Decode invoice using LNBits
      final decodedInvoice = await _invoiceService.decodeBolt11(
        serverUrl: session.serverUrl,
        invoiceKey: wallet.inKey, // Use wallet's invoice key
        bolt11: cleanBolt11,
      );

      if (mounted) {
        if (decodedInvoice.amountSats == 0) {
          // Amountless invoice — route through AmountScreen for user input
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AmountScreen(
                destination: decodedInvoice.description.isNotEmpty
                    ? decodedInvoice.description
                    : decodedInvoice.shortPaymentHash,
                destinationType: 'bolt11',
                decodedInvoice: decodedInvoice,
              ),
            ),
          );
        } else {
          // Normal invoice with amount — go directly to confirmation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceConfirmScreen(
                decodedInvoice: decodedInvoice,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('[SEND_SCREEN] Error decoding invoice: $e');
      _showErrorSnackBar('${AppLocalizations.of(context)!.decode_invoice_error_prefix}$e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // FIX 1: onTap is always passed (never null), so the disabled NFC button
  // still fires _showNfcUnavailable instead of being silently swallowed.
  Widget _buildBarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final color = enabled
        ? context.tokens.textPrimary
        : context.tokens.textPrimary.withValues(alpha: 0.32);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, // always forward the tap; caller decides the action
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIX 2: bottom bar now uses the same brand gradient as the send screen body,
  // matching the gradient used in receive_screen's action bar.
  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1419),
            Color(0xFF2D3FE7),
          ],
        ),
        border: Border(
          top: BorderSide(color: context.tokens.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        10,
        8,
        10 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarAction(
            icon: Icons.content_paste_rounded,
            label: AppLocalizations.of(context)!.paste_button,
            onTap: _pasteFromClipboard,
          ),
          _buildBarAction(
            icon: Icons.qr_code_scanner,
            label: AppLocalizations.of(context)!.scan_button,
            onTap: _scanQR,
          ),
          _buildBarAction(
            icon: Icons.nfc_rounded,
            label: AppLocalizations.of(context)!.nfc_action_label,
            enabled: _nfcAvailable,
            onTap: _nfcAvailable ? _activateNfcRead : _showNfcUnavailable,
          ),
        ],
      ),
    );
  }


  Future<void> _processLNURLPayment(String lnurl) async {
    // Clean LNURL by removing prefixes if they exist
    String cleanLnurl = lnurl.trim();
    if (cleanLnurl.toLowerCase().startsWith('lightning:')) {
      cleanLnurl = cleanLnurl.substring(10);
    }

    // Navigate to amount screen for LNURL payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountScreen(
          destination: cleanLnurl,
          destinationType: 'lnurl',
        ),
      ),
    );
  }

  Future<void> _processLightningAddressPayment(String address) async {
    // Navigate to amount screen for Lightning Address payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountScreen(
          destination: address,
          destinationType: 'lightning_address',
        ),
      ),
    );
  }

  void _showNfcUnavailable() {
    _showInfoSnackBar(AppLocalizations.of(context)!.nfc_unavailable_message);
  }

  void _activateNfcRead() {
    if (!_nfcAvailable) {
      _showInfoSnackBar(AppLocalizations.of(context)!.nfc_unavailable_message);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _NfcReadSheet(
        nfcService: _nfcReadService,
        onRead: (result) {
          Navigator.pop(sheetContext);
          _handleNfcReadResult(result);
        },
        onError: (error) {
          Navigator.pop(sheetContext);
          _showErrorSnackBar(error);
        },
      ),
    );
  }

  void _handleNfcReadResult(NfcReadResult result) {
    setState(() {
      _inputController.text = result.value;
    });

    if (result.type == NfcReadResultType.lightningAddress) {
      _processLightningAddressPayment(result.value);
    } else if (result.type == NfcReadResultType.lnurl) {
      _processLNURLPayment(result.value);
    }
  }

  // ignore: unused_element
  void _showSuccessSnackBar(String message) {
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // White content on saturated status background; not a themable surface.
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: t.statusHealthy.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _localizePaymentError(PaymentError e) {
    final l = AppLocalizations.of(context)!;
    switch (e.kind) {
      case PaymentErrorKind.insufficientBalance:
        return l.insufficient_balance_error;
      case PaymentErrorKind.feeReserveRequired:
        return l.payment_error_fee_reserve_required;
      case PaymentErrorKind.alreadyPaid:
        return l.payment_error_already_paid;
      case PaymentErrorKind.stillPending:
        return l.payment_error_still_pending;
      case PaymentErrorKind.routeNotFound:
        return l.payment_error_route_not_found;
      case PaymentErrorKind.paymentNotFound:
        return l.payment_error_payment_not_found;
      case PaymentErrorKind.authenticationError:
        return l.payment_error_auth;
      case PaymentErrorKind.amountlessInvoice:
        return l.amountless_invoice_error;
      case PaymentErrorKind.lnurlOrDecodeError:
        return l.payment_error_lnurl_generic(e.rawDetail ?? '');
      case PaymentErrorKind.serverError:
        return l.payment_error_server;
      case PaymentErrorKind.unknown:
        return l.payment_error_unknown(e.statusCode ?? '?');
    }
  }

  void _showInfoSnackBar(String message) {
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: t.accentSolid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
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
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
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
      bottomNavigationBar: _buildBottomActionBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          return Container(
            width: double.infinity,
            height: double.infinity,
            // 2-stop variant of the brand gradient on send-flow screens
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
                          AppLocalizations.of(context)!.send_title,
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 32.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isMobile ? 20 : 40),

                          Flexible(
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: isMobile ? 100 : 120,
                                maxHeight: isMobile ? 150 : 200,
                              ),
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
                                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                child: TextField(
                                  controller: _inputController,
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.paste_input_hint,
                                    hintStyle: TextStyle(
                                      color: t.textPrimary.withValues(alpha: 0.6),
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  maxLines: isMobile ? 6 : 8,
                                  minLines: isMobile ? 3 : 4,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.done,
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isMobile ? 16 : 24),

                          SizedBox(height: isMobile ? 16 : 24),

                          SizedBox(
                            width: double.infinity,
                            height: isMobile ? 52 : 64,
                            child: ElevatedButton(
                              onPressed: (_hasValidInput() && !_isProcessing) ? _processPayment : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasValidInput()
                                    ? t.accentSolid
                                    : t.surface,
                                foregroundColor: t.accentForeground,
                                elevation: _hasValidInput() ? 8 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: _hasValidInput()
                                        ? t.accentSolid
                                        : t.outline,
                                    width: 1,
                                  ),
                                ),
                                shadowColor: _hasValidInput()
                                    ? t.accentSolid.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                              child: _isProcessing
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(t.accentForeground),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.processing_text.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: t.accentForeground,
                                    ),
                                  ),
                                ],
                              )
                                  : Text(
                                AppLocalizations.of(context)!.pay_button.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _hasValidInput()
                                      ? t.accentForeground
                                      : t.textPrimary.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),

                          // Flexible spacer to push info to bottom
                          Expanded(
                            flex: 1,
                            child: Container(),
                          ),

                          // Additional information (only if there's space)
                          if (isMobile) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                AppLocalizations.of(context)!.paste_input_hint,
                                style: TextStyle(
                                  color: t.textPrimary.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
}

class _NfcReadSheet extends StatefulWidget {
  final NfcReadService nfcService;
  final Function(NfcReadResult) onRead;
  final Function(String) onError;

  const _NfcReadSheet({
    required this.nfcService,
    required this.onRead,
    required this.onError,
  });

  @override
  State<_NfcReadSheet> createState() => _NfcReadSheetState();
}

class _NfcReadSheetState extends State<_NfcReadSheet> {
  late String _status;
  bool _reading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _status = AppLocalizations.of(context)!.nfc_scanning_send;
  }

  @override
  void initState() {
    super.initState();
    _startNfcRead();
  }

  Future<void> _startNfcRead() async {
    try {
      await widget.nfcService.startReadSession(
        onResult: (result) {
          if (mounted) {
            final l = AppLocalizations.of(context)!;
            setState(() {
              _reading = false;
              _status = l.nfc_card_detected;
            });
            widget.onRead(result);
          }
        },
        onError: (error) {
          if (mounted) {
            final l = AppLocalizations.of(context)!;
            setState(() {
              _reading = false;
              _status = l.nfc_read_error(error);
            });
            Future.delayed(const Duration(seconds: 2), () {
              widget.onError(error);
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        widget.onError(e.toString());
      }
    }
  }

  @override
  void dispose() {
    widget.nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.dialogBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            _reading ? Icons.nfc_rounded : Icons.check_circle,
            size: 64,
            color: _reading ? t.accentSolid : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _reading
                ? l.nfc_scanning_message
                : l.nfc_processing_card,
            style: TextStyle(
              fontSize: 14,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (_reading)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.nfcService.stopSession();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.surface,
                  foregroundColor: t.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: t.outline),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.cancel_button),
              ),
            ),
        ],
      ),
    );
  }
}