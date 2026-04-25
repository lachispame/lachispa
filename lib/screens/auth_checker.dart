import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_tokens.dart';
import '2start_screen.dart';
import '6home_screen.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      print('[AUTH_CHECKER] Starting authentication check...');
      final authProvider = context.read<AuthProvider>();
      
      // Initialize auth provider (this will check for existing session)
      await authProvider.initialize();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        print('[AUTH_CHECKER] Auth check completed. Is logged in: ${authProvider.isLoggedIn}');
        
        // Navigate based on auth status
        if (authProvider.isLoggedIn) {
          print('[AUTH_CHECKER] User is logged in, navigating to HomeScreen');
          _navigateToHome();
        } else {
          print('[AUTH_CHECKER] User not logged in, navigating to StartScreen');
          _navigateToStart();
        }
      }
    } catch (e) {
      print('[AUTH_CHECKER] Error during authentication check: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _navigateToStart();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  void _navigateToStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const StartScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: t.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: t.accentSolid.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/chispabordesredondos.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 32),

              // App name
              Text(
                'LaChispa',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                  shadows: [
                    Shadow(
                      color: t.accentSolid.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loading indicator
              if (_isInitializing) ...[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(t.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Checking session...',
                  style: TextStyle(
                    fontSize: 16,
                    color: t.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}