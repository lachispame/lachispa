import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/server_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '6home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _hasAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasAcceptedTerms) {
      _showErrorDialog('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);

    try {
      final success = await authProvider.signup(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverUrl: serverProvider.currentServerUrl,
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta creada exitosamente! Bienvenido.'),
            backgroundColor: context.tokens.accentSolid,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to HomeScreen and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Error handled by AuthProvider
    } finally {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.errorMessage != null) {
          _showErrorDialog(authProvider.errorMessage!);
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    final t = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.dialogBackground,
        title: Text(
          'Error',
          style: TextStyle(color: t.textPrimary),
        ),
        content: Text(
          message,
          style: TextStyle(color: t.textPrimary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: t.accentSolid),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top navigation arrow
              _buildTopNavigation(t),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(t),
                      const SizedBox(height: 40),
                      _buildSignupForm(t),
                      const SizedBox(height: 20),
                      _buildTermsCheckbox(t),
                      const SizedBox(height: 20),
                      _buildServerInfo(t),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTokens t) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: t.accentSolid.withValues(alpha: _glowAnimation.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.create_account_title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                  shadows: [
                    Shadow(
                      color: t.accentSolid.withValues(alpha: _glowAnimation.value * 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Crea una nueva cuenta para acceder a tu billetera',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: t.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(AppTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.outline,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUsernameField(t),
            const SizedBox(height: 20),
            _buildPasswordField(t),
            const SizedBox(height: 20),
            _buildConfirmPasswordField(t),
            const SizedBox(height: 32),
            _buildSignupButton(t),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(AppTokens t) {
    return TextFormField(
      controller: _usernameController,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre de usuario es requerido';
        }
        if (value.trim().length < 3) {
          return 'El nombre de usuario debe tener al menos 3 caracteres';
        }
        if (value.trim().length > 20) {
          return 'El nombre de usuario no puede tener más de 20 caracteres';
        }
        // Only letters, numbers and some special characters
        final validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
        if (!validPattern.hasMatch(value.trim())) {
          return 'Solo se permiten letras, números, _, . y -';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.signup_username_label,
        hintText: AppLocalizations.of(context)!.signup_username_placeholder,
        labelStyle: TextStyle(color: t.textPrimary.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: t.textSecondary),
        prefixIcon: Icon(Icons.person, color: t.textPrimary.withValues(alpha: 0.7)),
        filled: true,
        fillColor: t.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.accentSolid),
        ),
      ),
      style: TextStyle(color: t.textPrimary),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField(AppTokens t) {
    return TextFormField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La contraseña es requerida';
        }
        if (value.length < 8) {
          return 'La contraseña debe tener al menos 8 caracteres';
        }
        if (value.length > 50) {
          return 'La contraseña no puede tener más de 50 caracteres';
        }
        // At least one number
        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'La contraseña debe contener al menos un número';
        }
        // At least one letter
        if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
          return 'La contraseña debe contener al menos una letra';
        }
        return null;
      },
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.signup_password_label,
        hintText: AppLocalizations.of(context)!.signup_password_placeholder,
        labelStyle: TextStyle(color: t.textPrimary.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: t.textSecondary),
        prefixIcon: Icon(Icons.lock, color: t.textPrimary.withValues(alpha: 0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: t.textPrimary.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: t.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.accentSolid),
        ),
      ),
      style: TextStyle(color: t.textPrimary),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildConfirmPasswordField(AppTokens t) {
    return TextFormField(
      controller: _confirmPasswordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirma tu contraseña';
        }
        if (value != _passwordController.text) {
          return AppLocalizations.of(context)!.passwords_mismatch_error;
        }
        return null;
      },
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirm_password_label,
        hintText: AppLocalizations.of(context)!.confirm_password_placeholder,
        labelStyle: TextStyle(color: t.textPrimary.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: t.textSecondary),
        prefixIcon: Icon(Icons.lock_outline, color: t.textPrimary.withValues(alpha: 0.7)),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: t.textPrimary.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: t.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.accentSolid),
        ),
      ),
      style: TextStyle(color: t.textPrimary),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignup(),
    );
  }

  Widget _buildSignupButton(AppTokens t) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: t.accentGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || authProvider.isLoading) ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (_isLoading || authProvider.isLoading)
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(t.accentForeground),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.create_account_button,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.accentForeground,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox(AppTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return t.accentSolid;
                  }
                  return Colors.transparent;
                }),
                checkColor: WidgetStateProperty.all(t.accentForeground),
                side: BorderSide(color: t.textPrimary.withValues(alpha: 0.3)),
              ),
            ),
            child: Checkbox(
              value: _hasAcceptedTerms,
              onChanged: (value) {
                setState(() {
                  _hasAcceptedTerms = value ?? false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'He anotado mi contraseña en un lugar seguro',
              style: TextStyle(
                fontSize: 14,
                color: t.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildServerInfo(AppTokens t) {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: t.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns,
                size: 16,
                color: t.textPrimary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Servidor: ',
                style: TextStyle(
                  fontSize: 14,
                  color: t.textPrimary.withValues(alpha: 0.7),
                ),
              ),
              Text(
                serverProvider.serverDisplayName,
                style: TextStyle(
                  fontSize: 14,
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopNavigation(AppTokens t) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: t.outline,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios,
                color: t.textPrimary,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
