import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/ln_address_provider.dart';
import '../providers/currency_settings_provider.dart';
import '../models/ln_address.dart';
import '../services/invoice_service.dart';
import '../services/yadio_service.dart';
import '../services/transaction_detector.dart';
import '../models/lightning_invoice.dart';
import '../models/wallet_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../widgets/universal_screen_wrapper.dart';
import '7ln_address_screen.dart';
import 'voucher_scan_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  // Cache for generated LNURL
  String? _cachedLightningAddress;
  String? _cachedLNURL;
  Future<String?>? _lnurlFuture;
  
  // State for information panel
  bool _isInfoExpanded = false;
  
  // State for request amount modal
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCurrency = 'sats';
  List<String> _currencies = ['sats'];
  
  // State for generated invoice
  LightningInvoice? _generatedInvoice;
  final InvoiceService _invoiceService = InvoiceService();
  final YadioService _yadioService = YadioService();
  final TransactionDetector _transactionDetector = TransactionDetector();
  bool _isGeneratingInvoice = false;
  
  // Timer to verify invoice payment
  Timer? _invoicePaymentTimer;

  // Timer that stops invoice monitoring after a long idle window
  Timer? _invoicePaymentTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLightningAddress();
      _initializeCurrencies();
    });
  }
  
  void _initializeCurrencies() async {
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final authProvider = context.read<AuthProvider>();
    
    print('[RECEIVE_SCREEN] Initializing currencies...');
    print('[RECEIVE_SCREEN] Server URL: ${authProvider.currentServer}');
    
    // Ensure provider has server URL configured
    if (authProvider.currentServer != null) {
      await currencyProvider.updateServerUrl(authProvider.currentServer);
      
      // Force load exchange rates to ensure they're available
      await currencyProvider.loadExchangeRates(forceRefresh: true);
      
      print('[RECEIVE_SCREEN] Available currencies: ${currencyProvider.availableCurrencies}');
      print('[RECEIVE_SCREEN] Exchange rates loaded: ${currencyProvider.availableCurrencies.isNotEmpty}');
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
    
    print('[RECEIVE_SCREEN] Final currencies: $_currencies');
    print('[RECEIVE_SCREEN] Selected currency: $_selectedCurrency');
  }
  
  /// Convert fiat amount to sats using inverse conversion (same method as amount_screen)
  Future<int> _getAmountInSats(double amount, String currency) async {
    print('[RECEIVE_SCREEN] Converting $amount $currency to sats');
    
    if (currency == 'sats') {
      return amount.round();
    }
    
    // Use INVERSE conversion from the working convertSatsToFiat method
    // This ensures we use exactly the same rates as home_screen
    try {
      final currencyProvider = context.read<CurrencySettingsProvider>();
      
      print('[RECEIVE_SCREEN] Using inverse conversion method for consistency');
      
      // Step 1: Get rate by converting 1 BTC (100M sats) to fiat
      const oneBtcInSats = 100000000; // 1 BTC = 100M sats
      final oneBtcInFiat = await currencyProvider.convertSatsToFiat(oneBtcInSats, currency);
      
      print('[RECEIVE_SCREEN] Rate check: $oneBtcInSats sats = $oneBtcInFiat $currency');
      
      // Step 2: Parse the result to get numeric rate
      final fiatString = oneBtcInFiat.replaceAll(RegExp(r'[^\d.]'), ''); // Remove non-numeric chars
      final oneBtcRate = double.tryParse(fiatString);
      
      if (oneBtcRate == null || oneBtcRate <= 0) {
        throw Exception('Invalid rate obtained: $oneBtcInFiat');
      }
      
      print('[RECEIVE_SCREEN] Parsed rate: 1 BTC = $oneBtcRate $currency');
      
      // Step 3: Calculate sats using inverse proportion
      // If 1 BTC = oneBtcRate fiat, then amount fiat = ? sats
      // sats = (amount / oneBtcRate) * 100000000
      final btcAmount = amount / oneBtcRate;
      final satsAmount = (btcAmount * 100000000).round();
      
      print('[RECEIVE_SCREEN] Conversion successful: $amount $currency = $satsAmount sats');
      print('[RECEIVE_SCREEN] Math: ($amount / $oneBtcRate) * 100000000 = $satsAmount');
      
      return satsAmount;
      
    } catch (e) {
      print('[RECEIVE_SCREEN] Error with inverse conversion: $e');
      
      // Fallback to YadioService as last resort
      try {
        print('[RECEIVE_SCREEN] Trying YadioService fallback');
        final sats = await _yadioService.convertToSats(
          amount: amount,
          currency: currency,
        );
        print('[RECEIVE_SCREEN] YadioService conversion: $amount $currency = $sats sats');
        return sats;
      } catch (fallbackError) {
        print('[RECEIVE_SCREEN] All conversion methods failed: $fallbackError');
        throw Exception('Error de conversión: $fallbackError');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _invoiceService.dispose();
    _yadioService.dispose();
    _invoicePaymentTimer?.cancel();
    _invoicePaymentTimeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeLightningAddress() {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final lnAddressProvider = context.read<LNAddressProvider>();

    // Configure authentication
    if (walletProvider.primaryWallet != null) {
      final wallet = walletProvider.primaryWallet!;
      lnAddressProvider.setAuthHeaders(wallet.inKey, wallet.adminKey);
      lnAddressProvider.setCurrentWallet(wallet.id);
    }

    // Only load addresses if they are not already loaded
    if (lnAddressProvider.currentWalletAddresses.isEmpty && !lnAddressProvider.isLoading) {
      lnAddressProvider.loadAllAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(gradient: context.tokens.backgroundGradient),
        child: SafeArea(
          child: withBottomPadding(
            context,
            Column(
              children: [
                // Header with navigation
                _buildHeader(),
                
                // Main content
                Expanded(
                  child: Consumer3<LNAddressProvider, WalletProvider, AuthProvider>(
                    builder: (context, lnAddressProvider, walletProvider, authProvider, child) {
                      final isMobile = MediaQuery.of(context).size.width < 768;
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24.0 : 32.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: isMobile ? 8 : 12),
                            _buildMainContent(lnAddressProvider, walletProvider),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            extraPadding: 24.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Row with back button and QR button
          Row(
            children: [
              // Back button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.tokens.outline,
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
                    color: context.tokens.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const Spacer(),
              
              // QR Scan button for vouchers
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.tokens.outline,
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
                    Icons.qr_code_scanner,
                    color: context.tokens.textPrimary,
                    size: 20,
                  ),
                  onPressed: _navigateToVoucherScreen,
                  padding: EdgeInsets.zero,
                  tooltip: 'Escanear voucher',
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 0 : 4),
          
          // Centered title
          Text(
            AppLocalizations.of(context)!.receive_title,
            style: TextStyle(
                            fontSize: isMobile ? 40 : 48,
              fontWeight: FontWeight.w700,
              color: context.tokens.textPrimary,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(LNAddressProvider lnAddressProvider, WalletProvider walletProvider) {
    final defaultAddress = lnAddressProvider.defaultAddress;
    
    if (lnAddressProvider.isLoading) {
      return _buildLoadingState();
    }
    
    if (lnAddressProvider.error != null) {
      return _buildErrorState(lnAddressProvider.error!);
    }
    
    if (defaultAddress == null) {
      if (_generatedInvoice != null) {
        return _buildNoAddressInvoiceCard();
      }
      return _buildNoAddressState();
    }

    // Show Lightning Address with QR
    return _buildLightningAddressCard(defaultAddress, walletProvider);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF4C63F7),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.loading_address_text,
              style: TextStyle(
                color: context.tokens.textPrimary.withValues(alpha: 0.8),
                fontSize: 16,
                              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: context.tokens.statusUnhealthy.withValues(alpha: 0.8),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loading_address_error_prefix,
            style: TextStyle(
              color: context.tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
                          ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.tokens.textPrimary.withValues(alpha: 0.8),
              fontSize: 14,
                          ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<LNAddressProvider>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.tokens.accentSolid,
                foregroundColor: context.tokens.accentForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.connect_button,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.alternate_email,
            color: context.tokens.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.not_available_text,
            style: TextStyle(
              color: context.tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
                          ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.lightning_address_description,
            style: TextStyle(
              color: context.tokens.textPrimary.withValues(alpha: 0.8),
              fontSize: 16,
                          ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.tokens.accentSolid, context.tokens.accentSolid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: context.tokens.accentSolid.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showRequestAmountModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.request_quote, color: context.tokens.textPrimary),
                label: Text(
                  AppLocalizations.of(context)!.amount_sats_label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.create_lnaddress_label,
            style: TextStyle(
              color: context.tokens.textPrimary.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LNAddressScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.tokens.accentForeground,
                side: BorderSide(
                  color: context.tokens.textTertiary,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                AppLocalizations.of(context)!.lightning_address_title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressInvoiceCard() {
    final invoice = _generatedInvoice!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildInvoiceQR(invoice)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: context.tokens.accentSolid.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.tokens.accentSolid.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: context.tokens.accentSolid, size: 22),
                const SizedBox(width: 8),
                Text(
                  invoice.formattedAmount,
                  style: TextStyle(
                    color: context.tokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (invoice.memo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              invoice.memo,
              style: TextStyle(
                color: context.tokens.textPrimary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          _buildCopyInvoiceButton(),
          const SizedBox(height: 12),
          _buildClearInvoiceButton(),
        ],
      ),
    );
  }

  Widget _buildCopyInvoiceButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.tokens.accentSolid, context.tokens.accentSolid],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.tokens.accentSolid.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _copyInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(Icons.copy, color: context.tokens.textPrimary, size: 20),
          label: Text(
            AppLocalizations.of(context)!.copy_button,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _copyInvoice() async {
    final invoice = _generatedInvoice;
    if (invoice == null) return;
    await Clipboard.setData(ClipboardData(text: invoice.paymentRequest));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.invoice_copied_message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: context.tokens.accentSolid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLightningAddressCard(LNAddress defaultAddress, WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR Code with LNURL
          _buildQRSection(defaultAddress),
          
          const SizedBox(height: 16),
          
          // Lightning Address and copy button together
          _buildAddressWithCopySection(defaultAddress),
          
          const SizedBox(height: 16),
          
          // Collapsible contextual information
          _buildCollapsibleInfoSection(),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(WalletProvider walletProvider) {
    final wallet = walletProvider.primaryWallet;
    if (wallet == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.tokens.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.tokens.accentSolid,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: context.tokens.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: TextStyle(
                    color: context.tokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Balance: ${wallet.balanceFormatted}',
                  style: TextStyle(
                    color: context.tokens.textPrimary.withValues(alpha: 0.7),
                    fontSize: 14,
                                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDisplay(LNAddress defaultAddress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tokens.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.tokens.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered address
          SizedBox(
            width: double.infinity,
            child: Text(
              defaultAddress.fullAddress,
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                              ),
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQRSection(LNAddress defaultAddress) {
    return Center(
      child: Container(
        // No fixed width, adjusts to content
        padding: const EdgeInsets.all(8), // Reduced to 8 for tighter frame
        decoration: BoxDecoration(
          color: context.tokens.textPrimary,
          borderRadius: BorderRadius.circular(6), // More square: from 16 to 6
          border: Border.all(
            color: context.tokens.outlineStrong,
          ),
        ),
        child: _buildQRCodeWithLNURL(defaultAddress),
      ),
    );
  }

  Widget _buildQRCodeWithLNURL(LNAddress defaultAddress) {
    // If there's a generated invoice, show its QR
    if (_generatedInvoice != null) {
      print('[RECEIVE_SCREEN] Mostrando QR de factura: ${_generatedInvoice!.paymentRequest.substring(0, 20)}...');
      return _buildInvoiceQR(_generatedInvoice!);
    }
    
    // If there's no invoice, show Lightning Address
    final lnurl = defaultAddress.lnurl;
    
    if (lnurl != null && lnurl.isNotEmpty) {
      print('[RECEIVE_SCREEN] Usando LNURL de LNBits: ${lnurl.substring(0, 20)}...${lnurl.substring(lnurl.length - 10)}');
      return _buildSuccessQR(lnurl);
    } else {
      print('[RECEIVE_SCREEN] No hay LNURL en el modelo, usando fallback');
      return _buildFallbackQR(defaultAddress.fullAddress, 'LNURL no disponible en LNBits');
    }
  }

  Widget _buildLoadingQR() {
    return SizedBox(
      height: 220, // Reduced from 280 to 220
      width: 220,  // Reduced from 280 to 220
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32, // Reduced from 40 to 32
            height: 32, // Reduced from 40 to 32
            child: CircularProgressIndicator(
              color: context.tokens.accentSolid,
              strokeWidth: 3, // Reduced from 4 to 3
            ),
          ),
          SizedBox(height: 16), // Reduced from 20 to 16
          Text(
            AppLocalizations.of(context)!.loading_text,
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              color: Colors.grey,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessQR(String lnurl) {
    return QrImageView(
      data: lnurl,
      version: QrVersions.auto,
      size: 220.0, // Reduced from 280 to 220
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H, // High level to support logo
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      embeddedImage: const AssetImage('Logo/chispalogoredondo.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(44, 44), // Proportionally reduced from 56x56 to 44x44
      ),
    );
  }

  Widget _buildFallbackQR(String lightningAddress, String error) {
    return QrImageView(
      data: lightningAddress.toUpperCase(),
      version: QrVersions.auto,
      size: 220.0, // Reduced from 280 to 220
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H, // High level to support logo
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      embeddedImage: const AssetImage('Logo/chispalogoredondo.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(44, 44), // Proportionally reduced from 56x56 to 44x44
      ),
    );
  }

  Widget _buildInvoiceQR(LightningInvoice invoice) {
    return QrImageView(
      data: invoice.paymentRequest,
      version: QrVersions.auto,
      size: 220.0, // Reduced from 280 to 220
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      embeddedImage: const AssetImage('Logo/chispalogoredondo.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(44, 44), // Proportionally reduced from 56x56 to 44x44
      ),
    );
  }

  Widget _buildCopyButton(LNAddress defaultAddress) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.tokens.accentSolid, context.tokens.accentSolid],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.tokens.accentSolid.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _copyPaymentInfo(defaultAddress),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(Icons.copy, color: context.tokens.textPrimary, size: 20),
          label: Text(
            _generatedInvoice != null ? AppLocalizations.of(context)!.copy_button : AppLocalizations.of(context)!.copy_lightning_address,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressWithCopySection(LNAddress defaultAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lightning Address display
        _buildAddressDisplay(defaultAddress),
        
        const SizedBox(height: 12),
        
        // Copy button right below
        _buildCopyButton(defaultAddress),
        
        const SizedBox(height: 12),
        
        // LNURL copy button
        _buildCopyLNURLButton(defaultAddress),
        
        const SizedBox(height: 12),
        
        // Request amount button or clear invoice button
        _generatedInvoice != null 
          ? _buildClearInvoiceButton()
          : _buildRequestAmountButton(),
      ],
    );
  }

  Widget _buildCollapsibleInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.accentSolid.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.tokens.accentSolid.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Button to expand/collapse
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isInfoExpanded = !_isInfoExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.tokens.accentSolid,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.settings_title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C63F7),
                                                  ),
                      ),
                    ),
                    Icon(
                      _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                      color: context.tokens.accentSolid,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Expandable content
          if (_isInfoExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: context.tokens.accentSolid,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.receive_info_text,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.tokens.textPrimary.withValues(alpha: 0.8),
                                            height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestAmountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showRequestAmountModal,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.tokens.accentForeground,
          side: BorderSide(
            color: context.tokens.textTertiary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.request_quote, size: 20),
        label: Text(
          AppLocalizations.of(context)!.amount_sats_label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
                      ),
        ),
      ),
    );
  }

  Widget _buildClearInvoiceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Cancel monitoring of current invoice
          _invoicePaymentTimer?.cancel();
          _invoicePaymentTimeoutTimer?.cancel();

          setState(() {
            _generatedInvoice = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
                  SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.invoice_cleared_message,
                    style: TextStyle(
                                            fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: context.tokens.accentSolid,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: context.tokens.accentForeground,
          side: BorderSide(
            color: context.tokens.textTertiary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.close, size: 20),
        label: Text(
          AppLocalizations.of(context)!.clear_invoice_button,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
                      ),
        ),
      ),
    );
  }

  void _showRequestAmountModal() {
    // Clear fields when opening modal
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedCurrency = 'sats';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              minHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D47),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.tokens.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.request_quote,
                          color: Color(0xFF4C63F7),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.amount_sats_label,
                            style: TextStyle(
                              color: context.tokens.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                                                          ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: context.tokens.textPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Modal content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row for amount and currency selector
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount input
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.amount_label,
                                    style: TextStyle(
                                      color: context.tokens.textPrimary.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: context.tokens.textPrimary,
                                      fontSize: 16,
                                                                          ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        color: context.tokens.textSecondary,
                                      ),
                                      filled: true,
                                      fillColor: context.tokens.inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: context.tokens.outline,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: context.tokens.outline,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4C63F7),
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Currency selector
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.currency_label,
                                  style: TextStyle(
                                    color: context.tokens.textPrimary.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                                                      ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 80,
                                  height: 52,
                                  child: Material(
                                    color: context.tokens.inputFill,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setModalState(() {
                                          final currentIndex = _currencies.indexOf(_selectedCurrency);
                                          final nextIndex = (currentIndex + 1) % _currencies.length;
                                          _selectedCurrency = _currencies[nextIndex];
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: context.tokens.outline,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _selectedCurrency,
                                            style: TextStyle(
                                              color: context.tokens.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                                                                          ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Note input
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.optional_description_label,
                              style: TextStyle(
                                color: context.tokens.textPrimary.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noteController,
                              style: TextStyle(
                                color: context.tokens.textPrimary,
                                fontSize: 16,
                                                              ),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.payment_description_example,
                                hintStyle: TextStyle(
                                  color: context.tokens.textSecondary,
                                ),
                                filled: true,
                                fillColor: context.tokens.inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.tokens.outline,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.tokens.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4C63F7),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Buttons
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.tokens.accentForeground,
                                    side: BorderSide(
                                      color: context.tokens.textTertiary,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel_button,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _confirmRequestAmount(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.tokens.accentSolid,
                                    foregroundColor: context.tokens.accentForeground,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.confirm_button,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRequestAmount() async {
    // Validate that an amount has been entered
    if (_amountController.text.trim().isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invalid_amount_error);
      return;
    }

    // Validate that the amount is valid
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invalid_amount_error);
      return;
    }

    // Close modal
    Navigator.pop(context);

    // Show loading
    setState(() {
      _isGeneratingInvoice = true;
    });

    try {
      // Get necessary data
      final walletProvider = context.read<WalletProvider>();
      final authProvider = context.read<AuthProvider>();
      
      final wallet = walletProvider.primaryWallet;
      final serverUrl = authProvider.sessionData?.serverUrl;
      
      if (wallet == null || serverUrl == null) {
        throw Exception(AppLocalizations.of(context)!.no_wallet_error);
      }

      // CURRENCY CONVERSION TO SATOSHIS
      print('[RECEIVE_SCREEN] === STARTING CURRENCY CONVERSION ===');
      print('[RECEIVE_SCREEN] Amount: $amount $_selectedCurrency');
      
      // ALWAYS use fresh conversion with consistent rates
      final amountInSats = await _getAmountInSats(amount, _selectedCurrency);
      final conversionMessage = _selectedCurrency == 'sats' 
          ? 'Factura: $amountInSats sats'
          : '$amount $_selectedCurrency / $amountInSats sats';
      
      print('[RECEIVE_SCREEN] Final conversion result: $conversionMessage');
      
      // Basic validations
      if (amountInSats < 1) {
        throw Exception('Monto convertido muy pequeño (mínimo 1 sat)');
      }
        
      // Validate extremely large amounts that can cause server problems
      if (amountInSats > 2100000000000000) { // 21M BTC en sats
        throw Exception('Monto muy grande. Máximo: 21M BTC');
      }
      
      if (amountInSats > 100000000000) { // 1000 BTC as practical limit
        print('[RECEIVE_SCREEN] ⚠️ WARNING: Very large amount ($amountInSats sats = ${(amountInSats/100000000).toStringAsFixed(2)} BTC)');
      }

      print('[RECEIVE_SCREEN] Generando factura: $amountInSats sats');
      print('[RECEIVE_SCREEN] Server: $serverUrl');
      print('[RECEIVE_SCREEN] Wallet: ${wallet.name}');
      print('[RECEIVE_SCREEN] Original currency: $_selectedCurrency');
      print('[RECEIVE_SCREEN] Original amount: $amount');
      print('[RECEIVE_SCREEN] Original rate: ${_selectedCurrency != 'sats' ? (amountInSats / amount) : 'N/A'}');

      // Prepare memo with fiat info as fallback for LNBits limitations
      String? finalMemo;
      if (_noteController.text.trim().isNotEmpty) {
        finalMemo = _noteController.text.trim();
      } else if (_selectedCurrency != 'sats') {
        // Use fiat amount as memo when no custom note (fallback for LNBits)
        finalMemo = '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $_selectedCurrency';
      }

      // Generate invoice with amount in satoshis and original fiat information.
      // Receiving only needs LNbits invoice key (read+create), not admin.
      final invoice = await _invoiceService.createInvoice(
        serverUrl: serverUrl,
        adminKey: wallet.inKey,
        amount: amountInSats,
        memo: finalMemo,
        comment: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        originalFiatCurrency: _selectedCurrency != 'sats' ? _selectedCurrency : null,
        originalFiatAmount: _selectedCurrency != 'sats' ? amount : null,
        originalFiatRate: _selectedCurrency != 'sats' ? (amountInSats / amount) : null,
      );

      // Update state
      setState(() {
        _generatedInvoice = invoice;
        _isGeneratingInvoice = false;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversionMessage.isNotEmpty ? conversionMessage : 'Factura: ${invoice.formattedAmount}',
                      style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.statusHealthy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      print('[RECEIVE_SCREEN] Factura generada exitosamente: ${invoice.paymentHash}');
      
      // Start automatic verification of invoice payment
      _startInvoicePaymentMonitoring(invoice, wallet, serverUrl);

    } catch (e) {
      print('[RECEIVE_SCREEN] Error generando factura: $e');
      
      setState(() {
        _isGeneratingInvoice = false;
      });
      
      _showErrorSnackBar('Error generando factura: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: context.tokens.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: context.tokens.statusUnhealthy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: context.tokens.textPrimary, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: context.tokens.accentSolid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyPaymentInfo(LNAddress defaultAddress) async {
    String textToCopy;
    String successMessage;
    
    if (_generatedInvoice != null) {
      // If there's a generated invoice, copy the invoice
      textToCopy = _generatedInvoice!.paymentRequest;
      successMessage = AppLocalizations.of(context)!.copy_button;
    } else {
      // If there's no invoice, copy the Lightning Address
      textToCopy = defaultAddress.fullAddress;
      successMessage = AppLocalizations.of(context)!.address_copied_message;
    }
    
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                successMessage,
                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.accentSolid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startInvoicePaymentMonitoring(LightningInvoice invoice, WalletInfo wallet, String serverUrl) {
    print('[RECEIVE_SCREEN] Iniciando monitoreo de pago para factura: ${invoice.paymentHash}');

    // Cancel previous timers if they exist
    _invoicePaymentTimer?.cancel();
    _invoicePaymentTimeoutTimer?.cancel();

    // Check every 5 seconds if the invoice was paid (gentle on rate-limited servers)
    _invoicePaymentTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        // Check invoice status — read-only operation, invoice key is enough
        final isPaid = await _invoiceService.checkInvoiceStatus(
          serverUrl: serverUrl,
          adminKey: wallet.inKey,
          paymentHash: invoice.paymentHash,
        );
        
        if (isPaid) {
          print('[RECEIVE_SCREEN] Invoice paid! Starting celebration sequence');
          timer.cancel();
          
          if (mounted) {
            // 1. FIRST: Activate spark effect
            print('[RECEIVE_SCREEN] 🎆 Activando efecto chispa por pago recibido');
            _transactionDetector.triggerEventSpark('invoice_paid');
            
            // 2. AFTER: Navigate to HomeScreen to show spark effect
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // 3. FINALLY: Wait a moment and show green notification
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${AppLocalizations.of(context)!.received_label}! ${invoice.formattedAmount}',
                          style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: context.tokens.statusHealthy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } catch (e) {
        print('[RECEIVE_SCREEN] Error verificando estado de factura: $e');
        // Continue checking in case of temporary error
      }
    });
    
    // Auto-cancel after 10 minutes to avoid infinite monitoring.
    // Notify the user and clear the QR so they can regenerate a fresh invoice.
    _invoicePaymentTimeoutTimer = Timer(const Duration(minutes: 10), () {
      _invoicePaymentTimer?.cancel();
      print('[RECEIVE_SCREEN] Timeout: Deteniendo monitoreo de factura');
      if (!mounted) return;
      setState(() {
        _generatedInvoice = null;
      });
      _showInfoSnackBar(
        AppLocalizations.of(context)!.invoice_monitoring_timeout_message,
      );
    });
  }

  Widget _buildCopyLNURLButton(LNAddress defaultAddress) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _copyLNURL(defaultAddress),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.tokens.accentForeground,
          side: BorderSide(
            color: context.tokens.textTertiary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.copy, size: 20),
        label: Text(
          AppLocalizations.of(context)!.copy_lnurl,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
                      ),
        ),
      ),
    );
  }

  void _copyLNURL(LNAddress defaultAddress) async {
    final lnurl = defaultAddress.lnurl;
    
    if (lnurl != null && lnurl.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: lnurl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'LNURL copiado',
                  style: TextStyle(
                                        fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: context.tokens.accentSolid,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: context.tokens.textPrimary, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'LNURL no disponible',
                  style: TextStyle(
                                        fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: context.tokens.statusUnhealthy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyLightningAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: context.tokens.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.address_copied_message,
                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.accentSolid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToVoucherScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoucherScanScreen(),
      ),
    );
  }
}