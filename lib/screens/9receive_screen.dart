import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/ln_address_provider.dart';
import '../providers/currency_settings_provider.dart';
import '../models/ln_address.dart';
import '../services/invoice_service.dart';
import '../services/yadio_service.dart';
import '../services/transaction_detector.dart';
import '../services/nfc_charge_service.dart';
import '../models/lightning_invoice.dart';
import '../models/wallet_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '7ln_address_screen.dart';
import 'voucher_scan_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCurrency = 'sats';
  List<String> _currencies = ['sats'];

  LightningInvoice? _generatedInvoice;
  final InvoiceService _invoiceService = InvoiceService();
  final YadioService _yadioService = YadioService();
  final TransactionDetector _transactionDetector = TransactionDetector();
  bool _isGeneratingInvoice = false;
  bool _isCheckingInvoiceStatus = false;

  Timer? _invoicePaymentTimer;
  Timer? _invoicePaymentTimeoutTimer;

  bool _nfcAvailable = false;
  bool _nfcChecked = false;
  bool _isHceActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLightningAddress();
      _initializeCurrencies();
      _checkNfcAvailability();
    });
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcChargeService.isAvailable();
    if (!mounted) return;
    setState(() {
      _nfcAvailable = available;
      _nfcChecked = true;
    });
  }

  void _initializeCurrencies() async {
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentServer != null) {
      await currencyProvider.updateServerUrl(authProvider.currentServer);
      await currencyProvider.loadExchangeRates(forceRefresh: true);
    }

    final displaySequence = currencyProvider.displaySequence;

    if (mounted) {
      setState(() {
        _currencies = displaySequence.isNotEmpty ? displaySequence : ['sats'];
        if (!_currencies.contains(_selectedCurrency)) {
          _selectedCurrency = _currencies.first;
        }
      });
    }
  }

  Future<int> _getAmountInSats(double amount, String currency) async {
    if (currency == 'sats') {
      return amount.round();
    }

    try {
      final currencyProvider = context.read<CurrencySettingsProvider>();
      const oneBtcInSats = 100000000;
      final oneBtcInFiat = await currencyProvider.convertSatsToFiat(oneBtcInSats, currency);

      final fiatString = oneBtcInFiat.replaceAll(RegExp(r'[^\d.]'), '');
      final oneBtcRate = double.tryParse(fiatString);

      if (oneBtcRate == null || oneBtcRate <= 0) {
        throw Exception('Invalid rate obtained: $oneBtcInFiat');
      }

      final btcAmount = amount / oneBtcRate;
      return (btcAmount * 100000000).round();
    } catch (e) {
      try {
        return await _yadioService.convertToSats(
          amount: amount,
          currency: currency,
        );
      } catch (fallbackError) {
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
    final walletProvider = context.read<WalletProvider>();
    final lnAddressProvider = context.read<LNAddressProvider>();

    if (walletProvider.primaryWallet != null) {
      final wallet = walletProvider.primaryWallet!;
      lnAddressProvider.setAuthHeaders(wallet.inKey, wallet.adminKey);
      lnAddressProvider.setCurrentWallet(wallet.id);
    }

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
          child: Consumer3<LNAddressProvider, WalletProvider, AuthProvider>(
            builder: (context, lnAddressProvider, walletProvider, authProvider, child) {
              final defaultAddress = lnAddressProvider.defaultAddress;
              final hasContent = (defaultAddress != null) || (_generatedInvoice != null);
              final showBottomBar = hasContent &&
                  !lnAddressProvider.isLoading &&
                  lnAddressProvider.error == null;

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildContent(lnAddressProvider, walletProvider),
                  ),
                  if (showBottomBar) _buildBottomActionBar(defaultAddress),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              _buildIconButton(
                icon: Icons.qr_code_scanner,
                onPressed: _navigateToVoucherScreen,
                tooltip: 'Escanear voucher',
              ),
            ],
          ),
          SizedBox(height: isMobile ? 0 : 4),
          Text(
            AppLocalizations.of(context)!.receive_title,
            style: TextStyle(
              fontSize: isMobile ? 36 : 44,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
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
        icon: Icon(icon, color: context.tokens.textPrimary, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildContent(LNAddressProvider lnAddressProvider, WalletProvider walletProvider) {
    if (lnAddressProvider.isLoading) {
      return _buildLoadingState();
    }

    if (lnAddressProvider.error != null) {
      return _buildErrorState(lnAddressProvider.error!);
    }

    final defaultAddress = lnAddressProvider.defaultAddress;
    if (defaultAddress == null && _generatedInvoice == null) {
      return _buildNoAddressState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: _buildMainCard(defaultAddress),
    );
  }

  Widget _buildMainCard(LNAddress? defaultAddress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tokens.outline, width: 1),
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
          Center(child: _buildQRCard(defaultAddress)),
          const SizedBox(height: 16),
          if (defaultAddress != null) _buildAddressDisplay(defaultAddress),
          if (_generatedInvoice != null) ...[
            if (defaultAddress != null) const SizedBox(height: 12),
            _buildAmountChip(_generatedInvoice!),
          ],
          const SizedBox(height: 20),
          _buildPrimaryCta(),
        ],
      ),
    );
  }

  Widget _buildQRCard(LNAddress? defaultAddress) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.tokens.textPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outlineStrong),
      ),
      child: _buildQRImage(defaultAddress),
    );
  }

  Widget _buildQRImage(LNAddress? defaultAddress) {
    if (_generatedInvoice != null) {
      return _buildQR(_generatedInvoice!.paymentRequest);
    }

    final lnurl = defaultAddress?.lnurl;
    if (lnurl != null && lnurl.isNotEmpty) {
      return _buildQR(lnurl);
    }
    return _buildQR(defaultAddress?.fullAddress.toUpperCase() ?? '');
  }

  Widget _buildQR(String data) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 220.0,
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
        size: Size(44, 44),
      ),
    );
  }

  Widget _buildAddressDisplay(LNAddress defaultAddress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.tokens.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline),
      ),
      child: Text(
        defaultAddress.fullAddress,
        style: TextStyle(
          color: context.tokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }

  Widget _buildAmountChip(LightningInvoice invoice) {
    final hasMemo = invoice.memo.isNotEmpty;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.tokens.accentSolid.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.tokens.accentSolid.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: context.tokens.accentSolid, size: 16),
            const SizedBox(width: 6),
            Text(
              invoice.formattedAmount,
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasMemo) ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: context.tokens.textPrimary.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  invoice.memo,
                  style: TextStyle(
                    color: context.tokens.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryCta() {
    final hasInvoice = _generatedInvoice != null;
    if (hasInvoice) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _clearInvoice,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

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
          onPressed: _isGeneratingInvoice ? null : _showRequestAmountModal,
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
    );
  }

  Widget _buildBottomActionBar(LNAddress? defaultAddress) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
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
            icon: Icons.content_copy_rounded,
            label: AppLocalizations.of(context)!.copy_button,
            onTap: () => _showCopySheet(defaultAddress),
          ),
          _buildBarAction(
            icon: Icons.nfc_rounded,
            label: AppLocalizations.of(context)!.nfc_action_label,
            enabled: _nfcAvailable,
            onTap: _nfcAvailable ? _activateNfc : _showNfcUnavailable,
          ),
          _buildBarAction(
            icon: Icons.ios_share_rounded,
            label: AppLocalizations.of(context)!.share_button,
            onTap: () => _shareContent(defaultAddress),
          ),
        ],
      ),
    );
  }

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
          onTap: onTap,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: context.tokens.accentSolid,
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
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.tokens.outline, width: 1),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddressState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.tokens.outline, width: 1),
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
      ),
    );
  }

  void _clearInvoice() {
    _invoicePaymentTimer?.cancel();
    _invoicePaymentTimeoutTimer?.cancel();
    setState(() {
      _generatedInvoice = null;
    });
    _showAccentSnackBar(
      icon: Icons.check_circle,
      message: AppLocalizations.of(context)!.invoice_cleared_message,
    );
  }

  void _showCopySheet(LNAddress? defaultAddress) {
    final hasInvoice = _generatedInvoice != null;
    final lnurl = defaultAddress?.lnurl;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.tokens.dialogBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          0,
          12,
          0,
          16 + MediaQuery.of(sheetContext).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.tokens.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.content_copy_rounded,
                      color: context.tokens.accentSolid, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.copy_button,
                    style: TextStyle(
                      color: context.tokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (defaultAddress != null)
              _buildSheetItem(
                icon: Icons.alternate_email,
                title: AppLocalizations.of(context)!.lightning_address_title,
                subtitle: defaultAddress.fullAddress,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyToClipboard(
                    defaultAddress.fullAddress,
                    AppLocalizations.of(context)!.address_copied_message,
                  );
                },
              ),
            if (lnurl != null && lnurl.isNotEmpty)
              _buildSheetItem(
                icon: Icons.link_rounded,
                title: 'LNURL',
                subtitle: _truncate(lnurl),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyToClipboard(
                    lnurl,
                    AppLocalizations.of(context)!.lnurl_copied_message,
                  );
                },
              ),
            if (hasInvoice)
              _buildSheetItem(
                icon: Icons.receipt_long_rounded,
                title: AppLocalizations.of(context)!.copy_invoice_button,
                subtitle: _truncate(_generatedInvoice!.paymentRequest),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyToClipboard(
                    _generatedInvoice!.paymentRequest,
                    AppLocalizations.of(context)!.invoice_copied_message,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.tokens.accentSolid.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: context.tokens.accentSolid, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.tokens.textPrimary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.tokens.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncate(String value) {
    if (value.length <= 32) return value;
    return '${value.substring(0, 16)}…${value.substring(value.length - 12)}';
  }

  void _shareContent(LNAddress? defaultAddress) async {
    String? text;
    if (_generatedInvoice != null) {
      text = 'lightning:${_generatedInvoice!.paymentRequest}';
    } else if (defaultAddress != null) {
      text = defaultAddress.fullAddress;
    }
    if (text == null) return;

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: AppLocalizations.of(context)!.receive_title,
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _showNfcUnavailable() {
    _showInfoSnackBar(AppLocalizations.of(context)!.nfc_unavailable_message);
  }

  Future<void> _activateNfc() async {
    if (!_nfcAvailable) {
      _showNfcUnavailable();
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // Sin factura → HCE directo exponiendo LNURL bech32 (funcionaba antes)
    if (_generatedInvoice == null) {
      final lnAddressProvider = context.read<LNAddressProvider>();
      final lnurl = lnAddressProvider.defaultAddress?.lnurl; // LNURL1... bech32
      debugPrint('[HCE_DEBUG] Sin monto - LNURL bech32: $lnurl');
      if (lnurl != null && lnurl.isNotEmpty) {
        debugPrint('[HCE_DEBUG] Iniciando HCE con LNURL: $lnurl');
        _openNfcChargeSheet(lnurl, modo: ModoNfcRecibir.hceWallet);
      } else {
        debugPrint('[HCE_DEBUG] No hay LNURL, solicitando monto');
        _showRequestAmountModal(autoStartNfcAfterGenerate: true);
      }
      return;
    }

    // Con factura → preguntar modo
    final modo = await showDialog<ModoNfcRecibir>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.nfc_mode_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: Text(l10n.nfc_mode_boltcard),
              subtitle: Text(l10n.nfc_mode_boltcard_subtitle),
              onTap: () => Navigator.pop(context, ModoNfcRecibir.lectorBoltcard),
            ),
            ListTile(
              leading: const Icon(Icons.nfc),
              title: Text(l10n.nfc_mode_hce),
              subtitle: Text(l10n.nfc_mode_hce_subtitle),
              onTap: () => Navigator.pop(context, ModoNfcRecibir.hceWallet),
            ),
          ],
        ),
      ),
    );

    if (modo == null) return;

    _openNfcChargeSheet(_generatedInvoice!.paymentRequest, 
                        modo: modo);
  }

  void _openNfcChargeSheet(String contenido, {required ModoNfcRecibir modo}) {
    setState(() {
      _isHceActive = modo == ModoNfcRecibir.hceWallet;
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _NfcChargeSheet(
        invoice: contenido,
        modo: modo,
        onFinish: () {
          setState(() {
            _isHceActive = false;
          });
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _copyToClipboard(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showAccentSnackBar(
      icon: Icons.check_circle,
      message: successMessage,
    );
  }

  void _showRequestAmountModal({bool autoStartNfcAfterGenerate = false, bool modoLector = false}) {
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedCurrency = _currencies.contains('sats') ? 'sats' : _currencies.first;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.9,
              minHeight: MediaQuery.of(modalContext).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: context.tokens.dialogBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.tokens.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.request_quote,
                          color: context.tokens.accentSolid,
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
                          onPressed: () => Navigator.pop(modalContext),
                          icon: Icon(
                            Icons.close,
                            color: context.tokens.textPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                        borderSide: BorderSide(color: context.tokens.outline),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: context.tokens.outline),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: context.tokens.accentSolid),
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
                                          border: Border.all(color: context.tokens.outline),
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
                              borderSide: BorderSide(color: context.tokens.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.tokens.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.tokens.accentSolid),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(modalContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.tokens.accentForeground,
                                    side: BorderSide(color: context.tokens.textTertiary),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel_button,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _confirmRequestAmount(
                                    modalContext,
                                    autoStartNfcAfterGenerate: autoStartNfcAfterGenerate,
                                    modoLector: modoLector,
                                  ),
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
                                    style: const TextStyle(
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

  void _confirmRequestAmount(
    BuildContext modalContext, {
    bool autoStartNfcAfterGenerate = false,
    bool modoLector = false,
  }) async {
    if (_amountController.text.trim().isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invalid_amount_error);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invalid_amount_error);
      return;
    }

    Navigator.pop(modalContext);

    setState(() {
      _isGeneratingInvoice = true;
    });

    try {
      final walletProvider = context.read<WalletProvider>();
      final authProvider = context.read<AuthProvider>();

      final wallet = walletProvider.primaryWallet;
      final serverUrl = authProvider.sessionData?.serverUrl;

      if (wallet == null || serverUrl == null) {
        throw Exception(AppLocalizations.of(context)!.no_wallet_error);
      }

      final amountInSats = await _getAmountInSats(amount, _selectedCurrency);

      if (amountInSats < 1) {
        throw Exception('Monto convertido muy pequeño (mínimo 1 sat)');
      }

      if (amountInSats > 2100000000000000) {
        throw Exception('Monto muy grande. Máximo: 21M BTC');
      }

      String? finalMemo;
      if (_noteController.text.trim().isNotEmpty) {
        finalMemo = _noteController.text.trim();
      } else if (_selectedCurrency != 'sats') {
        finalMemo = '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $_selectedCurrency';
      }

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

      if (!mounted) return;
      setState(() {
        _generatedInvoice = invoice;
        _isGeneratingInvoice = false;
      });

      _showAccentSnackBar(
        icon: Icons.check_circle,
        message: AppLocalizations.of(context)!.invoice_generated_message,
        backgroundColor: context.tokens.statusHealthy,
      );

      _startInvoicePaymentMonitoring(invoice, wallet, serverUrl);

      if (autoStartNfcAfterGenerate && _nfcAvailable) {
        // Decidir modo según si es lector o HCE
        if (modoLector) {
          // Leer BoltCard → usar invoice generada
          if (_generatedInvoice != null) {
            _openNfcChargeSheet(_generatedInvoice!.paymentRequest, 
                                modo: ModoNfcRecibir.lectorBoltcard);
          }
        } else {
          // HCE → usar invoice generada (con monto) o Lightning Address (sin monto)
          if (_generatedInvoice != null) {
            final invoice = _generatedInvoice!.paymentRequest;
            debugPrint('[HCE_DEBUG] Con monto - Exponiendo INVOICE: ${invoice.substring(0, 30)}...');
            debugPrint('[HCE_DEBUG] Con monto - Invoice completa: $invoice');
            _openNfcChargeSheet(invoice, 
                                  modo: ModoNfcRecibir.hceWallet);
          } else {
            final lnAddressProvider = context.read<LNAddressProvider>();
            final lightningAddress = lnAddressProvider.defaultAddress?.fullAddress;
            debugPrint('[HCE_DEBUG] Con monto pero sin invoice - Exponiendo Lightning Address: $lightningAddress');
            if (lightningAddress != null) {
              _openNfcChargeSheet(lightningAddress, modo: ModoNfcRecibir.hceWallet);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _isGeneratingInvoice = false;
      });
      _showErrorSnackBar('Error generando factura: ${e.toString()}');
    }
  }

  void _startInvoicePaymentMonitoring(LightningInvoice invoice, WalletInfo wallet, String serverUrl) {
    _invoicePaymentTimer?.cancel();
    _invoicePaymentTimeoutTimer?.cancel();

    _invoicePaymentTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isCheckingInvoiceStatus) return;
      _isCheckingInvoiceStatus = true;

      try {
        final isPaid = await _invoiceService.checkInvoiceStatus(
          serverUrl: serverUrl,
          adminKey: wallet.inKey,
          paymentHash: invoice.paymentHash,
        );

        if (isPaid) {
          timer.cancel();
          _invoicePaymentTimeoutTimer?.cancel();
          _invoicePaymentTimeoutTimer = null;

          if (mounted) {
            _transactionDetector.triggerEventSpark('invoice_paid');
            Navigator.of(context).popUntil((route) => route.isFirst);

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
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
      } catch (_) {
        // Continue checking on temporary errors
      } finally {
        _isCheckingInvoiceStatus = false;
      }
    });

    _invoicePaymentTimeoutTimer = Timer(const Duration(minutes: 10), () {
      _invoicePaymentTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _generatedInvoice = null;
      });
      _showInfoSnackBar(
        AppLocalizations.of(context)!.invoice_monitoring_timeout_message,
      );
    });
  }

  void _showAccentSnackBar({
    required IconData icon,
    required String message,
    Color? backgroundColor,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: context.tokens.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? context.tokens.accentSolid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
                style: const TextStyle(fontWeight: FontWeight.w500),
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
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

  void _navigateToVoucherScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoucherScanScreen(),
      ),
    );
  }
}

class _NfcChargeSheet extends StatefulWidget {
  final String invoice;
  final ModoNfcRecibir modo;
  final VoidCallback? onFinish;
  const _NfcChargeSheet({
    required this.invoice,
    required this.modo,
    this.onFinish,
  });

  @override
  State<_NfcChargeSheet> createState() => _NfcChargeSheetState();
}

class _NfcChargeSheetState extends State<_NfcChargeSheet> with SingleTickerProviderStateMixin {
  late final NfcChargeService _service;
  NfcChargeStatus _status = NfcChargeStatus.scanning;
  String? _errorMessage;
  bool _autoCloseScheduled = false;
  bool _serviceInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      _service = NfcChargeService(AppLocalizations.of(context)!);
      _serviceInitialized = true;
      debugPrint('[HCE_SHEET] Modo: ${widget.modo}');
      debugPrint('[HCE_SHEET] Contenido: ${widget.invoice}');
      _start();
    }
  }

  Future<void> _start() async {
    await _service.startChargeSession(
      lnurlOrInvoice: widget.invoice,
      modo: widget.modo,
      onStatus: (result) {
        if (!mounted) return;
        setState(() {
          _status = result.status;
          _errorMessage = result.message;
        });
          if (result.status == NfcChargeStatus.success && !_autoCloseScheduled) {
            _autoCloseScheduled = true;
            Future.delayed(const Duration(milliseconds: 1400), () {
              if (mounted) {
                if (widget.onFinish != null) widget.onFinish!();
              }
            });
          }
      },
    );
  }

  @override
  void dispose() {
    _service.stopSession();
    _service.dispose();
    super.dispose();
  }

  Color _statusColor(BuildContext context) {
    switch (_status) {
      case NfcChargeStatus.success:
        return context.tokens.statusHealthy;
      case NfcChargeStatus.invalidTag:
      case NfcChargeStatus.networkError:
      case NfcChargeStatus.callbackError:
        return context.tokens.statusUnhealthy;
      default:
        return context.tokens.accentSolid;
    }
  }

  IconData _statusIcon() {
    switch (_status) {
      case NfcChargeStatus.success:
        return Icons.check_circle_rounded;
      case NfcChargeStatus.invalidTag:
      case NfcChargeStatus.networkError:
      case NfcChargeStatus.callbackError:
        return Icons.error_rounded;
      case NfcChargeStatus.charging:
        return Icons.bolt_rounded;
      case NfcChargeStatus.reading:
        return Icons.contactless_rounded;
      case NfcChargeStatus.scanning:
        return Icons.nfc_rounded;
    }
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_status) {
      case NfcChargeStatus.scanning:
      case NfcChargeStatus.reading:
        return widget.modo == ModoNfcRecibir.hceWallet 
            ? l10n.nfc_hce_message 
            : l10n.nfc_scanning_message;
      case NfcChargeStatus.charging:
        return l10n.nfc_charging_message;
      case NfcChargeStatus.success:
        return l10n.invoice_generated_message;
      case NfcChargeStatus.invalidTag:
        return l10n.nfc_invalid_tag_message;
      case NfcChargeStatus.networkError:
      case NfcChargeStatus.callbackError:
        final detail = _errorMessage?.trim() ?? '';
        return detail.isNotEmpty
            ? '${l10n.nfc_charge_error_prefix}$detail'
            : l10n.nfc_charge_unknown_error;
    }
  }

  bool get _isFinal =>
      _status == NfcChargeStatus.success ||
      _status == NfcChargeStatus.invalidTag ||
      _status == NfcChargeStatus.networkError ||
      _status == NfcChargeStatus.callbackError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _statusColor(context);

    return Container(
      decoration: BoxDecoration(
        color: context.tokens.dialogBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.tokens.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.nfc_scanning_title,
            style: TextStyle(
              color: context.tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(_statusIcon(), color: accent, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            _statusText(context),
            style: TextStyle(
              color: context.tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
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
              child: Text(
                _isFinal ? l10n.close_dialog : l10n.cancel_button,
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
}
