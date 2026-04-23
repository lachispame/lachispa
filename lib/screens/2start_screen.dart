import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '3server_settings_screen.dart';
import '4login_screen.dart';
import '5signup_screen.dart';
import '18language_selection_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final Animation<double> _heroAnim;
  late final Animation<double> _bodyAnim;
  late final Animation<double> _ctaAnim;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _heroAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _bodyAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
    );
    _ctaAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );
    _staggerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().checkHealth();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildTopBar(),
                const SizedBox(height: 28),
                _buildHero(l),
                const SizedBox(height: 14),
                _buildTagline(l),
                const Spacer(),
                _buildCtas(l),
                const SizedBox(height: 10),
                _buildServerChangeChip(l),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _heroAnim,
      child: Row(
        children: [
          const Spacer(),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LanguageSelectionScreen(),
            ),
          ),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.getCurrentLanguageFlag(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(AppLocalizations l) {
    return FadeTransition(
      opacity: _heroAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_heroAnim),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.welcome_hero_prefix,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
            const Text(
              'LaChispa',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline(AppLocalizations l) {
    return FadeTransition(
      opacity: _bodyAnim,
      child: Text(
        l.welcome_hero_tagline,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _buildServerChangeChip(AppLocalizations l) {
    return FadeTransition(
      opacity: _ctaAnim,
      child: Consumer<ServerProvider>(
        builder: (context, server, _) {
          final dotColor = switch (server.serverHealth) {
            ServerHealth.healthy => const Color(0xFF4ADE80),
            ServerHealth.unhealthy => const Color(0xFFEF4444),
            ServerHealth.checking => Colors.white.withValues(alpha: 0.25),
          };
          return SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {
                final provider = context.read<ServerProvider>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServerSettingsScreen(),
                  ),
                ).then((_) {
                  if (mounted) provider.checkHealth();
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      server.serverDisplayName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.welcome_server_change,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.settings_outlined,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCtas(AppLocalizations l) {
    return FadeTransition(
      opacity: _ctaAnim,
      child: Column(
        children: [
          _primaryCta(
            icon: Icons.login_rounded,
            label: l.login_title,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _secondaryCta(
            icon: Icons.person_add_alt_1_rounded,
            label: l.create_account_title,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2D3FE7), Color(0xFF4C63F7)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryCta({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
