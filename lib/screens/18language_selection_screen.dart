import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/language_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../widgets/spark_effect.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  
  // Staggered animations following LaChispa style
  late AnimationController _staggerController;
  late AnimationController _sparkController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _footerAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Staggered animations - 2000ms total duration
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Spark effect controller
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60 FPS
      vsync: this,
    )..repeat();
    
    // Header animation (0.0-0.4)
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));
    
    // Content animation (0.3-0.7)
    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));
    
    // Footer animation (0.6-1.0)
    _footerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _staggerController.forward();
  }

  void _selectLanguage(String languageCode, LanguageProvider languageProvider) async {
    await languageProvider.changeLanguage(Locale(languageCode, ''));
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final availableLanguages = languageProvider.getAvailableLanguages();
    final currentLanguageCode = languageProvider.currentLocale.languageCode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                  // Header with back button - moved down with larger title
                  AnimatedBuilder(
                    animation: _headerAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _headerAnimation.value)),
                        child: Opacity(
                          opacity: _headerAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0), // More bottom padding
                            child: Row(
                              children: [
                                // Glassmorphism back button
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back, color: t.textPrimary, size: 24),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const Spacer(),
                                // Title - made smaller
                                Text(
                                  l10n.language_selector_title,
                                  style: TextStyle(
                                    color: t.textPrimary,
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(width: 48), // Balance for back button
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Content section
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _contentAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 40 * (1 - _contentAnimation.value)),
                          child: Opacity(
                            opacity: _contentAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Only subtitle - no duplicate title
                                  Text(
                                    l10n.language_selector_description,
                                    style: TextStyle(
                                      color: t.textPrimary.withValues(alpha: 0.9),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Languages List - Centered with selected language prominent
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: availableLanguages.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final language = entry.value;
                                        final isSelected = language['code'] == currentLanguageCode;
                                        
                                        // Make the selected language larger and more prominent
                                        final isCenter = isSelected;
                                        final containerHeight = isCenter ? 80.0 : 60.0;
                                        final flagSize = isCenter ? 36.0 : 28.0;
                                        final fontSize = isCenter ? 18.0 : 14.0;
                                        final horizontalPadding = isCenter ? 24.0 : 18.0;
                                        final verticalPadding = isCenter ? 16.0 : 12.0;
                                        final marginBottom = isCenter ? 18.0 : 10.0;
                                        
                                        return Container(
                                          height: containerHeight,
                                          margin: EdgeInsets.only(bottom: marginBottom),
                                          decoration: BoxDecoration(
                                            color: t.textPrimary.withValues(alpha: isCenter ? 0.12 : 0.06),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? t.accentSolid
                                                  : t.outline,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: isCenter ? 0.2 : 0.08),
                                                blurRadius: isCenter ? 15 : 8,
                                                offset: Offset(0, isCenter ? 6 : 3),
                                              ),
                                            ],
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () => _selectLanguage(language['code']!, languageProvider),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: horizontalPadding,
                                                vertical: verticalPadding,
                                              ),
                                              child: Row(
                                                children: [
                                                  // Flag container
                                                  Container(
                                                    width: flagSize,
                                                    height: flagSize,
                                                    decoration: BoxDecoration(
                                                      color: t.surface,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: t.outline,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        language['flag']!,
                                                        style: TextStyle(fontSize: flagSize * 0.6),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),

                                                  // Language info - in same line
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text: language['name']!,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? t.accentSolid
                                                                  : t.textPrimary.withValues(alpha: isCenter ? 1.0 : 0.8),
                                                              fontSize: fontSize,
                                                              fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text: ' ${language['code']!.toUpperCase()}',
                                                            style: TextStyle(
                                                              color: t.textSecondary,
                                                              fontSize: fontSize * 0.75,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // Selected indicator
                                                  if (isSelected)
                                                    Container(
                                                      width: isCenter ? 36 : 28,
                                                      height: isCenter ? 36 : 28,
                                                      decoration: BoxDecoration(
                                                        color: t.accentSolid,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.check,
                                                        color: t.accentForeground,
                                                        size: isCenter ? 22 : 16,
                                                      ),
                                                    )
                                                  else
                                                    Container(
                                                      width: isCenter ? 36 : 28,
                                                      height: isCenter ? 36 : 28,
                                                      decoration: BoxDecoration(
                                                        color: Colors.transparent,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: t.textPrimary.withValues(alpha: 0.3),
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  ),
                                  const SizedBox(height: 32), // Bottom padding for scroll
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}