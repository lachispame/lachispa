import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '11amount_screen.dart';
import '12invoice_confirm_screen.dart';
import '../services/invoice_service.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/qr_scanner_widget.dart';
import '../l10n/generated/app_localizations.dart';

class SendScreen extends StatefulWidget {
  final String? initialPaymentData;
  
  const SendScreen({super.key, this.initialPaymentData});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _inputController = TextEditingController();
  final InvoiceService _invoiceService = InvoiceService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes for automatic validation
    _inputController.addListener(_onTextChanged);
    
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
      _showErrorSnackBar('${AppLocalizations.of(context)!.send_error_prefix}$e');
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
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
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
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
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
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
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
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
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
                          AppLocalizations.of(context)!.send_title,
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
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
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
                                    color: Colors.white,
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.paste_input_hint,
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
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
                          
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: isMobile ? 48 : 56,
                                      child: ElevatedButton(
                                        onPressed: _pasteFromClipboard,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              width: 1,
                                            ),
                                          ),
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.content_paste,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!.paste_button,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  Expanded(
                                    child: Container(
                                      height: isMobile ? 48 : 56,
                                      child: ElevatedButton(
                                        onPressed: _scanQR,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              width: 1,
                                            ),
                                          ),
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_scanner,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!.scan_button,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: isMobile ? 16 : 24),
                              
                              Container(
                                width: double.infinity,
                                height: isMobile ? 52 : 64,
                                child: ElevatedButton(
                                  onPressed: (_hasValidInput() && !_isProcessing) ? _processPayment : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _hasValidInput() 
                                        ? const Color(0xFF2D3FE7)
                                        : Colors.white.withValues(alpha: 0.08),
                                    foregroundColor: Colors.white,
                                    elevation: _hasValidInput() ? 8 : 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: _hasValidInput()
                                            ? const Color(0xFF4C63F7)
                                            : Colors.white.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    shadowColor: _hasValidInput() 
                                        ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
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
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              AppLocalizations.of(context)!.processing_text.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
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
                                                ? Colors.white 
                                                : Colors.white.withValues(alpha: 0.4),
                                          ),
                                        ),
                                ),
                              ),
                            ],
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
                                  color: Colors.white.withValues(alpha: 0.6),
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