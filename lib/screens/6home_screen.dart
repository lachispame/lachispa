import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/language_provider.dart';
import '../services/transaction_detector.dart';
import '../providers/currency_settings_provider.dart';
import '../services/app_info_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '7history_screen.dart';
import '7ln_address_screen.dart';
import '9receive_screen.dart';
import '10send_screen.dart';
import '14fixed_float_screen.dart';
import '15boltz_screen.dart';
import '16currency_settings_screen.dart';
import '17settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _walletsInitialized = false;
  bool _balanceVisible = true;
  bool _isInHistory = false;
  
  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;
  
  // Currency toggle with new system
  int _currentCurrencyIndex = 0;
  
  // Currency conversion state management
  final Map<String, String> _conversionResults = {};
  final Set<String> _activeConversions = {};
  final Map<String, Future<String>?> _conversionFutures = {};
  
  // Transaction detector
  final TransactionDetector _transactionDetector = TransactionDetector();
  late StreamSubscription _sparkSubscription;
  
  // Staggered animations
  late AnimationController _staggerController;
  late AnimationController _flashController;
  late AnimationController _glowController;
  late AnimationController _sparkController;
  late AnimationController _celebrationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _userInfoAnimation;
  late Animation<double> _balanceAnimation;
  late Animation<double> _buttonsAnimation;
  late Animation<double> _bottomNavAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _celebrationAnimation;
  
  // Spark effects system
  bool _showDepositSpark = false;
  late Timer _sparkTimer;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  
  // Interactive states
  bool _sendButtonPressed = false;
  bool _receiveButtonPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _setupAnimations();
    _startAnimations();
    _setupSparkTimer();
    
    // Initialize after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWallets();
      _startAutoRefresh(); // Only starts when HomeScreen is active
      _initializeSparkEffect();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reactivate auto-refresh when returning to HomeScreen
    if (mounted) {
      _startAutoRefresh();
    }
  }

  @override
  void deactivate() {
    // Pause auto-refresh when navigating away from HomeScreen
    _stopAutoRefresh();
    super.deactivate();
  }
  
  void _setupAnimations() {
    // Staggered animation controller - 1600ms duration
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    
    // Spark animation controller - 60 FPS (16ms)
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..repeat();
    
    // Flash controller for currency change
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Glow animation controller - 2000ms with reverse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Celebration animation controller - 600ms
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Header animation - Interval 0.0-0.2
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic),
    ));
    
    // User info animation - Interval 0.125-0.325 (200ms delay)
    _userInfoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.125, 0.325, curve: Curves.easeOutCubic),
    ));
    
    // Balance animation - Interval 0.25-0.45 (400ms delay)
    _balanceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.25, 0.45, curve: Curves.easeOutCubic),
    ));
    
    // Buttons animation - Interval 0.375-0.575 (600ms delay)
    _buttonsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.375, 0.575, curve: Curves.easeOutCubic),
    ));
    
    // Bottom nav animation - Interval 0.5-0.7 (800ms delay)
    _bottomNavAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOutCubic),
    ));
    
    // Flash animation for currency change
    _flashAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
    
    // Glow animation for title with variable blur 20-30px
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Celebration animation for balance card
    _celebrationAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOut,
    ));
  }
  
  void _startAnimations() {
    _staggerController.forward();
  }
  
  void _setupSparkTimer() {
    // Timer to update particles at 60 FPS (16.67ms) - only for deposits
    _sparkTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _updateParticles();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _staggerController.dispose();
    _flashController.dispose();
    _glowController.dispose();
    _sparkController.dispose();
    _celebrationController.dispose();
    _sparkTimer.cancel();
    _sparkSubscription.cancel();
    _particles.clear(); // Memory leak prevention
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle auto-refresh according to app state
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
    }
  }

  // Initialize user wallets (optimized)
  void _initializeWallets() {
    if (_walletsInitialized) return;
    
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    
    if (authProvider.isLoggedIn && !walletProvider.isInitialized) {
      print('[HOME_SCREEN] Initializing wallets...');
      _walletsInitialized = true;
      
      // Initialize wallets immediately without waiting
      walletProvider.initializeWallets(
        serverUrl: authProvider.currentServer ?? '',
        authToken: authProvider.sessionData?.token ?? '',
      ).catchError((error) {
        print('[HOME_SCREEN] Error initializing wallets: $error');
        // Retry in 2 seconds if it fails
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !walletProvider.isInitialized) {
            _walletsInitialized = false;
            _initializeWallets();
          }
        });
      });
    }
  }

  // Auto-refresh every 5 seconds ONLY when HomeScreen is active
  // Automatically pauses when user navigates to other screens
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshBalance(showFeedback: false);
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }


  void _toggleBalanceVisibility() {
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
  }

  // Refresh with visual feedback and deposit detection
  void _refreshBalance({bool showFeedback = false}) {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    
    if (!authProvider.isLoggedIn || _isRefreshing) return;
    
    if (showFeedback) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    final previousBalance = walletProvider.primaryBalance;
    
    walletProvider.refreshPrimaryBalance(
      serverUrl: authProvider.currentServer ?? '',
    ).then((_) {
      // Check if there's a new deposit
      final newBalance = walletProvider.primaryBalance;
      if (newBalance > previousBalance) {
        final difference = newBalance - previousBalance;
        print('[HOME_SCREEN] New deposit detected! +$difference sats');
        
        // Activate celebration effects
        createDepositSpark();
        depositCelebration();
        
        // Notify transaction detector
        _transactionDetector.triggerDepositSpark(difference);
        
        // Visual feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  // White content on saturated status background; not a themable surface.
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${AppLocalizations.of(context)!.received_label}! +$difference sats'),
                ],
              ),
              backgroundColor: context.tokens.statusHealthy.withValues(alpha: 0.9),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      if (showFeedback && mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }).catchError((error) {
      print('[HOME_SCREEN] Error refrescando balance: $error');
      if (showFeedback && mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }


  // Cyclic denomination toggle with animation using new system
  void _toggleCurrency() {
    final currencyProvider = context.read<CurrencySettingsProvider>();
    final displaySequence = currencyProvider.displaySequence;
    
    if (displaySequence.isEmpty) {
      // No currencies available (server failed) - stay in sats
      print('[HOME_SCREEN] No currencies available, staying in sats mode');
      return;
    }
    
    if (displaySequence.length == 1) {
      // Only sats available - no toggle needed
      print('[HOME_SCREEN] Only sats available, no toggle needed');
      return;
    }
    
    _flashController.forward().then((_) {
      setState(() {
        _currentCurrencyIndex = (_currentCurrencyIndex + 1) % displaySequence.length;
        // Clear conversion cache when currency changes
        _conversionResults.clear();
        _activeConversions.clear();
        _conversionFutures.clear();
      });
      _flashController.reverse();
      
      print('[HOME_SCREEN] Toggled to currency: ${displaySequence[_currentCurrencyIndex]}');
    });
  }

  // Format main balance according to selected currency using new system
  String _formatMainBalanceSync(int balanceSats, CurrencySettingsProvider currencyProvider) {
    final displaySequence = currencyProvider.displaySequence;
    
    if (displaySequence.isEmpty) {
      // Server failed - show only sats
      return _balanceVisible ? '$balanceSats sats' : '••• sats';
    }
    
    final currency = displaySequence[_currentCurrencyIndex];
    
    if (!_balanceVisible) {
      return currency == 'sats' ? '••• sats' : '••• $currency';
    }
    
    if (currency == 'sats') {
      return '$balanceSats sats';
    }
    
    // For fiat currencies, we'll use FutureBuilder in the UI
    // This function is just for the loading state
    return AppLocalizations.of(context)!.calculating_text ?? 'Loading...';
  }

  // Format secondary balance (sats) to show below when not in sats using new system
  String? _formatSecondaryBalance(int balanceSats, CurrencySettingsProvider currencyProvider) {
    if (!_balanceVisible) return null;
    
    final displaySequence = currencyProvider.displaySequence;
    if (displaySequence.isEmpty) return null;
    
    final currency = displaySequence[_currentCurrencyIndex];
    
    // Only show sats below when we're in another currency
    if (currency == 'sats') {
      return null;
    }
    
    return '$balanceSats sats';
  }

  /// Determines balance font size based on selected currency using new system
  double _getBalanceFontSize(bool isMobile, CurrencySettingsProvider currencyProvider) {
    final displaySequence = currencyProvider.displaySequence;
    if (displaySequence.isEmpty) {
      return isMobile ? 36 : 42; // Default to sats size
    }
    
    final currency = displaySequence[_currentCurrencyIndex];
    
    // For sats, use normal size
    if (currency == 'sats') {
      return isMobile ? 36 : 42;
    }
    
    // For fiat currencies, use smaller size
    return isMobile ? 28 : 34;
  }

  /// Build balance display widget (main + optional secondary balance)
  Widget _buildBalanceDisplay(String mainBalance, String? secondaryBalance, bool isMobile, CurrencySettingsProvider currencyProvider) {
    return Column(
      key: ValueKey('${_currentCurrencyIndex}_${DateTime.now().millisecondsSinceEpoch}'),
      children: [
        // Main balance
        Text(
          mainBalance,
          textAlign: TextAlign.center,
          style: TextStyle(
                        fontSize: _getBalanceFontSize(isMobile, currencyProvider),
            fontWeight: FontWeight.bold,
            color: context.tokens.textPrimary,
          ),
        ),
        // Secondary balance (sats) when not in sats mode
        if (secondaryBalance != null) ...[
          const SizedBox(height: 4),
          Text(
            secondaryBalance,
            textAlign: TextAlign.center,
            style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: context.tokens.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }


  // Initialize spark effects system
  void _initializeSparkEffect() {
    _sparkSubscription = _transactionDetector.sparkTriggerStream.listen((shouldTrigger) {
      if (shouldTrigger && mounted) {
        print('[HOME_SCREEN] Transaction event detected!');
        createDepositSpark();
      }
    });
  }

  void _showTransactionHistory(BuildContext context) {
    setState(() {
      _isInHistory = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    ).then((_) {
      // Reset state when returning from history
      if (mounted) {
        setState(() {
          _isInHistory = false;
        });
      }
    });
  }

  void _openWalletSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildWalletSelectorSheet(),
    );
  }

  void _goToSend(BuildContext context) {
    // Loading state with visual feedback
    setState(() => _sendButtonPressed = true);
    
    // Actual navigation to send screen
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _sendButtonPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SendScreen(),
          ),
        );
      }
    });
  }

  void _goToReceive(BuildContext context) {
    // Loading state with visual feedback
    setState(() => _receiveButtonPressed = true);
    
    // Actual navigation to receive screen
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _receiveButtonPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReceiveScreen(),
          ),
        );
      }
    });
  }


  
  // Create celebration sparks for deposits
  void createDepositSpark() {
    if (!mounted) return;
    
    print('[HOME_SCREEN] Activating deposit spark!');
    
    // Create 5-10 simultaneous sparks
    final sparkCount = _random.nextInt(6) + 5; // 5-10 chispas
    
    for (int spark = 0; spark < sparkCount; spark++) {
      final screenSize = MediaQuery.of(context).size;
      final x = _random.nextDouble() * screenSize.width;
      final y = _random.nextDouble() * screenSize.height;
      final particleCount = _random.nextInt(31) + 20; // 20-50 particles per spark
      
      for (int i = 0; i < particleCount; i++) {
        _particles.add(Particle(x, y, _random));
      }
    }
    
    setState(() {
      _showDepositSpark = true;
    });
    
    // Activate deposit celebration
    depositCelebration();
    
    // Auto-hide after 3 seconds with automatic cleanup
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showDepositSpark = false;
        });
        _particles.clear(); // Remove dead particles
      }
    });
  }
  
  // Celebration animation for deposits
  void depositCelebration() {
    if (!mounted) return;
    
    // Balance card scale animation: 1.0 → 1.05 → 1.0
    _celebrationController.reset();
    _celebrationController.forward().then((_) {
      if (mounted) {
        _celebrationController.reverse();
      }
    });
  }
  
  void _updateParticles() {
    if (!mounted) return;
    
    setState(() {
      // Remove dead particles automatically (optimization)
      _particles.removeWhere((particle) {
        particle.update();
        return !particle.isAlive;
      });
    });
  }
  
  // Method for manual testing
  void _triggerTestSpark() {
    createDepositSpark();
  }

  /// Get stable future for currency conversion
  Future<String> _getStableConversionFuture(
    int sats,
    String currency,
    CurrencySettingsProvider currencyProvider,
    AuthProvider authProvider,
  ) {
    final key = '${sats}_$currency';
    
    // Return existing future if available
    if (_conversionFutures[key] != null) {
      return _conversionFutures[key]!;
    }
    
    // Create new future and cache it
    final future = _performConversion(sats, currency, currencyProvider, authProvider);
    _conversionFutures[key] = future;
    return future;
  }

  /// Perform the actual conversion using CurrencyProvider
  Future<String> _performConversion(
    int sats, 
    String currency, 
    CurrencySettingsProvider currencyProvider,
    AuthProvider authProvider,
  ) async {
    final key = '${sats}_$currency';
    
    // Return cached result if available
    if (_conversionResults.containsKey(key)) {
      print('[HOME_SCREEN] Using cached result for $currency: ${_conversionResults[key]}');
      return _conversionResults[key]!;
    }
    
    // Prevent multiple concurrent calls for same conversion
    if (_activeConversions.contains(key)) {
      print('[HOME_SCREEN] Conversion already in progress for $currency');
      // Wait a bit for the active conversion to complete
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_conversionResults.containsKey(key)) {
          return _conversionResults[key]!;
        }
      }
      return '--';
    }
    
    _activeConversions.add(key);
    
    try {
      print('[HOME_SCREEN] Starting conversion: $sats sats to $currency');
      
      // Use the proper CurrencySettingsProvider method that handles all API logic
      final result = await currencyProvider.convertSatsToFiat(sats, currency)
          .timeout(
        const Duration(seconds: 10), // Reasonable timeout for API calls
        onTimeout: () {
          print('[HOME_SCREEN] Provider conversion timeout for $currency');
          return '--';
        },
      );
      
      _conversionResults[key] = result;
      print('[HOME_SCREEN] Conversion completed for $currency: $result');
      return result;
      
    } catch (e) {
      print('[HOME_SCREEN] Conversion failed for $currency: $e');
      _conversionResults[key] = '--';
      return '--';
    } finally {
      _activeConversions.remove(key);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    // Determine if it's mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer3<AuthProvider, WalletProvider, CurrencySettingsProvider>(
      builder: (context, authProvider, walletProvider, currencyProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: context.tokens.backgroundGradient),
            child: Column(
              children: [
                // Main content
                Expanded(
                  child: Stack(
                    children: [
                      SafeArea(
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
                                    child: _buildHeader(context),
                                  ),
                                );
                              },
                            ),
                            
                            // Animated user information
                            AnimatedBuilder(
                              animation: _userInfoAnimation,
                              builder: (context, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(_userInfoAnimation),
                                  child: FadeTransition(
                                    opacity: _userInfoAnimation,
                                    child: _buildUserInfo(),
                                  ),
                                );
                              },
                            ),
                            
                            // Main content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    const Spacer(flex: 2),
                                    
                                    // Animated balance card
                                    AnimatedBuilder(
                                      animation: _balanceAnimation,
                                      builder: (context, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.3),
                                            end: Offset.zero,
                                          ).animate(_balanceAnimation),
                                          child: FadeTransition(
                                            opacity: _balanceAnimation,
                                            child: _buildBalanceCard(context, isMobile),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Animated action buttons
                                    AnimatedBuilder(
                                      animation: _buttonsAnimation,
                                      builder: (context, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.3),
                                            end: Offset.zero,
                                          ).animate(_buttonsAnimation),
                                          child: FadeTransition(
                                            opacity: _buttonsAnimation,
                                            child: _buildActionButtons(context, isMobile),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    const Spacer(flex: 2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          
                      // Particle system with z-index 100 (overlay)
                      if (_showDepositSpark)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _sparkController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: SparkPainter(_particles),
                                  size: Size.infinite,
                                  willChange: true, // Optimization for animations
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              
                // Fixed history button at the bottom
                SafeArea(
                  top: false,
                  child: AnimatedBuilder(
                    animation: _bottomNavAnimation,
                    builder: (context, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_bottomNavAnimation),
                        child: FadeTransition(
                          opacity: _bottomNavAnimation,
                          child: _buildHistoryButton(context),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Navigation drawer
          drawer: _buildDrawer(context, authProvider, walletProvider),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          // Menu button with glassmorphism
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.tokens.outline,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: context.tokens.textPrimary,
                size: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          
          const Spacer(),
          
          // 'LaChispa' title with animated glow (20-30px variable blur)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'LaChispa',
                  style: TextStyle(
                                        fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 0),
                      blurRadius: 20 + (10 * _glowAnimation.value), // 20-30px blur
                      color: context.tokens.accentSolid.withValues(
                        alpha: 0.3 + (0.4 * _glowAnimation.value), // More intensity
                      ),
                    ),
                    Shadow(
                      offset: const Offset(0, 0),
                      blurRadius: 10 + (5 * _glowAnimation.value), // Glow adicional
                      color: context.tokens.accentSolid.withValues(
                        alpha: 0.2 + (0.3 * _glowAnimation.value),
                      ),
                    ),
                  ],
                ),
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Test spark button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.tokens.outline,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.auto_awesome,
                color: context.tokens.statusWarning,
                size: 24,
              ),
              onPressed: _triggerTestSpark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserInfo() {
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (context, authProvider, walletProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (walletProvider.primaryWallet != null) ...[
                GestureDetector(
                  onTap: () => _openWalletSelector(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.tokens.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: context.tokens.textPrimary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          walletProvider.primaryWallet!.name,
                          style: TextStyle(
                                                        fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: context.tokens.textPrimary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (walletProvider.isLoading) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(context.tokens.textPrimary.withValues(alpha: 0.7)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.loading_text,
                      style: TextStyle(
                                                fontSize: 12,
                        color: context.tokens.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
  
  Widget _buildBalanceCard(BuildContext context, bool isMobile) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedBuilder(
          animation: _celebrationAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _celebrationAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.tokens.outline,
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
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.balance_label,
                      style: TextStyle(
                                                fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.tokens.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _flashAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _isRefreshing ? 0.5 : _flashAnimation.value,
                                child: GestureDetector(
                                  onTap: _toggleCurrency,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Consumer2<WalletProvider, CurrencySettingsProvider>(
                                      builder: (context, walletProvider, currencyProvider, child) {
                                        final balance = walletProvider.primaryBalance;
                                        final displaySequence = currencyProvider.displaySequence;
                                        
                                        // Show balance with new system
                                        if (walletProvider.primaryWallet == null) {
                                          final mainBalance = walletProvider.isLoading
                                              ? (AppLocalizations.of(context)!.loading_text ?? 'Loading...')
                                              : '0 sats';
                                          return _buildBalanceDisplay(mainBalance, null, isMobile, currencyProvider);
                                        }
                                        
                                        // Server failed or no currencies - show only sats
                                        if (displaySequence.isEmpty) {
                                          final mainBalance = _balanceVisible ? '$balance sats' : '••• sats';
                                          return _buildBalanceDisplay(mainBalance, null, isMobile, currencyProvider);
                                        }
                                        
                                        final currency = displaySequence[_currentCurrencyIndex];
                                        
                                        // Sats mode
                                        if (currency == 'sats') {
                                          final mainBalance = _balanceVisible ? '$balance sats' : '••• sats';
                                          return _buildBalanceDisplay(mainBalance, null, isMobile, currencyProvider);
                                        }
                                        
                                        // Fiat mode - use FutureBuilder for conversion with stable future
                                        return FutureBuilder<String>(
                                          future: _getStableConversionFuture(balance, currency, currencyProvider, context.read<AuthProvider>()),
                                          builder: (context, snapshot) {
                                            String mainBalance;
                                            
                                            if (!_balanceVisible) {
                                              mainBalance = '••• $currency';
                                            } else if (snapshot.connectionState == ConnectionState.waiting) {
                                              // Still loading
                                              mainBalance = AppLocalizations.of(context)!.calculating_text ?? 'Calculando...';
                                            } else if (snapshot.hasError) {
                                              // Show error message instead of resetting
                                              print('[HOME_SCREEN] Currency conversion error for $currency: ${snapshot.error}');
                                              mainBalance = _balanceVisible ? 'Error $currency' : '••• $currency';
                                            } else if (snapshot.hasData) {
                                              final value = snapshot.data!;
                                              if (value == '--') {
                                                // Show error message instead of resetting
                                                print('[HOME_SCREEN] Currency conversion failed for $currency');
                                                mainBalance = _balanceVisible ? 'Error $currency' : '••• $currency';
                                              } else {
                                                // Successful conversion - use currency code format
                                                mainBalance = '$currency $value';
                                              }
                                            } else {
                                              // Fallback case
                                              print('[HOME_SCREEN] FutureBuilder in unexpected state for $currency');
                                              mainBalance = _balanceVisible ? '$balance sats' : '••• sats';
                                            }
                                            
                                            final secondaryBalance = _formatSecondaryBalance(balance, currencyProvider);
                                            return _buildBalanceDisplay(mainBalance, secondaryBalance, isMobile, currencyProvider);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Balance visibility toggle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: context.tokens.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _balanceVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                key: ValueKey(_balanceVisible),
                                color: context.tokens.textSecondary,
                                size: 24,
                              ),
                            ),
                            onPressed: _toggleBalanceVisibility,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Row(
          children: [
            // Send button with interactive states
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                transform: Matrix4.identity()
                  ..scale(_sendButtonPressed ? 0.95 : 1.0),
                decoration: BoxDecoration(
                  gradient: context.tokens.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.tokens.accentSolid.withValues(
                        alpha: _sendButtonPressed ? 0.5 : 0.3,
                      ),
                      blurRadius: _sendButtonPressed ? 8 : 12,
                      offset: Offset(0, _sendButtonPressed ? 3 : 6),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _sendButtonPressed = true),
                  onTapUp: (_) => setState(() => _sendButtonPressed = false),
                  onTapCancel: () => setState(() => _sendButtonPressed = false),
                  onTap: () => _goToSend(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.send_button,
                          style: TextStyle(
                                                        fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.north_east,
                          color: context.tokens.textPrimary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Receive button with interactive states
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                transform: Matrix4.identity()
                  ..scale(_receiveButtonPressed ? 0.95 : 1.0),
                decoration: BoxDecoration(
                  color: context.tokens.textPrimary.withValues(
                    alpha: _receiveButtonPressed ? 0.12 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.tokens.textPrimary.withValues(
                      alpha: _receiveButtonPressed ? 0.2 : 0.1,
                    ),
                    width: 1,
                  ),
                  boxShadow: _receiveButtonPressed ? [
                    BoxShadow(
                      color: context.tokens.outline,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ] : [],
                ),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _receiveButtonPressed = true),
                  onTapUp: (_) => setState(() => _receiveButtonPressed = false),
                  onTapCancel: () => setState(() => _receiveButtonPressed = false),
                  onTap: () => _goToReceive(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.south_east,
                          color: context.tokens.textPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.receive_button,
                          style: TextStyle(
                                                        fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
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
  
  Widget _buildWalletSelectorSheet() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F1419),
                Color(0xFF1A1D47),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: context.tokens.textPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.wallet_title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Wallets List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final isSelected = walletProvider.primaryWallet?.id == wallet.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? context.tokens.accentSolid.withValues(alpha: 0.3)
                            : context.tokens.inputFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? context.tokens.accentSolid
                              : context.tokens.outline,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? context.tokens.accentSolid.withValues(alpha: 0.3)
                                : context.tokens.outline,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: isSelected ? context.tokens.accentBright : context.tokens.textPrimary.withValues(alpha: 0.7),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          wallet.name,
                          style: TextStyle(
                            color: context.tokens.textPrimary,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          wallet.balanceFormatted,
                          style: TextStyle(
                            color: isSelected ? context.tokens.accentBright : context.tokens.textPrimary.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: context.tokens.accentBright,
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          walletProvider.setPrimaryWallet(wallet);
                          Navigator.pop(context);
                          
                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${AppLocalizations.of(context)!.wallet_title} "${wallet.name}" seleccionada'),
                              backgroundColor: context.tokens.accentSolid,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Info Section
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.tokens.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.tokens.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.tokens.accentBright,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.create_new_wallet_title,
                          style: TextStyle(
                            color: context.tokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.create_wallet_short_description,
                      style: TextStyle(
                        color: context.tokens.textPrimary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showWalletCreationInfo();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.tokens.accentSolid,
                          foregroundColor: context.tokens.accentForeground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.server_settings_title,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWalletCreationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.dialogBackground,
        title: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: context.tokens.accentBright,
            ),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.create_new_wallet_title,
              style: TextStyle(color: context.tokens.textPrimary),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.create_wallet_detailed_instructions,
          style: TextStyle(
            color: context.tokens.textPrimary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel_button,
              style: TextStyle(color: context.tokens.accentBright),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24), // Margin according to style guide
      child: Container(
        height: 56, // Standard button height
        decoration: BoxDecoration(
          color: context.tokens.surface, // Glassmorphism
          borderRadius: BorderRadius.circular(16), // Standard border radius
          border: Border.all(
            color: context.tokens.outline,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTransactionHistory(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: _isInHistory ? context.tokens.accentBright : context.tokens.textPrimary,
                  size: 20, // Icon size according to guide
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.history_title,
                  style: TextStyle(
                                        fontSize: 16,
                    fontWeight: FontWeight.w500, // Weight for secondary buttons
                    color: _isInHistory ? context.tokens.accentBright : context.tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, WalletProvider walletProvider) {
    return Drawer(
      backgroundColor: context.tokens.dialogBackground,
      child: Container(
        decoration: BoxDecoration(gradient: context.tokens.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and username
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.tokens.accentSolid,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person,
                            color: context.tokens.textPrimary,
                            size: 28,
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
                                  color: context.tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _extractDomain(authProvider.currentServer ?? ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.tokens.textPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Current wallet information
                    if (walletProvider.primaryWallet != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.tokens.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.tokens.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: context.tokens.accentBright,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    walletProvider.primaryWallet!.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: context.tokens.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    walletProvider.primaryWallet!.balanceFormatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.tokens.accentBright,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Menu options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: AppLocalizations.of(context)!.settings_button,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.currency_exchange,
                      title: 'Boltz',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BoltzScreen(),
                          ),
                        );
                      },
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.swap_horiz,
                      title: 'Fixed Float',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FixedFloatScreen(),
                          ),
                        );
                      },
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context)!.about_title,
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
                    ),
                  ],
                ),
              ),

              // Footer with logout
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: context.tokens.outline,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLogoutConfirmation(authProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.tokens.statusUnhealthy.withValues(alpha: 0.2),
                          foregroundColor: context.tokens.statusUnhealthy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(
                          AppLocalizations.of(context)!.logout_option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.tokens.outline, width: 1),
          ),
          child: Icon(
            icon,
            color: context.tokens.accentBright,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.tokens.textPrimary,
          ),
        ),
        subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.tokens.textPrimary.withValues(alpha: 0.7),
              ),
            )
          : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showAboutDialog() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLocale.languageCode;
    
    String subtitle;
    String description;
    
    switch (currentLanguage) {
      case 'en':
        subtitle = 'Lightning Wallet';
        description = 'A mobile application to manage Bitcoin through Lightning Network using LNBits as backend.';
        break;
      case 'pt':
        subtitle = 'Carteira Lightning';
        description = 'Uma aplicação móvel para gerir Bitcoin através da Lightning Network usando LNBits como backend.';
        break;
      case 'de':
        subtitle = 'Lightning-Wallet';
        description = 'Eine mobile Anwendung zur Verwaltung von Bitcoin über das Lightning-Netzwerk mit LNBits als Backend.';
        break;
      case 'fr':
        subtitle = 'Portefeuille Lightning';
        description = 'Une application mobile pour gérer Bitcoin via le réseau Lightning en utilisant LNBits comme backend.';
        break;
      case 'it':
        subtitle = 'Portafoglio Lightning';
        description = 'Un\'applicazione mobile per gestire Bitcoin tramite Lightning Network utilizzando LNBits come backend.';
        break;
      case 'ru':
        subtitle = 'Lightning кошелек';
        description = 'Мобильное приложение для управления Bitcoin через Lightning Network с использованием LNBits в качестве бэкенда.';
        break;
      default: // es
        subtitle = 'Billetera Lightning';
        description = 'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.dialogBackground,
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
              style: TextStyle(color: context.tokens.textPrimary),
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
                color: context.tokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: context.tokens.textPrimary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.tokens.accentSolid.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.code,
                    color: context.tokens.accentBright,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppInfoService.getVersionDisplay(languageProvider.currentLocale.languageCode),
                    style: TextStyle(
                      color: context.tokens.accentBright,
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel_button,
              style: TextStyle(color: context.tokens.accentBright),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.dialogBackground,
        title: Text(
          AppLocalizations.of(context)!.logout_option,
          style: TextStyle(color: context.tokens.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirm_logout_message,
          style: TextStyle(color: context.tokens.textPrimary.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel_button,
              style: TextStyle(color: context.tokens.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              // Reset WalletProvider to clear previous session data
              final walletProvider = Provider.of<WalletProvider>(context, listen: false);
              walletProvider.reset();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.logout_option,
              style: TextStyle(color: context.tokens.statusUnhealthy),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(LanguageProvider languageProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
          ),
          borderRadius: BorderRadius.only(
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
                color: context.tokens.textTertiary,
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
                  color: context.tokens.textPrimary,
                ),
              ),
            ),
            
            // Language options
            ...languageProvider.getAvailableLanguages().map((language) {
              final isSelected = languageProvider.currentLocale.languageCode == language['code'];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await languageProvider.changeLanguage(Locale(language['code']!));
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
                              color: isSelected ? context.tokens.accentSolid : context.tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: context.tokens.accentSolid,
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
  final double maxLife;

  Particle(this.x, this.y, math.Random random) :
    size = (random.nextDouble() * 3 + 1.0), // 1-4px as specified
    speedX = (random.nextDouble() - 0.5) * (2 + random.nextDouble() * 4),
    speedY = (random.nextDouble() - 0.5) * (2 + random.nextDouble() * 4),
    life = 100, // Life 100 frames
    maxLife = 100,
    decay = random.nextDouble() * 1.5 + 0.5;

  void update() {
    x += speedX;
    y += speedY;
    life -= decay;
    speedX *= 0.99; // Gradual deceleration
    speedY *= 0.99;
  }

  bool get isAlive => life > 0;
  
  // EaseOutQuart curve for smooth fading (optimized)
  double get opacity {
    if (life <= 0) return 0.0;
    final normalizedLife = life / maxLife;
    return math.min(1.0, 1 - math.pow(1 - normalizedLife, 4).toDouble());
  }
}

class SparkPainter extends CustomPainter {
  final List<Particle> particles;

  SparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Optimized particle rendering
    if (particles.isEmpty) return;
    
    // Particle colors are intrinsic to the visual effect (CustomPainter, no context)
    const primaryColor = Color(0xFF5B73FF); // Glow exterior
    const secondaryColor = Color(0xFF4C63F7); // Glow interior
    
    // Draw particles with z-index 100 (overlay)
    for (final particle in particles) {
      final alpha = particle.opacity;
      if (alpha <= 0.01) continue; // Skip nearly invisible particles

      final center = Offset(particle.x, particle.y);
      final scaledSize = particle.size;
      
      // Check if particle is on screen (optimization)
      if (center.dx < -scaledSize * 2 || center.dx > size.width + scaledSize * 2 ||
          center.dy < -scaledSize * 2 || center.dy > size.height + scaledSize * 2) {
        continue;
      }

      // 1. Glow exterior (sutil)
      final glowPaint2 = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 2, glowPaint2);

      // 2. Inner glow (more intense)
      final glowPaint1 = Paint()
        ..color = secondaryColor.withValues(alpha: alpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 1.5, glowPaint1);

      // 3. Main particle (solid)
      final particlePaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.9);
      
      canvas.drawCircle(center, scaledSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) {
    // Only repaint if particle count changed (optimization)
    return particles.length != oldDelegate.particles.length;
  }
}