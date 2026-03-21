import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/ln_address_provider.dart';
import '../models/ln_address.dart';
import '../services/invoice_service.dart';
import '../services/yadio_service.dart';
import '../services/transaction_detector.dart';
import '../models/lightning_invoice.dart';
import '../models/wallet_info.dart';
import '7ln_address_screen.dart';

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
  final List<String> _currencies = ['sats', 'CUP', 'USD'];

  // State for generated invoice
  LightningInvoice? _generatedInvoice;
  final InvoiceService _invoiceService = InvoiceService();
  final YadioService _yadioService = YadioService();
  final TransactionDetector _transactionDetector = TransactionDetector();
  bool _isGeneratingInvoice = false;

  // Timer to verify invoice payment
  Timer? _invoicePaymentTimer;
  Timer? _invoiceTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLightningAddress();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _invoiceService.dispose();
    _yadioService.dispose();
    _invoicePaymentTimer?.cancel();
    _invoiceTimeoutTimer?.cancel();
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
    if (lnAddressProvider.currentWalletAddresses.isEmpty &&
        !lnAddressProvider.isLoading) {
      lnAddressProvider.loadAllAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              // Header with navigation
              _buildHeader(),

              // Main content
              Expanded(
                child:
                    Consumer3<LNAddressProvider, WalletProvider, AuthProvider>(
                  builder: (context, lnAddressProvider, walletProvider,
                      authProvider, child) {
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

          // Centered title
          Text(
            'Recibir',
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
    );
  }

  Widget _buildMainContent(
      LNAddressProvider lnAddressProvider, WalletProvider walletProvider) {
    final defaultAddress = lnAddressProvider.defaultAddress;

    if (lnAddressProvider.isLoading) {
      return _buildLoadingState();
    }

    if (lnAddressProvider.error != null) {
      return _buildErrorState(lnAddressProvider.error!);
    }

    if (defaultAddress == null) {
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
              'Cargando Lightning Address...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontFamily: 'Inter',
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.8),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error cargando Lightning Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<LNAddressProvider>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3FE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.alternate_email,
            color: Colors.white.withOpacity(0.6),
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin Lightning Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea una Lightning Address para recibir pagos más fácilmente',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D3FE7), Color(0xFF4C63F7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D3FE7).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LNAddressScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Lightning Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightningAddressCard(
      LNAddress defaultAddress, WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3FE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Balance: ${wallet.balanceFormatted}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Inter',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // First line: icon + label (centered)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.alternate_email,
                color: const Color(0xFF4C63F7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Lightning Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second line: centered address
          SizedBox(
            width: double.infinity,
            child: Text(
              defaultAddress.fullAddress,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(6), // More square: from 16 to 6
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: _buildQRCodeWithLNURL(defaultAddress),
      ),
    );
  }

  Widget _buildQRCodeWithLNURL(LNAddress defaultAddress) {
    // If there's a generated invoice, show its QR
    if (_generatedInvoice != null) {
      print(
          '[RECEIVE_SCREEN] Mostrando QR de factura: ${_generatedInvoice!.paymentRequest.substring(0, 20)}...');
      return _buildInvoiceQR(_generatedInvoice!);
    }

    // If there's no invoice, show Lightning Address
    final lnurl = defaultAddress.lnurl;

    if (lnurl != null && lnurl.isNotEmpty) {
      print(
          '[RECEIVE_SCREEN] Usando LNURL de LNBits: ${lnurl.substring(0, 20)}...${lnurl.substring(lnurl.length - 10)}');
      return _buildSuccessQR(lnurl);
    } else {
      print('[RECEIVE_SCREEN] No hay LNURL en el modelo, usando fallback');
      return _buildFallbackQR(
          defaultAddress.fullAddress, 'LNURL no disponible en LNBits');
    }
  }

  Widget _buildLoadingQR() {
    return const SizedBox(
      height: 220, // Reduced from 280 to 220
      width: 220, // Reduced from 280 to 220
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32, // Reduced from 40 to 32
            height: 32, // Reduced from 40 to 32
            child: CircularProgressIndicator(
              color: Color(0xFF2D3FE7),
              strokeWidth: 3, // Reduced from 4 to 3
            ),
          ),
          SizedBox(height: 16), // Reduced from 20 to 16
          Text(
            'Resolviendo LNURL...',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              color: Colors.grey,
              fontFamily: 'Inter',
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
      embeddedImage: const AssetImage('Logo/chispa_logo.png'),
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
      embeddedImage: const AssetImage('Logo/chispa_logo.png'),
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
      embeddedImage: const AssetImage('Logo/chispa_logo.png'),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF2D3FE7), Color(0xFF4C63F7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D3FE7).withOpacity(0.3),
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
          icon: const Icon(Icons.copy, color: Colors.white, size: 20),
          label: Text(
            _generatedInvoice != null
                ? 'Copiar Factura'
                : 'Copiar Lightning Address',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.white,
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
        color: const Color(0xFF2D3FE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D3FE7).withOpacity(0.2),
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
                      color: const Color(0xFF4C63F7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Información de uso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C63F7),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Icon(
                      _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF4C63F7),
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
                  const Divider(
                    color: Color(0xFF2D3FE7),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Comparte tu Lightning Address para recibir pagos de cualquier monto\n\n• El código QR se resuelve automáticamente a LNURL para máxima compatibilidad\n\n• Los pagos se reciben directamente en esta billetera',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
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
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.request_quote, size: 20),
        label: const Text(
          'Solicitar monto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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

          setState(() {
            _generatedInvoice = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Vuelto a Lightning Address',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4C63F7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text(
          'Nueva solicitud',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D47),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
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
                    const Expanded(
                      child: Text(
                        'Solicitar monto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Modal content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  'Monto',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
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
                                'Moneda',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 80,
                                height: 52,
                                child: Material(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setModalState(() {
                                        final currentIndex = _currencies
                                            .indexOf(_selectedCurrency);
                                        final nextIndex = (currentIndex + 1) %
                                            _currencies.length;
                                        _selectedCurrency =
                                            _currencies[nextIndex];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _selectedCurrency,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
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
                            'Nota (opcional)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej: Pago por servicios',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
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

                      const Spacer(),

                      // Buttons
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _confirmRequestAmount(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D3FE7),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Confirmar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRequestAmount() async {
    // Validate that an amount has been entered
    if (_amountController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor ingresa un monto');
      return;
    }

    // Validate that the amount is valid
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Monto inválido');
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
        throw Exception('Sin billetera o servidor configurado');
      }

      // CURRENCY CONVERSION TO SATOSHIS
      int amountInSats;
      String conversionMessage = '';

      if (_selectedCurrency == 'sats') {
        // If already in sats, use directly
        amountInSats = amount.toInt();

        print('[RECEIVE_SCREEN] Monto directo en sats: $amountInSats');
      } else {
        // Convert using Yadio.io
        print(
            '[RECEIVE_SCREEN] Convirtiendo $amount $_selectedCurrency a sats usando Yadio');

        amountInSats = await _yadioService.convertToSats(
          amount: amount,
          currency: _selectedCurrency,
        );

        conversionMessage = '$amount $_selectedCurrency / $amountInSats sats';
        print('[RECEIVE_SCREEN] Conversion completed: $conversionMessage');

        // Basic validations
        if (amountInSats < 1) {
          throw Exception('Monto convertido muy pequeño (mínimo 1 sat)');
        }

        // Validate extremely large amounts that can cause server problems
        if (amountInSats > 2100000000000000) {
          // 21M BTC en sats
          throw Exception('Monto muy grande. Máximo: 21M BTC');
        }

        if (amountInSats > 100000000000) {
          // 1000 BTC as practical limit
          print(
              '[RECEIVE_SCREEN] ⚠️ WARNING: Very large amount ($amountInSats sats = ${(amountInSats / 100000000).toStringAsFixed(2)} BTC)');
        }
      }

      print('[RECEIVE_SCREEN] Generando factura: $amountInSats sats');
      print('[RECEIVE_SCREEN] Server: $serverUrl');
      print('[RECEIVE_SCREEN] Wallet: ${wallet.name}');

      // Generate invoice with amount in satoshis
      final invoice = await _invoiceService.createInvoice(
        serverUrl: serverUrl,
        adminKey: wallet.adminKey,
        amount: amountInSats,
        memo: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
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
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversionMessage.isNotEmpty
                          ? conversionMessage
                          : 'Factura: ${invoice.formattedAmount}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      print(
          '[RECEIVE_SCREEN] Factura generada exitosamente: ${invoice.paymentHash}');

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
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
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
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4C63F7),
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
      successMessage = 'Factura copiada';
    } else {
      // If there's no invoice, copy the Lightning Address
      textToCopy = defaultAddress.fullAddress;
      successMessage = 'Lightning Address copiada';
    }

    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                successMessage,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D3FE7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startInvoicePaymentMonitoring(
      LightningInvoice invoice, WalletInfo wallet, String serverUrl) {
    print(
        '[RECEIVE_SCREEN] Iniciando monitoreo de pago para factura: ${invoice.paymentHash}');

    // Cancel previous timer if it exists
    _invoicePaymentTimer?.cancel();

    // Check every 2 seconds if the invoice was paid
    _invoicePaymentTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        // Check invoice status
        final isPaid = await _invoiceService.checkInvoiceStatus(
          serverUrl: serverUrl,
          adminKey: wallet.adminKey,
          paymentHash: invoice.paymentHash,
        );

        if (isPaid) {
          print('[RECEIVE_SCREEN] Invoice paid! Starting celebration sequence');
          timer.cancel();

          if (mounted) {
            // 1. FIRST: Activate spark effect
            print(
                '[RECEIVE_SCREEN] 🎆 Activando efecto chispa por pago recibido');
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
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Pago recibido! ${invoice.formattedAmount}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
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

    // Auto-cancel after 10 minutes to avoid infinite monitoring
    _invoiceTimeoutTimer?.cancel();
    _invoiceTimeoutTimer = Timer(const Duration(minutes: 10), () {
      _invoicePaymentTimer?.cancel();
      print('[RECEIVE_SCREEN] Timeout: Deteniendo monitoreo de factura');
    });
  }

  void _copyLightningAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Lightning Address copiada',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D3FE7),
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
