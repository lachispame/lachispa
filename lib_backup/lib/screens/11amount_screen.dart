import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/yadio_service.dart';
import '../services/invoice_service.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class AmountScreen extends StatefulWidget {
  final String destination;
  final String destinationType; // 'lnurl' or 'lightning_address'

  const AmountScreen({
    super.key,
    required this.destination,
    required this.destinationType,
  });

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final YadioService _yadioService = YadioService();
  final InvoiceService _invoiceService = InvoiceService();

  String _amount = '0';
  String _selectedCurrency = 'sats';
  final List<String> _currencies = ['sats', 'USD', 'CUP'];

  Map<String, double>? _exchangeRates;
  bool _isLoadingRates = false;
  bool _isProcessingPayment = false;

  // Real-time conversion cache to avoid API calls on every input change
  double _cachedSatsAmount = 0.0;
  bool _isConverting = false;

  // Debounce timer for currency conversions to reduce API load
  Timer? _conversionTimer;
  int _conversionRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
    _updateConversion();
  }

  @override
  void dispose() {
    _conversionTimer?.cancel();
    _yadioService.dispose();
    _invoiceService.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRates = true;
    });

    try {
      final rates = await _yadioService.getExchangeRates();
      if (!mounted) return;
      setState(() {
        _exchangeRates = rates;
      });
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error cargando tipos de cambio');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRates = false;
        });
      }
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
      _cachedSatsAmount = 0.0;
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
    setState(() {
      final currentIndex = _currencies.indexOf(_selectedCurrency);
      final nextIndex = (currentIndex + 1) % _currencies.length;
      _selectedCurrency = _currencies[nextIndex];
    });
    _updateConversion();
  }

  Future<double> _getAmountInSats() async {
    final amount = double.tryParse(_amount) ?? 0.0;

    if (_selectedCurrency == 'sats') {
      return amount;
    }

    // Use YadioService for direct currency conversion
    try {
      final sats = await _yadioService.convertToSats(
        amount: amount,
        currency: _selectedCurrency,
      );
      return sats.toDouble();
    } catch (e) {
      print('Error converting to sats: $e');
      return 0.0;
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
        _cachedSatsAmount = double.tryParse(_amount) ?? 0.0;
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

    // Increment request ID to track latest request
    final requestId = ++_conversionRequestId;

    // Wait 800ms before making API request (debounce for user input)
    _conversionTimer = Timer(const Duration(milliseconds: 800), () async {
      // Ignore stale responses
      if (requestId != _conversionRequestId) return;

      try {
        final satsAmount = await _getAmountInSats();
        // Only update if this is still the latest request
        if (mounted && requestId == _conversionRequestId) {
          setState(() {
            _cachedSatsAmount = satsAmount;
            _isConverting = false;
          });
        }
      } catch (e) {
        // Only update if this is still the latest request
        if (mounted && requestId == _conversionRequestId) {
          print('Error updating conversion: $e');
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
      return ' / calculando...';
    }

    if (_cachedSatsAmount > 0) {
      return ' / ${_cachedSatsAmount.toStringAsFixed(0)} sats';
    }

    return ' / -- sats';
  }

  Future<void> _processPayment() async {
    if (_isProcessingPayment) return;

    // Use cached amount if available, otherwise calculate
    double satsAmount = _cachedSatsAmount;
    if (satsAmount <= 0) {
      satsAmount = await _getAmountInSats();
    }

    if (satsAmount <= 0) {
      if (mounted) _showErrorSnackBar('Por favor ingresa un monto válido');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Process payment based on destination type (LNURL vs Lightning Address)
      if (widget.destinationType == 'lnurl') {
        await _processLNURLPayment(satsAmount.round());
      } else if (widget.destinationType == 'lightning_address') {
        await _processLightningAddressPayment(satsAmount.round());
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error procesando pago: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _processLNURLPayment(int satsAmount) async {
    try {
      print('[AMOUNT_SCREEN] Processing LNURL payment');

      // Get required providers for authentication and wallet access
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();

      if (authProvider.sessionData == null) {
        throw Exception('Sin sesión activa');
      }

      if (walletProvider.primaryWallet == null) {
        throw Exception('Sin billetera principal disponible');
      }

      final session = authProvider.sessionData!;
      final wallet = walletProvider.primaryWallet!;

      _showSuccessSnackBar('Enviando pago LNURL...');

      // Send payment directly to LNURL using LNBits
      final paymentResult = await _invoiceService.sendPaymentToLNURL(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey,
        lnurl: widget.destination,
        amountSats: satsAmount,
        comment: null, // TODO: Add comment support in UI
      );

      print('[AMOUNT_SCREEN] LNURL payment sent successfully: $paymentResult');

      // Check payment status from response to provide appropriate user feedback
      final paymentStatus =
          paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' ||
          paymentStatus == 'settled' ||
          paymentStatus == 'paid';

      if (isPending) {
        _showPendingSnackBar('Pago LNURL pendiente - Factura Hold detectada');
      } else if (isSuccess) {
        _showSuccessSnackBar('Pago LNURL completado exitosamente!');
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

      if (e.toString().contains('not found') ||
          e.toString().contains('no encontrada')) {
        errorMessage = 'LNURL no encontrada';
      } else if (e.toString().contains('Minimum amount') ||
          e.toString().contains('Minimum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Maximum amount') ||
          e.toString().contains('Maximum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Insufficient balance') ||
          e.toString().contains('Saldo insuficiente')) {
        errorMessage = 'Saldo insuficiente para realizar el pago';
      } else if (e.toString().contains('authentication') ||
          e.toString().contains('authentication')) {
        errorMessage = 'Authentication error. Please try logging in again.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Request timeout. Please check your connection.';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _processLightningAddressPayment(int satsAmount) async {
    try {
      print('[AMOUNT_SCREEN] Processing Lightning Address payment');

      // Get required providers for authentication and wallet access
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();

      if (authProvider.sessionData == null) {
        throw Exception('Sin sesión activa');
      }

      if (walletProvider.primaryWallet == null) {
        throw Exception('Sin billetera principal disponible');
      }

      final session = authProvider.sessionData!;
      final wallet = walletProvider.primaryWallet!;

      _showSuccessSnackBar('Sending Lightning Address payment...');

      // Send payment directly to Lightning Address using LNBits
      final paymentResult = await _invoiceService.sendPaymentToLightningAddress(
        serverUrl: session.serverUrl,
        adminKey: wallet.adminKey,
        lightningAddress: widget.destination,
        amountSats: satsAmount,
        comment: null, // TODO: Add comment support in UI
      );

      print('[AMOUNT_SCREEN] Payment sent successfully: $paymentResult');

      // Check payment status from response to provide appropriate user feedback
      final paymentStatus =
          paymentResult['status']?.toString()?.toLowerCase() ?? 'unknown';
      final isPending = paymentStatus == 'pending';
      final isSuccess = paymentStatus == 'complete' ||
          paymentStatus == 'settled' ||
          paymentStatus == 'paid';

      if (isPending) {
        _showPendingSnackBar(
            'Pago Lightning Address pendiente - Factura Hold detectada');
      } else if (isSuccess) {
        _showSuccessSnackBar('Pago Lightning Address completado exitosamente!');
      } else {
        _showSuccessSnackBar(
            'Pago Lightning Address enviado! Estado: $paymentStatus');
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

      if (e.toString().contains('not found') ||
          e.toString().contains('no encontrada')) {
        errorMessage = 'Lightning Address no encontrada';
      } else if (e.toString().contains('Minimum amount') ||
          e.toString().contains('Minimum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Maximum amount') ||
          e.toString().contains('Maximum amount')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Insufficient balance') ||
          e.toString().contains('Saldo insuficiente')) {
        errorMessage = 'Saldo insuficiente para realizar el pago';
      } else if (e.toString().contains('authentication') ||
          e.toString().contains('authentication')) {
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
            Text(message),
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
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.withOpacity(0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNumberButton(
      String text, VoidCallback onPressed, bool isMobile) {
    return Container(
      height: isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
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

  Widget _buildActionButton(String text, VoidCallback onPressed,
      {IconData? icon, required bool isMobile}) {
    return Container(
      height: isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.08),
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
        child: icon != null
            ? Icon(icon, color: Colors.white, size: isMobile ? 18 : 20)
            : Text(
                text,
                style: TextStyle(
                  fontSize: (text == '00' ||
                          text == '000' ||
                          text == 'sats' ||
                          text == 'CUP' ||
                          text == 'USD')
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

                        // Title and recipient
                        Column(
                          children: [
                            Text(
                              'Enviar a',
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
                                color: Colors.white.withOpacity(0.8),
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 32.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isMobile ? 16 : 24),

                          // Amount display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  _formatDisplayAmount(),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isMobile ? 32 : 40,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_selectedCurrency != 'sats') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '≈ ${_cachedSatsAmount.toStringAsFixed(0)} sats',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: isMobile ? 20 : 32),

                          // Numeric keypad
                          Flexible(
                            child: Container(
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
                                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildNumberButton(
                                                '1',
                                                () => _onNumberPressed('1'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '2',
                                                () => _onNumberPressed('2'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '3',
                                                () => _onNumberPressed('3'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildActionButton(
                                                '⌫', _onDeletePressed,
                                                icon: Icons.backspace_outlined,
                                                isMobile: isMobile)),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildNumberButton(
                                                '4',
                                                () => _onNumberPressed('4'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '5',
                                                () => _onNumberPressed('5'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '6',
                                                () => _onNumberPressed('6'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildActionButton('00',
                                                () => _onZerosPressed('00'),
                                                isMobile: isMobile)),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildNumberButton(
                                                '7',
                                                () => _onNumberPressed('7'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '8',
                                                () => _onNumberPressed('8'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '9',
                                                () => _onNumberPressed('9'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildActionButton('000',
                                                () => _onZerosPressed('000'),
                                                isMobile: isMobile)),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: _buildActionButton(
                                                '.', _onDecimalPressed,
                                                isMobile: isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildNumberButton(
                                                '0',
                                                () => _onNumberPressed('0'),
                                                isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildActionButton(
                                                'C', _onClearPressed,
                                                isMobile: isMobile)),
                                        SizedBox(width: isMobile ? 8 : 12),
                                        Expanded(
                                            child: _buildActionButton(
                                                _selectedCurrency,
                                                _toggleCurrency,
                                                isMobile: isMobile)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: (double.tryParse(_amount) ?? 0) > 0 &&
                                      !_isProcessingPayment
                                  ? _processPayment
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (double.tryParse(_amount) ?? 0) > 0
                                        ? const Color(0xFF2D3FE7)
                                        : Colors.white.withOpacity(0.08),
                                foregroundColor: Colors.white,
                                elevation:
                                    (double.tryParse(_amount) ?? 0) > 0 ? 8 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: (double.tryParse(_amount) ?? 0) > 0
                                        ? const Color(0xFF4C63F7)
                                        : Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                shadowColor: (double.tryParse(_amount) ?? 0) > 0
                                    ? const Color(0xFF2D3FE7).withOpacity(0.3)
                                    : Colors.transparent,
                              ),
                              child: _isProcessingPayment
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'PROCESANDO...',
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
                                        color:
                                            (double.tryParse(_amount) ?? 0) > 0
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.4),
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
                                      Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Loading rates...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
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
