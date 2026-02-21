import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/yadio_service.dart';
import '../services/invoice_service.dart';
import '../models/decoded_invoice.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/currency_settings_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '12invoice_confirm_screen.dart';

class AmountScreen extends StatefulWidget {
  final String destination;
  final String destinationType; // 'lnurl', 'lightning_address', or 'bolt11'
  final DecodedInvoice? decodedInvoice;

  const AmountScreen({
    super.key,
    required this.destination,
    required this.destinationType,
    this.decodedInvoice,
  });

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final YadioService _yadioService = YadioService();
  final InvoiceService _invoiceService = InvoiceService();
  
  String _amount = '0';
  String _selectedCurrency = 'sats';
  List<String> _currencies = ['sats'];
  
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  Map<String, double>? _exchangeRates;
  bool _isLoadingRates = false;
  bool _isProcessingPayment = false;
  
  // Real-time conversion cache to avoid API calls on every input change
  int _cachedSatsAmount = 0;
  bool _isConverting = false;
  
  // Debounce timer for currency conversions to reduce API load
  Timer? _conversionTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrencies();
    });
    _loadExchangeRates();
    _updateConversion();
  }
  
  void _initializeCurrencies() async {
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final authProvider = context.read<AuthProvider>();
    
    print('[AMOUNT_SCREEN] Initializing currencies...');
    print('[AMOUNT_SCREEN] Server URL: ${authProvider.currentServer}');
    
    // Ensure provider has server URL configured
    if (authProvider.currentServer != null) {
      await currencyProvider.updateServerUrl(authProvider.currentServer);
      
      // Force load exchange rates to ensure they're available
      await currencyProvider.loadExchangeRates(forceRefresh: true);
      
      print('[AMOUNT_SCREEN] Available currencies: ${currencyProvider.availableCurrencies}');
      print('[AMOUNT_SCREEN] Exchange rates loaded: ${currencyProvider.availableCurrencies.isNotEmpty}');
    }
    
    final displaySequence = currencyProvider.displaySequence;
    
    if (mounted) {
      setState(() {
        _currencies = displaySequence.isNotEmpty ? displaySequence : ['sats'];
        // Ensure selected currency is valid
        if (!_currencies.contains(_selectedCurrency)) {
          _selectedCurrency = _currencies.first;
        }
      });
    }
    
    print('[AMOUNT_SCREEN] Final currencies: $_currencies');
    print('[AMOUNT_SCREEN] Selected currency: $_selectedCurrency');
  }

  @override
  void dispose() {
    _conversionTimer?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _yadioService.dispose();
    _invoiceService.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
    });

    try {
      final rates = await _yadioService.getExchangeRates();
      setState(() {
        _exchangeRates = rates;
      });
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!.conversion_rate_error);
    } finally {
      setState(() {
        _isLoadingRates = false;
      });
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
    _updateConversion();
  }

  void _onDecimalPressed() {
    if (!_amount.contains('.')) {
      setState(() {
        _amount += '.';
      });
    }
    _updateConversion();
  }

  void _onClearPressed() {
    setState(() {
      _amount = '0';
      _cachedSatsAmount = 0;
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
    _updateConversion();
  }

  void _onZerosPressed(String zeros) {
    setState(() {
      if (_amount == '0') {
        _amount = zeros.substring(1); // Remove first zero
      } else {
        _amount += zeros;
      }
    });
    _updateConversion();
  }

  void _toggleCurrency() {
    // Get fresh currency list from provider
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final availableCurrencies = currencyProvider.displaySequence;
    
    if (availableCurrencies.isEmpty) {
      // Fallback to sats only
      setState(() {
        _currencies = ['sats'];
        _selectedCurrency = 'sats';
      });
      return;
    }
    
    setState(() {
      _currencies = availableCurrencies;
      final currentIndex = _currencies.indexOf(_selectedCurrency);
      final nextIndex = (currentIndex + 1) % _currencies.length;
      _selectedCurrency = _currencies[nextIndex];
    });
    _updateConversion();
  }

  Future<int> _getAmountInSats() async {
    final amount = double.tryParse(_amount) ?? 0.0;
    
    print('[AMOUNT_SCREEN] Converting $amount $_selectedCurrency to sats');
    
    if (_selectedCurrency == 'sats') {
      return amount.round();
    }
    
    // Use INVERSE conversion from the working convertSatsToFiat method
    // This ensures we use exactly the same rates as home_screen
    try {
      final currencyProvider = context.read<CurrencySettingsProvider>();
      
      print('[AMOUNT_SCREEN] Using inverse conversion method for consistency');
      
      // Step 1: Get rate by converting 1 BTC (100M sats) to fiat
      const oneBtcInSats = 100000000; // 1 BTC = 100M sats
      final oneBtcInFiat = await currencyProvider.convertSatsToFiat(oneBtcInSats, _selectedCurrency);
      
      print('[AMOUNT_SCREEN] Rate check: $oneBtcInSats sats = $oneBtcInFiat $_selectedCurrency');
      
      // Step 2: Parse the result to get numeric rate
      final fiatString = oneBtcInFiat.replaceAll(RegExp(r'[^\d.]'), ''); // Remove non-numeric chars
      final oneBtcRate = double.tryParse(fiatString);
      
      if (oneBtcRate == null || oneBtcRate <= 0) {
        throw Exception('Invalid rate obtained: $oneBtcInFiat');
      }
      
      print('[AMOUNT_SCREEN] Parsed rate: 1 BTC = $oneBtcRate $_selectedCurrency');
      
      // Step 3: Calculate sats using inverse proportion
      // If 1 BTC = oneBtcRate fiat, then amount fiat = ? sats
      // sats = (amount / oneBtcRate) * 100000000
      final btcAmount = amount / oneBtcRate;
      final satsAmount = (btcAmount * 100000000).round();
      
      print('[AMOUNT_SCREEN] Conversion successful: $amount $_selectedCurrency = $satsAmount sats');
      print('[AMOUNT_SCREEN] Math: ($amount / $oneBtcRate) * 100000000 = $satsAmount');
      
      return satsAmount;
      
    } catch (e) {
      print('[AMOUNT_SCREEN] Error with inverse conversion: $e');
      
      // Fallback to YadioService as last resort
      try {
        print('[AMOUNT_SCREEN] Trying YadioService fallback');
        final sats = await _yadioService.convertToSats(
          amount: amount,
          currency: _selectedCurrency,
        );
        print('[AMOUNT_SCREEN] YadioService conversion: $amount $_selectedCurrency = $sats sats');
        return sats;
      } catch (fallbackError) {
        print('[AMOUNT_SCREEN] All conversion methods failed: $fallbackError');
        return 0;
      }
    }
  }

  String _formatDisplayAmount() {
    final amount = double.tryParse(_amount) ?? 0.0;
    
    if (_selectedCurrency == 'sats') {
      return '${amount.toStringAsFixed(0)} sats';
    } else {
      return '$amount $_selectedCurrency';
    }
  }

  void _updateConversion() {
    if (_selectedCurrency == 'sats') {
      setState(() {
        _cachedSatsAmount = (double.tryParse(_amount) ?? 0.0).round();
      });
      return;
    }
    
    // Cancel previous timer if exists to prevent multiple API calls
    _conversionTimer?.cancel();
    
    // Show "calculating..." state immediately for UX feedback
    if (!_isConverting) {
      setState(() {
        _isConverting = true;
      });
    }
    
    // Wait 800ms before making API request (debounce for user input)
    _conversionTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final satsAmount = await _getAmountInSats();
        if (mounted) {
          setState(() {
            _cachedSatsAmount = satsAmount;
            _isConverting = false;
          });
        }
      } catch (e) {
        print('Error updating conversion: $e');
        if (mounted) {
          setState(() {
            _isConverting = false;
          });
        }
      }
    });
  }

  String _getConversionText() {
    if (_selectedCurrency == 'sats') {
      return '';
    }
    
    if (_isConverting) {
      return ' / ${AppLocalizations.of(context)!.calculating_text}...';
    }
    
    if (_cachedSatsAmount > 0) {
      return ' / $_cachedSatsAmount sats';
    }
    
    return ' / -- sats';
  }

  Future<void> _processPayment() async {
    if (_isProcessingPayment) return;
    
    print('[AMOUNT_SCREEN] === STARTING PAYMENT PROCESS ===');
    print('[AMOUNT_SCREEN] Amount: $_amount $_selectedCurrency');
    print('[AMOUNT_SCREEN] Cached sats: $_cachedSatsAmount');
    
    // ALWAYS recalculate sats amount for payment to ensure accuracy
    // Cache is only for display, payment must use fresh calculation
    final satsAmount = await _getAmountInSats();
    
    print('[AMOUNT_SCREEN] Final sats amount for payment: $satsAmount');
    
    if (satsAmount <= 0) {
      print('[AMOUNT_SCREEN] Invalid sats amount: $satsAmount');
      _showErrorSnackBar(AppLocalizations.of(context)!.invalid_amount_error);
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Process payment based on destination type (LNURL vs Lightning Address)
      print('[AMOUNT_SCREEN] Processing payment with $satsAmount sats');
      
      if (widget.destinationType == 'bolt11') {
        await _processBolt11Payment(satsAmount);
      } else if (widget.destinationType == 'lnurl') {
        await _processLNURLPayment(satsAmount);
      } else if (widget.destinationType == 'lightning_address') {
        await _processLightningAddressPayment(satsAmount);
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.send_error_prefix}$e');
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _processBolt11Payment(int satsAmount) async {
    if (widget.decodedInvoice == null) return;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceConfirmScreen(
            decodedInvoice: widget.decodedInvoice!,
            overrideAmountSats: satsAmount,
          ),
        ),
      );
    }
  }

  Future<void> _processLNURLPayment(int satsAmount) async {
    try {
      print('[AMOUNT_SCREEN] Processing LNURL payment: ${widget.destination}');
      print('[AMOUNT_SCREEN] Amount: $satsAmount sats');
      
      // Get required providers for authentication and wallet access
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
      
      _showSuccessSnackBar(AppLocalizations.of(context)!.send_title);
      
      // Send payment directly to LNURL using LNBits
      final paymentResult = await _invoiceService.sendPaymentToLNURL(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey,
        lnurl: widget.destination,
        amountSats: satsAmount,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      
      print('[AMOUNT_SCREEN] LNURL payment sent successfully: $paymentResult');
      
      // Check payment status from response to provide appropriate user feedback
      final paymentStatus = paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' || paymentStatus == 'settled' || paymentStatus == 'paid';

      if (isPending) {
        _showPendingSnackBar(AppLocalizations.of(context)!.pending_label);
      } else if (isSuccess) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.payment_success);
      } else {
        _showSuccessSnackBar('Pago LNURL enviado! Estado: $paymentStatus');
      }
      
      // Wait for user to see success message before navigation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate back to home, skipping send screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
    } catch (e) {
      print('[AMOUNT_SCREEN] Error processing LNURL: $e');
      
      // Show specific error message to user based on error type
      String errorMessage = 'Error procesando pago LNURL';
      
      if (e.toString().contains('not found') || e.toString().contains('no encontrada')) {
        errorMessage = 'LNURL no encontrada';
      } else if (e.toString().contains('Minimum amount') || e.toString().contains('Minimum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Maximum amount') || e.toString().contains('Maximum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Insufficient balance') || e.toString().contains('Saldo insuficiente')) {
        errorMessage = 'Saldo insuficiente para realizar el pago';
      } else if (e.toString().contains('authentication') || e.toString().contains('authentication')) {
        errorMessage = 'Authentication error. Please try logging in again.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _processLightningAddressPayment(int satsAmount) async {
    try {
      print('[AMOUNT_SCREEN] Processing Lightning Address payment: ${widget.destination}');
      print('[AMOUNT_SCREEN] Amount: $satsAmount sats');
      
      // Get required providers for authentication and wallet access
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
      
      _showSuccessSnackBar(AppLocalizations.of(context)!.send_title);
      
      // Send payment directly to Lightning Address using LNBits
      final paymentResult = await _invoiceService.sendPaymentToLightningAddress(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey,
        lightningAddress: widget.destination,
        amountSats: satsAmount,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      
      print('[AMOUNT_SCREEN] Payment sent successfully: $paymentResult');
      
      // Check payment status from response to provide appropriate user feedback
      final paymentStatus = paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' || paymentStatus == 'settled' || paymentStatus == 'paid';

      if (isPending) {
        _showPendingSnackBar(AppLocalizations.of(context)!.pending_label);
      } else if (isSuccess) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.payment_success);
      } else {
        _showSuccessSnackBar('Pago Lightning Address enviado! Estado: $paymentStatus');
      }
      
      // Wait for user to see success message before navigation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate back to home, skipping send screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
    } catch (e) {
      print('[AMOUNT_SCREEN] Error processing Lightning Address: $e');
      
      // Show specific error message to user based on error type
      String errorMessage = 'Error procesando pago';
      
      if (e.toString().contains('not found') || e.toString().contains('no encontrada')) {
        errorMessage = 'Lightning Address no encontrada';
      } else if (e.toString().contains('Minimum amount') || e.toString().contains('Minimum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Maximum amount') || e.toString().contains('Maximum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Insufficient balance') || e.toString().contains('Saldo insuficiente')) {
        errorMessage = 'Saldo insuficiente para realizar el pago';
      } else if (e.toString().contains('authentication') || e.toString().contains('authentication')) {
        errorMessage = 'Authentication error. Please try logging in again.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.withValues(alpha: 0.9),
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
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
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
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNumberButton(String text, VoidCallback onPressed, bool isMobile) {
    return SizedBox(
      height: isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
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
        child: Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, {IconData? icon, required bool isMobile}) {
    return SizedBox(
      height: isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
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
        child: icon != null
            ? Icon(icon, color: Colors.white, size: isMobile ? 18 : 20)
            : Text(
                text,
                style: TextStyle(
                  fontSize: (text == '00' || text == '000' || text == 'sats' || text == 'CUP' || text == 'USD') 
                      ? (isMobile ? 12 : 14) 
                      : (isMobile ? 14 : 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencySettingsProvider>(
      builder: (context, currencyProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
                  // Header with navigation
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      children: [
                        // Row with back button
                        Row(
                          children: [
                            // Back button
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
                        
                        // Title and recipient
                        Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.send_to_title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isMobile ? 40 : 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.destination,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 32.0,
                        vertical: 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 200,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isMobile ? 8 : 12),
                          
                          // Amount display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                if (_selectedCurrency == 'sats') 
                                  Text(
                                    _formatDisplayAmount(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isMobile ? 38 : 48,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                else
                                  // Display fiat amount with sats conversion side by side
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _formatDisplayAmount(),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: isMobile ? 38 : 48,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isConverting 
                                            ? '(${AppLocalizations.of(context)!.calculating_text}...)'
                                            : '(≈ $_cachedSatsAmount sats)',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: isMobile ? 18 : 22,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 20),
                          
                          // Numeric keypad
                          Flexible(
                            child: Container(
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildNumberButton('1', () => _onNumberPressed('1'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('2', () => _onNumberPressed('2'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('3', () => _onNumberPressed('3'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildActionButton('⌫', _onDeletePressed, icon: Icons.backspace_outlined, isMobile: isMobile)),
                                      ],
                                    ),
                                    
                                    SizedBox(height: isMobile ? 8 : 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(child: _buildNumberButton('4', () => _onNumberPressed('4'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('5', () => _onNumberPressed('5'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('6', () => _onNumberPressed('6'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildActionButton('00', () => _onZerosPressed('00'), isMobile: isMobile)),
                                      ],
                                    ),
                                    
                                    SizedBox(height: isMobile ? 8 : 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(child: _buildNumberButton('7', () => _onNumberPressed('7'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('8', () => _onNumberPressed('8'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('9', () => _onNumberPressed('9'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildActionButton('000', () => _onZerosPressed('000'), isMobile: isMobile)),
                                      ],
                                    ),
                                    
                                    SizedBox(height: isMobile ? 8 : 12),
                                    
                                    Row(
                                      children: [
                                        Expanded(child: _buildActionButton('.', _onDecimalPressed, isMobile: isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildNumberButton('0', () => _onNumberPressed('0'), isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildActionButton('C', _onClearPressed, isMobile: isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(child: _buildActionButton(_selectedCurrency, _toggleCurrency, isMobile: isMobile)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // Comment field (hidden for bolt11 - invoice has its own description)
                          if (widget.destinationType != 'bolt11')
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              key: const Key('comment_field'),
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              maxLines: 2,
                              maxLength: 150,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.add_note_optional,
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                counterStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: (double.tryParse(_amount) ?? 0) > 0 && !_isProcessingPayment
                                  ? _processPayment
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (double.tryParse(_amount) ?? 0) > 0
                                    ? const Color(0xFF2D3FE7)
                                    : Colors.white.withValues(alpha: 0.08),
                                foregroundColor: Colors.white,
                                elevation: (double.tryParse(_amount) ?? 0) > 0 ? 8 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: (double.tryParse(_amount) ?? 0) > 0
                                        ? const Color(0xFF4C63F7)
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                shadowColor: (double.tryParse(_amount) ?? 0) > 0
                                    ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                              child: _isProcessingPayment
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
                                      _selectedCurrency != 'sats'
                                          ? 'SEND ${_formatDisplayAmount()}${_getConversionText()}'
                                          : 'SEND ${_formatDisplayAmount()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: (double.tryParse(_amount) ?? 0) > 0
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.4),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                          
                          
                          // Compact loading indicator for exchange rates
                          if (_isLoadingRates) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.loading_text,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],
                          
                          // Extra space for keyboard
                          const SizedBox(height: 60),
                        ],
                        ),
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
      },
    );
  }
}