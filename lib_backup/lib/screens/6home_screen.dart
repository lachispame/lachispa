import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/transaction_detector.dart';
import '../services/yadio_service.dart';
import '7history_screen.dart';
import '7ln_address_screen.dart';
import '9receive_screen.dart';
import '10send_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _walletsInitialized = false;
  bool _balanceVisible = true;
  bool _isInHistory = false;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  // Currency toggle
  int _currentCurrencyIndex = 0;
  final List<String> _currencies = ['sats', 'USD', 'CUP'];

  // Transaction detector
  final TransactionDetector _transactionDetector = TransactionDetector();
  late StreamSubscription _sparkSubscription;

  // Currency conversion service
  final YadioService _yadioService = YadioService();

  // Currency conversion cache to avoid multiple API calls
  Map<String, String> _conversionCache = {};

  // Timer to update conversions every 5 minutes
  Timer? _conversionTimer;
  DateTime? _lastConversionUpdate;
  int? _lastKnownBalance;

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
      _startConversionTimer();
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
    _conversionTimer?.cancel();
    _staggerController.dispose();
    _flashController.dispose();
    _glowController.dispose();
    _sparkController.dispose();
    _celebrationController.dispose();
    _sparkTimer.cancel();
    _sparkSubscription.cancel();
    _particles.clear(); // Memory leak prevention
    _yadioService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle auto-refresh according to app state
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
      _startConversionTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
      _stopConversionTimer();
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
      walletProvider
          .initializeWallets(
        serverUrl: authProvider.currentServer ?? '',
        authToken: authProvider.sessionData?.token ?? '',
      )
          .catchError((error) {
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

  // Start conversion timer every 5 minutes
  void _startConversionTimer() {
    _conversionTimer?.cancel();
    _conversionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      print('[HOME_SCREEN] Updating conversions by timer (5min)');
      _updateConversionsIfNeeded(force: true);
    });
  }

  void _stopConversionTimer() {
    _conversionTimer?.cancel();
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

    // Detect balance change
    final currentBalance = walletProvider.primaryBalance;
    final balanceChanged =
        _lastKnownBalance != null && _lastKnownBalance != currentBalance;

    if (balanceChanged) {
      print(
          '[HOME_SCREEN] Balance changed from $_lastKnownBalance to $currentBalance - updating conversions');
      // Clear cache and force conversion update
      _clearConversionCache();
      _updateConversionsIfNeeded(force: true);
    }

    _lastKnownBalance = currentBalance;

    if (showFeedback) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final previousBalance = walletProvider.primaryBalance;

    walletProvider
        .refreshPrimaryBalance(
      serverUrl: authProvider.currentServer ?? '',
    )
        .then((_) {
      // Check if there's a new deposit
      final newBalance = walletProvider.primaryBalance;
      if (newBalance > previousBalance) {
        final difference = newBalance - previousBalance;
        print('[HOME_SCREEN] New deposit detected');

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
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Deposit received! +$difference sats'),
                ],
              ),
              backgroundColor: Colors.green.withOpacity(0.9),
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
      print('[HOME_SCREEN] Error refreshing balance');
      if (showFeedback && mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }

  // Get conversion with cache to avoid multiple API calls
  Future<String> _getCachedConversion(int balanceSats, String currency) async {
    final cacheKey = '${balanceSats}_$currency';

    // Check cache first
    if (_conversionCache.containsKey(cacheKey)) {
      return _conversionCache[cacheKey]!;
    }

    try {
      // Make conversion using YadioService
      final result = await _yadioService.convertSatsToFiat(
        sats: balanceSats,
        currency: currency,
      );

      // Save to cache
      _conversionCache[cacheKey] = result;
      return result;
    } catch (e) {
      print('[HOME_SCREEN] Error converting balance to currency');
      return '--';
    }
  }

  // Clear cache when balance changes
  void _clearConversionCache() {
    _conversionCache.clear();
  }

  // Cyclic denomination toggle with animation
  void _toggleCurrency() {
    _flashController.forward().then((_) {
      setState(() {
        _currentCurrencyIndex =
            (_currentCurrencyIndex + 1) % _currencies.length;
      });
      _flashController.reverse();

      // Update conversions for new currency (only if not in cache)
      _updateConversionsIfNeeded();
    });
  }

  // Format main balance according to selected currency (sync)
  String _formatMainBalanceSync(int balanceSats) {
    if (!_balanceVisible) return '••• ${_currencies[_currentCurrencyIndex]}';

    final currency = _currencies[_currentCurrencyIndex];
    if (currency == 'sats') {
      return '$balanceSats sats';
    }

    // If balance is 0, show 0 directly in fiat currency
    if (balanceSats == 0) {
      return currency == 'USD' ? '\$0' : '0 $currency';
    }

    // For fiat currencies, show value from cache or "Calculating..."
    final cacheKey = '${balanceSats}_$currency';
    if (_conversionCache.containsKey(cacheKey)) {
      final value = _conversionCache[cacheKey]!;
      return currency == 'USD' ? '\$$value' : '$value $currency';
    }

    return 'Calculando...';
  }

  // Format secondary balance (sats) to show below when not in sats
  String? _formatSecondaryBalance(int balanceSats) {
    if (!_balanceVisible) return null;

    // Only show sats below when we're in another currency
    if (_currencies[_currentCurrencyIndex] == 'sats') {
      return null;
    }

    return '$balanceSats sats';
  }

  /// Determines balance font size based on selected currency
  double _getBalanceFontSize(bool isMobile) {
    final currency = _currencies[_currentCurrencyIndex];

    // For sats, use normal size
    if (currency == 'sats') {
      return isMobile ? 36 : 42;
    }

    // For CUP and USD, use smaller size
    return isMobile ? 28 : 34;
  }

  // Check if conversions need updating
  bool _needsConversionUpdate(int balanceSats, {bool force = false}) {
    if (force) return true;

    final currency = _currencies[_currentCurrencyIndex];
    if (currency == 'sats') return false;

    final cacheKey = '${balanceSats}_$currency';
    if (!_conversionCache.containsKey(cacheKey)) return true;

    // Check if more than 5 minutes have passed since last update
    if (_lastConversionUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastConversionUpdate!);
      return timeSinceUpdate.inMinutes >= 5;
    }

    return true;
  }

  // Update conversions only when necessary
  Future<void> _updateConversionsIfNeeded({bool force = false}) async {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.primaryWallet == null) return;

    final balanceSats = walletProvider.primaryBalance;
    final currency = _currencies[_currentCurrencyIndex];

    if (currency != 'sats' &&
        balanceSats > 0 &&
        _needsConversionUpdate(balanceSats, force: force)) {
      try {
        print('[HOME_SCREEN] Updating conversion');
        await _getCachedConversion(balanceSats, currency);
        _lastConversionUpdate = DateTime.now();

        // Update UI after getting conversion
        if (mounted) setState(() {});
      } catch (e) {
        print('[HOME_SCREEN] Error updating conversion: $e');
      }
    }
  }

  // Initialize spark effects system
  void _initializeSparkEffect() {
    _sparkSubscription =
        _transactionDetector.sparkTriggerStream.listen((shouldTrigger) {
      if (shouldTrigger && mounted) {
        print('[HOME_SCREEN] 🎆 Transaction event detected!');
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

    print('[HOME_SCREEN] 🎆 Activating deposit spark!');

    // Create 5-10 simultaneous sparks
    final sparkCount = _random.nextInt(6) + 5; // 5-10 chispas

    for (int spark = 0; spark < sparkCount; spark++) {
      final screenSize = MediaQuery.of(context).size;
      final x = _random.nextDouble() * screenSize.width;
      final y = _random.nextDouble() * screenSize.height;
      final particleCount =
          _random.nextInt(31) + 20; // 20-50 particles per spark

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

  @override
  Widget build(BuildContext context) {
    // Determine if it's mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer2<AuthProvider, WalletProvider>(
      builder: (context, authProvider, walletProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1419), // Azul oscuro profundo
                  Color(0xFF1A1D47), // Azul medio
                  Color(0xFF2D3FE7), // Azul vibrante
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                                            child: _buildBalanceCard(
                                                context, isMobile),
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
                                            child: _buildActionButtons(
                                                context, isMobile),
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
                                  willChange:
                                      true, // Optimization for animations
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
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
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
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius:
                            20 + (10 * _glowAnimation.value), // 20-30px blur
                        color: const Color(0xFF2D3FE7).withValues(
                          alpha: 0.3 +
                              (0.4 * _glowAnimation.value), // More intensity
                        ),
                      ),
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius:
                            10 + (5 * _glowAnimation.value), // Glow adicional
                        color: const Color(0xFF4C63F7).withValues(
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
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.auto_awesome,
                color: Colors.orange,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          walletProvider.primaryWallet!.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (walletProvider.isLoading) ...[
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cargando billeteras...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
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
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Saldo disponible',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
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
                                opacity:
                                    _isRefreshing ? 0.5 : _flashAnimation.value,
                                child: GestureDetector(
                                  onTap: _toggleCurrency,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Consumer<WalletProvider>(
                                      builder:
                                          (context, walletProvider, child) {
                                        // Show balance with dual format (fiat + sats)
                                        final balance =
                                            walletProvider.primaryBalance;
                                        final mainBalance = walletProvider
                                                    .primaryWallet !=
                                                null
                                            ? _formatMainBalanceSync(balance)
                                            : walletProvider.isLoading
                                                ? 'Cargando...'
                                                : '0 sats';

                                        // Activate conversions if necessary
                                        if (walletProvider.primaryWallet !=
                                                null &&
                                            _currencies[
                                                    _currentCurrencyIndex] !=
                                                'sats') {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            _updateConversionsIfNeeded();
                                          });
                                        }
                                        final secondaryBalance = walletProvider
                                                    .primaryWallet !=
                                                null
                                            ? _formatSecondaryBalance(balance)
                                            : null;

                                        return Column(
                                          key: ValueKey(
                                              '${_currentCurrencyIndex}_$balance'),
                                          children: [
                                            // Balance principal
                                            Text(
                                              mainBalance,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: _getBalanceFontSize(
                                                    isMobile),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // Secondary balance (sats) when not in sats mode
                                            if (secondaryBalance != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                secondaryBalance,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: isMobile ? 16 : 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ],
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
                            color: Colors.white.withOpacity(0.08),
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
                                color: Colors.white.withOpacity(0.6),
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
                      color: const Color(0xFF2D3FE7).withValues(
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Enviar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.north_east,
                          color: Colors.white,
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
                  color: Colors.white.withValues(
                    alpha: _receiveButtonPressed ? 0.12 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _receiveButtonPressed ? 0.2 : 0.1,
                    ),
                    width: 1,
                  ),
                  boxShadow: _receiveButtonPressed
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: GestureDetector(
                  onTapDown: (_) =>
                      setState(() => _receiveButtonPressed = true),
                  onTapUp: (_) => setState(() => _receiveButtonPressed = false),
                  onTapCancel: () =>
                      setState(() => _receiveButtonPressed = false),
                  onTap: () => _goToReceive(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.south_east,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recibir',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Seleccionar Billetera',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
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
                    final isSelected =
                        walletProvider.primaryWallet?.id == wallet.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2D3FE7).withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2D3FE7)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2D3FE7).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: isSelected
                                ? const Color(0xFF5B73FF)
                                : Colors.white70,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          wallet.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          wallet.balanceFormatted,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF5B73FF)
                                : Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF5B73FF),
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          walletProvider.setPrimaryWallet(wallet);
                          Navigator.pop(context);

                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Billetera "${wallet.name}" seleccionada'),
                              backgroundColor: const Color(0xFF2D3FE7),
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF5B73FF),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Crear nueva billetera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para crear una nueva billetera, accede a tu panel LNBits desde el navegador y usa la opción "Crear billetera".',
                      style: TextStyle(
                        color: Colors.white70,
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
                          backgroundColor: const Color(0xFF2D3FE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'Más información',
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
        backgroundColor: const Color(0xFF1A1D47),
        title: const Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Color(0xFF5B73FF),
            ),
            SizedBox(width: 8),
            Text(
              'Crear nueva billetera',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Para crear una nueva billetera:\n\n'
          '1. Abre tu navegador web\n'
          '2. Accede a tu servidor LNBits\n'
          '3. Inicia sesión con tu cuenta\n'
          '4. Busca el botón "Crear billetera"\n'
          '5. Asigna un nombre a tu nueva billetera\n'
          '6. Regresa a LaChispa y actualiza tus billeteras\n\n'
          'La nueva billetera aparecerá automáticamente en tu lista.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Color(0xFF5B73FF)),
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
          color: Colors.white.withOpacity(0.08), // Glassmorphism
          borderRadius: BorderRadius.circular(16), // Standard border radius
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                  color: _isInHistory ? const Color(0xFF5B73FF) : Colors.white,
                  size: 20, // Icon size according to guide
                ),
                const SizedBox(width: 12),
                Text(
                  'Historial',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500, // Weight for secondary buttons
                    color:
                        _isInHistory ? const Color(0xFF5B73FF) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider,
      WalletProvider walletProvider) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1D47),
      child: Container(
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
                            color: const Color(0xFF2D3FE7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _extractDomain(
                                    authProvider.currentServer ?? ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF5B73FF),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    walletProvider.primaryWallet!.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    walletProvider
                                        .primaryWallet!.balanceFormatted,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5B73FF),
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
                      icon: Icons.alternate_email,
                      title: 'Lightning Address',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LNAddressScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
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
                      color: Colors.white.withOpacity(0.1),
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
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Cerrar sesión',
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
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5B73FF),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D47),
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
            const Text(
              'LaChispa',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billetera Lightning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3FE7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.code,
                    color: Color(0xFF5B73FF),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Version: 0.0.1',
                    style: TextStyle(
                      color: Color(0xFF5B73FF),
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
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF5B73FF)),
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
        backgroundColor: const Color(0xFF1A1D47),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              // Reset WalletProvider to clear previous session data
              final walletProvider =
                  Provider.of<WalletProvider>(context, listen: false);
              walletProvider.reset();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
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

  Particle(this.x, this.y, math.Random random)
      : size = (random.nextDouble() * 3 + 1.0), // 1-4px as specified
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

    // Predefined Chispa colors for performance
    const primaryColor = Color(0xFF5B73FF); // Glow exterior
    const secondaryColor = Color(0xFF4C63F7); // Glow interior

    // Draw particles with z-index 100 (overlay)
    for (final particle in particles) {
      final alpha = particle.opacity;
      if (alpha <= 0.01) continue; // Skip nearly invisible particles

      final center = Offset(particle.x, particle.y);
      final scaledSize = particle.size;

      // Check if particle is on screen (optimization)
      if (center.dx < -scaledSize * 2 ||
          center.dx > size.width + scaledSize * 2 ||
          center.dy < -scaledSize * 2 ||
          center.dy > size.height + scaledSize * 2) {
        continue;
      }

      // 1. Glow exterior (sutil)
      final glowPaint2 = Paint()
        ..color = primaryColor.withOpacity(alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(center, scaledSize * 2, glowPaint2);

      // 2. Inner glow (more intense)
      final glowPaint1 = Paint()
        ..color = secondaryColor.withOpacity(alpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(center, scaledSize * 1.5, glowPaint1);

      // 3. Main particle (solid)
      final particlePaint = Paint()
        ..color = primaryColor.withOpacity(alpha * 0.9);

      canvas.drawCircle(center, scaledSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) {
    // Only repaint if particle count changed (optimization)
    return particles.length != oldDelegate.particles.length;
  }
}
