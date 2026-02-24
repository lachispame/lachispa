import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '3server_settings_screen.dart';
import '4login_screen.dart';
import '5signup_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _customServerController = TextEditingController();

  
  @override
  void dispose() {
    _customServerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            // Background chispa image
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/start_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
          child: Consumer<ServerProvider>(
            builder: (context, serverProvider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    const SizedBox(height: 60),
                    
                    Text(
                      'LaChispa',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            color: const Color(0xFF2D3FE7).withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.choose_option_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    _buildMainActionButtons(context),
                    
                    const SizedBox(height: 40),
                    
                    _buildServerInfo(serverProvider),
                    const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfo(ServerProvider serverProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current server display with responsive layout
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.server_settings_title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              serverProvider.serverDisplayName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Centered server change button
        GestureDetector(
          onTap: () => _showServerSettings(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4C63F7),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4C63F7).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.change_server_button,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildGradientButton(
          AppLocalizations.of(context)!.login_title,
          () => _navigateToLogin(context),
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        
        _buildGradientButton(
          AppLocalizations.of(context)!.create_account_title,
          () => _navigateToSignup(context),
          isPrimary: false,
        ),
      ],
    );
  }



  Widget _buildGradientButton(String text, VoidCallback onPressed, {required bool isPrimary}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isPrimary ? [
            const Color(0xFF2D3FE7),
            const Color(0xFF4C63F7),
          ] : [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  void _showServerSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServerSettingsScreen(),
      ),
    );
  }
}

