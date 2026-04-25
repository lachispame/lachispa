import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '7ln_address_screen.dart';
import '16currency_settings_screen.dart';
import '18language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(t),

              // Settings list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Lightning Address
                    _buildSettingsItem(
                      t: t,
                      icon: Icons.alternate_email,
                      iconColor: t.accentSolid,
                      title: AppLocalizations.of(context)!.lightning_address_title,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LNAddressScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Currency Settings
                    Consumer<CurrencySettingsProvider>(
                      builder: (context, currencyProvider, child) {
                        return _buildSettingsItem(
                          t: t,
                          icon: Icons.attach_money,
                          iconColor: t.accentSolid,
                          title: AppLocalizations.of(context)!.currency_settings_title,
                          subtitle: '${currencyProvider.availableCurrencies.length} currencies',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CurrencySettingsScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Language Settings
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return _buildSettingsItem(
                          t: t,
                          icon: Icons.language,
                          iconColor: t.accentSolid,
                          title: AppLocalizations.of(context)!.language_selector_title,
                          subtitle: languageProvider.getCurrentLanguageName(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageSelectionScreen(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Theme Settings
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildSettingsItem(
                          t: t,
                          icon: _themeIcon(themeProvider.current),
                          iconColor: t.accentSolid,
                          title: AppLocalizations.of(context)!.theme_selector_title,
                          subtitle: _themeLabel(context, themeProvider.current),
                          onTap: () => _showThemeSelector(themeProvider),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.outline, width: 1),
              ),
              child: Icon(
                Icons.arrow_back,
                color: t.textPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.settings_screen_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required AppTokens t,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.lachispa:
        return Icons.bolt;
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
    }
  }

  String _themeLabel(BuildContext context, AppTheme theme) {
    final l = AppLocalizations.of(context)!;
    switch (theme) {
      case AppTheme.lachispa:
        return l.theme_lachispa;
      case AppTheme.light:
        return l.theme_light;
      case AppTheme.dark:
        return l.theme_dark;
    }
  }

  void _showThemeSelector(ThemeProvider themeProvider) {
    final t = context.tokens;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer<ThemeProvider>(
        builder: (context, provider, _) => Container(
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
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textPrimary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  AppLocalizations.of(context)!.select_theme,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
              ),
              ...AppTheme.values.map((option) {
                final isSelected = provider.current == option;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await provider.changeTheme(option);
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _themeIcon(option),
                            color: isSelected ? t.accentSolid : t.textPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _themeLabel(context, option),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? t.accentSolid
                                    : t.textPrimary,
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
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}
