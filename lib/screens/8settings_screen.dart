import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/server_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '3server_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _staggerController;
  late AnimationController _glowController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Staggered animation controller
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // Glow controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Specific animations
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _staggerController.forward();
  }


  @override
  void dispose() {
    _staggerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Consumer4<AuthProvider, WalletProvider, ServerProvider, LanguageProvider>(
      builder: (context, authProvider, walletProvider, serverProvider, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: t.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Animated header
                  AnimatedBuilder(
                    animation: _headerAnimation,
                    builder: (context, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(_headerAnimation),
                        child: FadeTransition(
                          opacity: _headerAnimation,
                          child: _buildHeader(t),
                        ),
                      );
                    },
                  ),

                  // Main content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _contentAnimation,
                      builder: (context, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_contentAnimation),
                          child: FadeTransition(
                            opacity: _contentAnimation,
                            child: _buildContent(authProvider, walletProvider, serverProvider, languageProvider, t),
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

  Widget _buildHeader(AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: t.outline,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: t.textPrimary,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(width: 16),

          // Title with glow
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Text(
                  AppLocalizations.of(context)!.settings_title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 20 + (10 * _glowAnimation.value),
                        color: t.accentSolid.withValues(
                          alpha: 0.3 + (0.4 * _glowAnimation.value),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthProvider authProvider, WalletProvider walletProvider, ServerProvider serverProvider, LanguageProvider languageProvider, AppTokens t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // User section
          _buildUserSection(authProvider, t),

          const SizedBox(height: 24),

          // Server section
          _buildServerSection(authProvider, serverProvider, t),

          const SizedBox(height: 24),

          // Wallet section
          _buildWalletSection(walletProvider, t),

          const SizedBox(height: 24),

          // Language section
          _buildLanguageSection(languageProvider, t),

          const SizedBox(height: 24),

          // Information section
          _buildInfoSection(t),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserSection(AuthProvider authProvider, AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.accentSolid,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: t.accentForeground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.currentUser ?? 'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.login_title,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(AuthProvider authProvider, ServerProvider serverProvider, AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                Icons.dns,
                color: t.accentSolid,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.server_settings_title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.server_settings_title,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _extractDomain(authProvider.currentServer ?? ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServerSettingsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accentSolid,
                foregroundColor: t.accentForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.server_settings_title,
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

  Widget _buildWalletSection(WalletProvider walletProvider, AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                color: t.accentBright,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.wallet_title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (walletProvider.primaryWallet != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.wallet_title,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    walletProvider.primaryWallet!.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    walletProvider.primaryWallet!.balanceFormatted,
                    style: TextStyle(
                      fontSize: 14,
                      color: t.accentBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.statusWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: t.statusWarning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: t.statusWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.wallet_title,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.statusWarning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSection(LanguageProvider languageProvider, AppTokens t) {
    return Container(
          padding: const EdgeInsets.all(24),
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
                    Icons.language,
                    color: t.accentSolid,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.language_selector_title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language selector
              _buildLanguageSelector(languageProvider, t),
            ],
          ),
        );
  }

  Widget _buildLanguageSelector(LanguageProvider languageProvider, AppTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: t.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLanguageSelector(languageProvider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  languageProvider.getCurrentLanguageFlag(),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getCurrentLanguageName(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.language_selector_description,
                        style: TextStyle(
                          fontSize: 14,
                          color: t.textPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: t.textPrimary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(LanguageProvider languageProvider) {
    final t = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer<LanguageProvider>(
        builder: (context, langProvider, child) => Container(
        decoration: BoxDecoration(
          color: t.dialogBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.textPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context)!.select_language,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
            ),

            // Language options
            ...langProvider.getAvailableLanguages().map((language) {
              final isSelected = langProvider.currentLocale.languageCode == language['code'];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await langProvider.changeLanguage(Locale(language['code']!));
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          language['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            language['name']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? t.accentSolid : t.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: t.accentSolid,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoSection(AppTokens t) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                Icons.info,
                color: t.accentSolid,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.settings_title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // About the app
          _buildSettingItem(
            t: t,
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.settings_title,
            subtitle: AppLocalizations.of(context)!.settings_title,
            onTap: () {
              _showAboutDialog();
            },
          ),

          const SizedBox(height: 16),

          // Help
          _buildSettingItem(
            t: t,
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)!.settings_title,
            subtitle: AppLocalizations.of(context)!.settings_title,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.settings_title),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required AppTokens t,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: t.accentBright,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: t.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final t = context.tokens;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLocale.languageCode;

    String subtitle;
    String description;
    String closeText;

    switch (currentLanguage) {
      case 'en':
        subtitle = 'Lightning Wallet';
        description = 'A mobile application to manage Bitcoin through Lightning Network using LNBits as backend.';
        closeText = 'Close';
        break;
      case 'pt':
        subtitle = 'Carteira Lightning';
        description = 'Uma aplicação móvel para gerir Bitcoin através da Lightning Network usando LNBits como backend.';
        closeText = 'Fechar';
        break;
      case 'de':
        subtitle = 'Lightning-Wallet';
        description = 'Eine mobile Anwendung zur Verwaltung von Bitcoin über das Lightning-Netzwerk mit LNBits als Backend.';
        closeText = 'Schließen';
        break;
      case 'fr':
        subtitle = 'Portefeuille Lightning';
        description = 'Une application mobile pour gérer Bitcoin via le réseau Lightning en utilisant LNBits comme backend.';
        closeText = 'Fermer';
        break;
      case 'it':
        subtitle = 'Portafoglio Lightning';
        description = 'Un\'applicazione mobile per gestire Bitcoin tramite Lightning Network utilizzando LNBits come backend.';
        closeText = 'Chiudi';
        break;
      case 'ru':
        subtitle = 'Lightning кошелек';
        description = 'Мобильное приложение для управления Bitcoin через Lightning Network с использованием LNBits в качестве бэкенда.';
        closeText = 'Закрыть';
        break;
      default: // es
        subtitle = 'Billetera Lightning';
        description = 'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.';
        closeText = 'Cerrar';
        break;
    }

    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: t.dialogBackground,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'Logo/chispabordesredondos.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'LaChispa',
                style: TextStyle(color: t.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: t.textPrimary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.accentSolid.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.code,
                      color: t.accentBright,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Version: 0.0.1',
                      style: TextStyle(
                        color: t.accentBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                closeText,
                style: TextStyle(color: t.accentBright),
              ),
            ),
          ],
        ),
      );
  }

  String _extractDomain(String url) {
    try {
      Uri uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url.replaceAll('https://', '').replaceAll('http://', '');
    }
  }
}
