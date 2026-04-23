import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1D47),
              Color(0xFF2D3FE7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                      color: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
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
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF2D3FE7).withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Loading indicator
              if (_isInitializing) ...[
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Checking session...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
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