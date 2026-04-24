import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ln_address_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/ln_address.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';

class LNAddressScreen extends StatefulWidget {
  const LNAddressScreen({super.key});

  @override
  State<LNAddressScreen> createState() => _LNAddressScreenState();
}

class _LNAddressScreenState extends State<LNAddressScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedWalletId;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  void _initializeScreen() {
    final walletProvider = context.read<WalletProvider>();
    final lnAddressProvider = context.read<LNAddressProvider>();

    if (walletProvider.primaryWallet != null) {
      final wallet = walletProvider.primaryWallet!;
      _selectedWalletId = wallet.id;

      lnAddressProvider.setAuthHeaders(wallet.inKey, wallet.adminKey);
      lnAddressProvider.setCurrentWallet(_selectedWalletId!);
    }

    lnAddressProvider.loadAllAddresses();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(gradient: t.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [

                  _buildHeader(t),


                  Expanded(
                    child: Consumer3<LNAddressProvider, WalletProvider, AuthProvider>(
                      builder: (context, lnAddressProvider, walletProvider, authProvider, child) {
                        return Column(
                          children: [

                            _buildWalletInfo(walletProvider, authProvider, t),


                            Expanded(
                              child: _showCreateForm
                                  ? _buildCreateForm(lnAddressProvider, walletProvider, t)
                                  : _buildAddressList(lnAddressProvider, t),
                            ),
                          ],
                        );
                      },
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

  Widget _buildHeader(AppTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [

          Container(
            decoration: BoxDecoration(
              color: t.outline,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: t.outlineStrong,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back,
                    color: t.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.lightning_address_title,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),


          Container(
            decoration: BoxDecoration(
              color: t.outline,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: t.outlineStrong,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _refreshAddresses,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.refresh,
                    color: t.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(WalletProvider walletProvider, AuthProvider authProvider, AppTokens t) {
    final serverDomain = authProvider.sessionData?.serverUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '') ?? 'your-server.com';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: t.outline,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: t.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    walletProvider.primaryWallet?.name ?? AppLocalizations.of(context)!.wallet_title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.server_settings_title}: $serverDomain',
              style: TextStyle(
                color: t.textPrimary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(LNAddressProvider lnAddressProvider, AppTokens t) {
    if (lnAddressProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(t.textPrimary),
        ),
      );
    }

    if (lnAddressProvider.error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.outline,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: t.statusUnhealthy,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.loading_address_error_prefix,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lnAddressProvider.error!,
                  style: TextStyle(
                    color: t.textPrimary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildPrimaryButton(
                  text: AppLocalizations.of(context)!.connect_button,
                  onPressed: _refreshAddresses,
                  t: t,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (!lnAddressProvider.hasAddresses)
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: t.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email,
                        color: t.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.not_available_text,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.lightning_address_title,
                        style: TextStyle(
                          color: t.textPrimary.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lnAddressProvider.currentWalletAddresses.length,
              itemBuilder: (context, index) {
                final address = lnAddressProvider.currentWalletAddresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildAddressItem(address, lnAddressProvider, t),
                );
              },
            ),
          ),

        if (!_showCreateForm)
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: _buildPrimaryButton(
                text: AppLocalizations.of(context)!.lightning_address_title,
                onPressed: () {
                  setState(() {
                    _showCreateForm = true;
                  });
                },
                icon: Icons.add,
                t: t,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressItem(LNAddress address, LNAddressProvider lnAddressProvider, AppTokens t) {
    // Amber star for default address — semantic indicator unique to this screen, kept literal
    const amber = Colors.amber;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.alternate_email,
                color: t.accentSolid,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullAddress,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            color: amber,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.lightning_address_title,
                        style: const TextStyle(
                          color: amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAddressAction(value, address, lnAddressProvider),
                iconColor: t.textPrimary,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.lightning_address_copy),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(
                          address.isDefault ? Icons.star : Icons.star_border,
                          size: 18,
                          color: address.isDefault ? amber : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.isDefault
                              ? AppLocalizations.of(context)!.lightning_address_is_default
                              : AppLocalizations.of(context)!.lightning_address_set_default,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: t.statusUnhealthy),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.lightning_address_delete,
                          style: TextStyle(color: t.statusUnhealthy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (address.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              address.description,
              style: TextStyle(
                color: t.textPrimary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? amber.withValues(alpha: 0.2)
                      : (address.isActive
                          ? t.statusHealthy.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: address.isDefault
                        ? amber.withValues(alpha: 0.3)
                        : (address.isActive
                            ? t.statusHealthy.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
                child: Text(
                  address.isDefault ? AppLocalizations.of(context)!.lightning_address_title : (address.isActive ? AppLocalizations.of(context)!.valid_status : AppLocalizations.of(context)!.not_available_text),
                  style: TextStyle(
                    color: address.isDefault ? amber : (address.isActive ? t.statusHealthy : Colors.grey),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Created: ${_formatDate(address.createdAt)}',
                style: TextStyle(
                  color: t.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(LNAddressProvider lnAddressProvider, WalletProvider walletProvider, AppTokens t) {
    final serverDomain = context.read<AuthProvider>().sessionData?.serverUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '') ?? 'your-server.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: t.outline,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: t.accentSolid,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.lightning_address_title,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: t.outline,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _showCreateForm = false;
                            _usernameController.clear();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: t.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),


            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: t.outline,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Wallet:',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: t.outline,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWalletId,
                        isExpanded: true,
                        dropdownColor: t.dialogBackground,
                        style: TextStyle(color: t.textPrimary),
                        icon: Icon(Icons.arrow_drop_down, color: t.textPrimary),
                        items: walletProvider.wallets.map((wallet) {
                          return DropdownMenuItem<String>(
                            value: wallet.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: t.accentSolid,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    wallet.name,
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedWalletId = newValue;
                            });


                            final selectedWallet = walletProvider.wallets.firstWhere(
                              (w) => w.id == newValue,
                            );
                            lnAddressProvider.setAuthHeaders(selectedWallet.inKey, selectedWallet.adminKey);
                            lnAddressProvider.setCurrentWallet(newValue);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Username input
                  Text(
                    'Lightning Address:',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          style: TextStyle(color: t.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'satoshi',
                            hintStyle: TextStyle(
                              color: t.textSecondary,
                            ),
                            filled: true,
                            fillColor: t.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: t.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: t.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: t.accentSolid,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final error = LNAddress.getUsernameError(value);
                            return error.isEmpty ? null : error;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_-]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '@$serverDomain',
                        style: TextStyle(
                          color: t.textPrimary.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Error message
                  if (lnAddressProvider.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.statusUnhealthy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: t.statusUnhealthy.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: t.statusUnhealthy,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lnAddressProvider.error!,
                              style: TextStyle(
                                color: t.statusUnhealthy,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          text: AppLocalizations.of(context)!.cancel_button,
                          onPressed: () {
                            setState(() {
                              _showCreateForm = false;
                              _usernameController.clear();
                            });
                          },
                          t: t,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrimaryButton(
                          text: lnAddressProvider.isCreating ? AppLocalizations.of(context)!.loading_text : AppLocalizations.of(context)!.connect_button,
                          onPressed: lnAddressProvider.isCreating ? null : _createAddress,
                          t: t,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required AppTokens t,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: t.accentSolid,
        foregroundColor: t.accentForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback? onPressed,
    required AppTokens t,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.textPrimary,
        side: BorderSide(
          color: t.textPrimary.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleAddressAction(String action, LNAddress address, LNAddressProvider lnAddressProvider) {
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: address.fullAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.fullAddress} ${AppLocalizations.of(context)!.address_copied_message}'),
            backgroundColor: context.tokens.statusHealthy,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'set_default':
        _setAsDefault(address, lnAddressProvider);
        break;
      case 'delete':
        _showDeleteConfirmation(address, lnAddressProvider);
        break;
    }
  }

  void _setAsDefault(LNAddress address, LNAddressProvider lnAddressProvider) async {
    if (address.isDefault) {
      // If already default, do nothing
      return;
    }

    final success = await lnAddressProvider.setAsDefault(address.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${address.fullAddress} ${AppLocalizations.of(context)!.lightning_address_title}'),
          backgroundColor: context.tokens.statusHealthy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(LNAddress address, LNAddressProvider lnAddressProvider) {
    final t = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.dialogBackground,
        title: Text(
          AppLocalizations.of(context)!.lightning_address_title,
          style: TextStyle(color: t.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${address.fullAddress}?',
          style: TextStyle(color: t.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel_button),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await lnAddressProvider.deleteLNAddress(address.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.lightning_address_title),
                    backgroundColor: context.tokens.statusHealthy,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: t.statusUnhealthy)),
          ),
        ],
      ),
    );
  }

  void _createAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) return;

    context.read<LNAddressProvider>().clearError();

    final walletProvider = context.read<WalletProvider>();
    final selectedWallet = walletProvider.wallets.firstWhere(
      (w) => w.id == _selectedWalletId!,
    );

    final success = await context.read<LNAddressProvider>().createLNAddress(
      username: _usernameController.text.trim().toLowerCase(),
      walletId: _selectedWalletId!,
      description: 'Lightning Address for ${selectedWallet.name}',
      zapsEnabled: true,
    );

    if (success && mounted) {
      setState(() {
        _showCreateForm = false;
        _usernameController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.lightning_address_title),
          backgroundColor: context.tokens.statusHealthy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _refreshAddresses() {
    context.read<LNAddressProvider>().refresh();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
