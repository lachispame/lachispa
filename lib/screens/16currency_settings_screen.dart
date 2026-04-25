import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/currency_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../theme/app_tokens.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCurrencies = [];
  bool _isDropdownOpen = false;
  

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _searchController.addListener(_filterCurrencies);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _filterCurrencies() {
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final query = _searchController.text.toLowerCase();
    
    // Use all currencies from CurrencyInfo instead of server-specific list
    final allCurrencies = CurrencyInfo.allCurrencies.keys.toList();
    
    if (query.isEmpty) {
      _filteredCurrencies = List.from(allCurrencies);
    } else {
      _filteredCurrencies = allCurrencies.where((currency) {
        final currencyInfo = currencyProvider.getCurrencyInfo(currency);
        final name = currencyInfo?.name.toLowerCase() ?? currency.toLowerCase();
        final country = currencyInfo?.country.toLowerCase() ?? '';
        
        return currency.toLowerCase().contains(query) ||
               name.contains(query) ||
               country.contains(query);
      }).toList();
    }
    
    setState(() {});
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (_isDropdownOpen) {
        _filterCurrencies();
      }
    });
  }

  void _selectCurrency(String currency, CurrencySettingsProvider currencyProvider) async {
    if (currency == 'sats') return; // Can't select sats
    
    if (currencyProvider.isCurrencySelected(currency)) {
      // Currency already selected
      setState(() {
        _isDropdownOpen = false;
        _searchController.clear();
      });
      return;
    }
    
    // Show loading state
    setState(() {
      _isDropdownOpen = false;
      _searchController.clear();
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.dialogBackground,
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.tokens.accentBright),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.checking_currency_availability(currency),
                style: TextStyle(color: context.tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
    
    try {
      // Validate currency availability on the current server
      final isAvailable = await currencyProvider.validateCurrencyAvailability(currency);
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (isAvailable) {
        // Currency is available, add it
        await currencyProvider.addCurrency(currency);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.currency_added_successfully(currency)),
                ],
              ),
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Currency is not available on this server
        if (mounted) {
          final currencyInfo = CurrencyInfo.getInfo(currency);
          final currencyName = currencyInfo?.name ?? currency;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.currency_not_available_on_server(currencyName, currency)),
                  ),
                ],
              ),
              backgroundColor: Colors.red.withValues(alpha: 0.9),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.error_checking_currency(currency, e.toString())),
                ),
              ],
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencySettingsProvider>(
      builder: (context, currencyProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: context.tokens.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildHeader(context),
                      );
                    },
                  ),
                  
                  // Content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildContent(context, currencyProvider),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.tokens.outline,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: context.tokens.textPrimary,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.currency_settings_title ?? 'Currency Settings',
                  style: TextStyle(
        fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.currency_settings_subtitle ?? 'Select your preferred currencies',
                  style: TextStyle(
        fontSize: 14,
                    color: context.tokens.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CurrencySettingsProvider currencyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and dropdown section
          _buildSearchAndDropdownSection(currencyProvider),
          
          const SizedBox(height: 32),
          
          // Selected currencies section
          _buildSelectedCurrenciesSection(currencyProvider),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchAndDropdownSection(CurrencySettingsProvider currencyProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: context.tokens.accentBright,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.available_currencies ?? 'Add Currency',
                style: TextStyle(
    fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
              ),
              const Spacer(),
              if (currencyProvider.isLoadingCurrencies)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.tokens.accentBright),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search bar / Dropdown trigger
          GestureDetector(
            onTap: () {
              // Always allow opening dropdown since we show all currencies now
              _toggleDropdown();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.tokens.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDropdownOpen 
                      ? context.tokens.accentBright
                      : context.tokens.outline,
                  width: _isDropdownOpen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.tokens.accentBright,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isDropdownOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(
                              color: context.tokens.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search currencies...',
                              hintStyle: TextStyle(
                                color: context.tokens.textSecondary,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : Text(
                            'Search and select currencies...',
                            style: TextStyle(
                              color: context.tokens.textPrimary.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                  ),
                  Icon(
                    _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: context.tokens.accentBright,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Dropdown list
          if (_isDropdownOpen) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: context.tokens.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.tokens.outline,
                  width: 1,
                ),
              ),
              child: _filteredCurrencies.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          _searchController.text.isNotEmpty
                              ? 'No currencies found'
                              : 'No currencies available',
                          style: TextStyle(
                            color: context.tokens.textPrimary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        final currencyInfo = currencyProvider.getCurrencyInfo(currency);
                        final isAlreadySelected = currencyProvider.isCurrencySelected(currency);
                        
                        return _buildDropdownCurrencyItem(
                          currency: currency,
                          currencyInfo: currencyInfo,
                          isAlreadySelected: isAlreadySelected,
                          onTap: () => _selectCurrency(currency, currencyProvider),
                        );
                      },
                    ),
            ),
          ],
          
          // Info about currency validation
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.currency_validation_info,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCurrenciesSection(CurrencySettingsProvider currencyProvider) {
    final selectedCurrencies = currencyProvider.selectedCurrencies;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: context.tokens.accentBright,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.selected_currencies ?? 'Selected Currencies',
                style: TextStyle(
    fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedCurrencies.length + 1}', // +1 for sats
                style: TextStyle(
    fontSize: 14,
                  color: context.tokens.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sats (always first and can't be removed)
          _buildSelectedCurrencyItem(
            currency: 'sats',
            currencyInfo: null, // Special case for sats
            isFirst: true,
            canRemove: false,
            onRemove: null,
          ),
          
          // User selected currencies
          ...selectedCurrencies.asMap().entries.map((entry) {
            final index = entry.key;
            final currency = entry.value;
            final currencyInfo = currencyProvider.getCurrencyInfo(currency);
            return _buildSelectedCurrencyItem(
              currency: currency,
              currencyInfo: currencyInfo,
              isFirst: false,
              canRemove: true,
              onRemove: () => currencyProvider.removeCurrency(currency),
            );
          }).toList(),
          
          if (selectedCurrencies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.select_currencies_hint ?? 'Select currencies from the list above',
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownCurrencyItem({
    required String currency,
    required CurrencyInfo? currencyInfo,
    required bool isAlreadySelected,
    required VoidCallback onTap,
  }) {
    final flag = currencyInfo?.flag ?? '💰';
    final name = currencyInfo?.name ?? currency;
    final country = currencyInfo?.country ?? '';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAlreadySelected ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.tokens.inputFill,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.tokens.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Currency info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          currency,
                          style: TextStyle(
                        fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isAlreadySelected 
                                ? context.tokens.textSecondary
                                : context.tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                        fontSize: 12,
                            color: isAlreadySelected 
                                ? context.tokens.textTertiary
                                : context.tokens.textPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (country.isNotEmpty)
                      Text(
                        country,
                        style: TextStyle(
                    fontSize: 11,
                          color: isAlreadySelected 
                              ? context.tokens.textTertiary
                              : context.tokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Status indicator
              if (isAlreadySelected)
                Icon(
                  Icons.check_circle,
                  color: context.tokens.textSecondary,
                  size: 18,
                )
              else
                Icon(
                  Icons.add_circle_outline,
                  color: context.tokens.accentBright,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyListItem({
    required String currency,
    required CurrencyInfo? currencyInfo,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final flag = currencyInfo?.flag ?? '💰';
    final name = currencyInfo?.name ?? currency;
    final country = currencyInfo?.country ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? context.tokens.accentSolid.withValues(alpha: 0.2)
                  : context.tokens.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? context.tokens.accentSolid
                    : context.tokens.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Flag and selection indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? context.tokens.accentSolid.withValues(alpha: 0.3)
                        : context.tokens.outline,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? context.tokens.accentSolid
                          : context.tokens.outlineStrong,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: context.tokens.accentSolid,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: context.tokens.accentForeground,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Currency info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currency,
                            style: TextStyle(
                            fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? context.tokens.accentSolid : context.tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? context.tokens.accentSolid.withValues(alpha: 0.2)
                                  : context.tokens.outline,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              currencyInfo?.symbol ?? currency,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                    ? context.tokens.accentSolid
                                    : context.tokens.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                    fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? context.tokens.accentSolid.withValues(alpha: 0.8)
                              : context.tokens.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      if (country.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          country,
                          style: TextStyle(
                        fontSize: 12,
                            color: isSelected 
                                ? context.tokens.accentSolid.withValues(alpha: 0.6)
                                : context.tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? context.tokens.accentSolid : context.tokens.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCurrencyItem({
    required String currency,
    required CurrencyInfo? currencyInfo,
    required bool isFirst,
    required bool canRemove,
    required VoidCallback? onRemove,
  }) {
    final flag = isFirst ? '⚡' : (currencyInfo?.flag ?? '💰');
    final name = isFirst ? 'Satoshis' : (currencyInfo?.name ?? currency);
    final country = isFirst ? 'Bitcoin Lightning' : (currencyInfo?.country ?? '');
    final symbol = isFirst ? 'sats' : (currencyInfo?.symbol ?? currency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst 
            ? const Color(0xFFFFD700).withValues(alpha: 0.1)
            : context.tokens.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst 
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : context.tokens.outline,
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Flag/Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFirst 
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : context.tokens.accentSolid.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                    : context.tokens.outlineStrong,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                flag,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Currency information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currency.toUpperCase(),
                      style: TextStyle(
                fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFirst ? const Color(0xFFFFD700) : context.tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFirst 
                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                            : context.tokens.outline,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        symbol,
                        style: TextStyle(
                    fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isFirst 
                              ? const Color(0xFFFFD700)
                              : context.tokens.textPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
        fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isFirst 
                        ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                        : context.tokens.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                if (country.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    country,
                    style: TextStyle(
            fontSize: 12,
                      color: isFirst 
                          ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                          : context.tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          if (canRemove && onRemove != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                    : context.tokens.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFirst 
                      ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                      : context.tokens.outlineStrong,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.lock,
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                    : context.tokens.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }


}