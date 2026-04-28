import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/server_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
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
    final t = context.tokens;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: Stack(
          children: [
            _buildBoltWatermark(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildTopBar(),
                    const SizedBox(height: 28),
                    _buildHero(l, t),
                    const SizedBox(height: 14),
                    _buildTagline(l, t),
                    const Spacer(),
                    _buildCtas(l, t),
                    const SizedBox(height: 10),
                    _buildServerChangeChip(l, t),
                    const SizedBox(height: 16),
                    _buildPoweredBy(l, t),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
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
    final t = context.tokens;
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
                  color: t.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(AppLocalizations l, AppTokens t) {
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
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.1,
                letterSpacing: -0.8,
                color: t.textPrimary,
              ),
            ),
            Text(
              'LaChispa',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.8,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline(AppLocalizations l, AppTokens t) {
    return FadeTransition(
      opacity: _bodyAnim,
      child: Text(
        l.welcome_hero_tagline,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: t.textSecondary,
        ),
      ),
    );
  }

  Widget _buildServerChangeChip(AppLocalizations l, AppTokens t) {
    return FadeTransition(
      opacity: _ctaAnim,
      child: Consumer<ServerProvider>(
        builder: (context, server, _) {
          final dotColor = switch (server.serverHealth) {
            ServerHealth.healthy => t.statusHealthy,
            ServerHealth.unhealthy => t.statusUnhealthy,
            ServerHealth.checking => t.statusChecking,
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
                backgroundColor: t.surface,
                side: BorderSide(color: t.outline, width: 1),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.welcome_server_change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.settings_outlined,
                    size: 15,
                    color: t.textSecondary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCtas(AppLocalizations l, AppTokens t) {
    return FadeTransition(
      opacity: _ctaAnim,
      child: Column(
        children: [
          _primaryCta(
            t: t,
            icon: Icons.login_rounded,
            label: l.login_title,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _secondaryCta(
            t: t,
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
    required AppTokens t,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: t.accentGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: t.ctaShadow,
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
              Icon(icon, size: 18, color: t.accentForeground),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.accentForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoweredBy(AppLocalizations l, AppTokens t) {
    return FadeTransition(
      opacity: _ctaAnim,
      child: Center(
        child: InkWell(
          onTap: _openCubaBitcoin,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.welcome_powered_by,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: t.textTertiary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Opacity(
                  opacity: 0.85,
                  child: ColorFiltered(
                    colorFilter:
                        ColorFilter.mode(t.textPrimary, BlendMode.srcIn),
                    child: Image.asset(
                      'assets/images/CubaBitcoin-Hztal-BLANCO-transp.png',
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCubaBitcoin() async {
    final uri = Uri.parse('https://cubabitcoin.org');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _secondaryCta({
    required AppTokens t,
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
          side: BorderSide(color: t.outlineStrong, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: t.textPrimary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoltWatermark() {
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _heroAnim,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.55,
              heightFactor: 0.78,
              child: CustomPaint(
                painter: _BoltPainter(
                  color: const Color.fromARGB(20, 0, 0, 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  _BoltPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.23, h * 1.00)
      ..lineTo(w * 1.00, h * 0.42)
      ..lineTo(w * 0.54, h * 0.42)
      ..lineTo(w * 0.77, h * 0.00)
      ..lineTo(w * 0.00, h * 0.58)
      ..lineTo(w * 0.46, h * 0.58)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoltPainter oldDelegate) =>
      oldDelegate.color != color;
}
