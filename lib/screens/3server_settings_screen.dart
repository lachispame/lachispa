import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../providers/server_provider.dart';
import '../l10n/generated/app_localizations.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> 
    with TickerProviderStateMixin {
  late String _selectedServer;
  final _customServerController = TextEditingController();
  bool _isCustomSelected = false;
  bool _isSaving = false;

  late AnimationController _sparkController;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  late Timer _sparkTimer;

  @override
  void initState() {
    super.initState();
    _setupSparkAnimation();
    _setupSparkTimer();
    _initializeServerSelection();
  }

  void _setupSparkAnimation() {
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60 FPS
      vsync: this,
    )..repeat();
  }

  void _setupSparkTimer() {
    // Create sparks every 3 seconds exactly
    _sparkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _createRandomSpark();
    });
  }

  void _createRandomSpark() {
    if (!mounted) return;
    
    final sparkCount = _random.nextInt(3) + 2; // 2-4 sparks
    
    for (int spark = 0; spark < sparkCount; spark++) {
      final screenSize = MediaQuery.of(context).size;
      final x = _random.nextDouble() * screenSize.width;
      final y = _random.nextDouble() * screenSize.height;
      final particleCount = _random.nextInt(20) + 10; // 10-30 particles
      
      for (int i = 0; i < particleCount; i++) {
        _particles.add(Particle(x, y, _random));
      }
    }
  }

  void _initializeServerSelection() {
    final serverProvider = context.read<ServerProvider>();
    _selectedServer = serverProvider.selectedServer;
    
    // Check if the current server is not in the default list
    bool isInDefaultList = serverProvider.defaultServers.values
        .any((url) => url == _selectedServer);
    if (!isInDefaultList) {
      _isCustomSelected = true;
      _customServerController.text = _selectedServer;
    }
  }

  void _selectServer(String serverUrl) {
    setState(() {
      _selectedServer = serverUrl;
      _isCustomSelected = false;
    });
  }

  void _selectCustomServer() {
    setState(() {
      _isCustomSelected = true;
      _selectedServer = _customServerController.text;
    });
  }

  void _onCustomServerChanged(String value) {
    if (_isCustomSelected) {
      setState(() {
        _selectedServer = value;
      });
    }
  }

  Future<void> _saveServer() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    final serverProvider = context.read<ServerProvider>();
    
    String serverToSave = _isCustomSelected 
        ? _customServerController.text.trim()
        : _selectedServer;

    if (serverToSave.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.server_url_label, isError: true);
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      await serverProvider.selectServer(serverToSave);
      
      if (mounted) {
        _showMessage('${AppLocalizations.of(context)!.server_settings_title}: ${serverProvider.serverDisplayName}', isError: false);
        
        // Wait a moment for the user to see the message
        await Future.delayed(const Duration(seconds: 1));
        
        // Return to the previous screen
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.connection_error_prefix}${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF2D3FE7),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _customServerController.dispose();
    _sparkController.dispose();
    _sparkTimer.cancel();
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
            // Animated spark effects
            AnimatedBuilder(
              animation: _sparkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SparkPainter(_particles),
                  size: Size.infinite,
                );
              },
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header with back button
                  _buildHeader(),
                  
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          
                          // Title
                          Text(
                            AppLocalizations.of(context)!.server_settings_title,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            AppLocalizations.of(context)!.server_url_label,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Server list
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Predefined servers
                                  _buildDefaultServers(),
                                  const SizedBox(height: 24),
                                  
                                  // Custom server
                                  _buildCustomServerSection(),
                                ],
                              ),
                            ),
                          ),
                          
                          // Save button
                          _buildSaveButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.server_settings_title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultServers() {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        return Column(
          children: serverProvider.defaultServers.entries.map((entry) {
            final isSelected = _selectedServer == entry.value && !_isCustomSelected;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectServer(entry.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF2D3FE7)
                          : Colors.white.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 24,
                        color: isSelected 
                            ? const Color(0xFF4C63F7) 
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? Colors.white 
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: isSelected 
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomServerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCustomSelected 
            ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCustomSelected 
              ? const Color(0xFF2D3FE7)
              : Colors.white.withValues(alpha: 0.2),
          width: _isCustomSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _selectCustomServer,
            child: Row(
              children: [
                Icon(
                  _isCustomSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 24,
                  color: _isCustomSelected 
                      ? const Color(0xFF4C63F7) 
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context)!.server_url_label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isCustomSelected 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customServerController,
            onChanged: _onCustomServerChanged,
            onTap: _selectCustomServer,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.server_url_placeholder,
              hintStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2D3FE7),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.server_url_label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2D3FE7),
            Color(0xFF4C63F7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveServer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(context)!.connect_button,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  double speedX;
  double speedY;
  double life;
  final double decay;

  Particle(this.x, this.y, math.Random random) :
    size = (random.nextDouble() * 3 + 1.0), // 1-4px
    speedX = _generateOrganicVelocity(random),
    speedY = _generateOrganicVelocity(random),
    life = 100,
    decay = random.nextDouble() * 1.5 + 0.5; // 0.5-2

  static double _generateOrganicVelocity(math.Random random) {
    // More organic radial distribution
    final angle = random.nextDouble() * 2 * math.pi;
    final intensity = random.nextDouble() * 4 + 2; // 2-6 intensidad
    final direction = random.nextBool() ? 1 : -1;
    return math.cos(angle) * intensity * direction;
  }

  void update() {
    x += speedX;
    y += speedY;
    life -= decay;
    speedX *= 0.99; // Deceleration
    speedY *= 0.99;
  }

  bool get isAlive => life > 0;
  
  // Use smooth curve for fade out
  double get opacity {
    final normalizedLife = life / 100;
    // Apply easeOutQuart curve for smoothness
    return 1 - math.pow(1 - normalizedLife, 4).toDouble();
  }
}

class SparkPainter extends CustomPainter {
  final List<Particle> particles;

  SparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Update particles
    particles.removeWhere((particle) {
      particle.update();
      return !particle.isAlive;
    });

    // Get devicePixelRatio for high density screens
    final devicePixelRatio = 1.0; // Can be obtained from context if needed
    
    // Draw particles
    for (final particle in particles) {
      final alpha = particle.opacity;
      if (alpha <= 0) continue;

      final center = Offset(particle.x, particle.y);
      final scaledSize = particle.size * devicePixelRatio;
      
      // More saturated and bright colors
      const primaryColor = Color(0xFF5B73FF); // Brighter
      const secondaryColor = Color(0xFF4C63F7); // Original

      // 1. Outer glow (more subtle)
      final glowPaint2 = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 2, glowPaint2);

      // 2. Inner glow (smaller)
      final glowPaint1 = Paint()
        ..color = secondaryColor.withValues(alpha: alpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 1.5, glowPaint1);

      // 3. Main particle (solid, brighter)
      final particlePaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.9);
      
      canvas.drawCircle(center, scaledSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}