import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/server_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/ln_address_provider.dart';
import 'providers/language_provider.dart';
import 'providers/currency_settings_provider.dart';
import 'services/wallet_service.dart';
import 'services/ln_address_service.dart';
import 'services/app_info_service.dart';
import 'services/deep_link_service.dart';
import 'screens/auth_checker.dart';
import 'screens/10send_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app info service to read version from pubspec.yaml
  await AppInfoService.initialize();
  
  // Initialize deep link service
  await DeepLinkService().initialize();
  
  runApp(const LaChispaApp());
}

class LaChispaApp extends StatefulWidget {
  const LaChispaApp({super.key});

  @override
  State<LaChispaApp> createState() => _LaChispaAppState();
}

class _LaChispaAppState extends State<LaChispaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _setupDeepLinkHandling();
  }
  
  void _setupDeepLinkHandling() {
    DeepLinkService().setOnLinkReceived((Uri uri) {
      _handleDeepLink(uri);
    });
  }
  
  void _handleDeepLink(Uri uri) {
    // Ensure we have a valid navigation context
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    
    String? paymentData;
    
    switch (uri.scheme.toLowerCase()) {
      case 'bitcoin':
        // Extract the address and parameters
        final params = DeepLinkService().parseBitcoinUri(uri);
        paymentData = params['address'] ?? '';
        break;
      case 'lightning':
      case 'lnurl':
      case 'lnurlw':
      case 'lnurlp':
      case 'lnurlc':
        paymentData = DeepLinkService().parseLightningUri(uri);
        break;
      case 'lachispa':
        // Handle app-specific deep links
        paymentData = uri.path.replaceFirst('/', '');
        break;
    }
    
    if (paymentData != null && paymentData.isNotEmpty) {
      // Check if user is logged in
      try {
        final authProvider = context.read<AuthProvider>();
        
        if (authProvider.isLoggedIn) {
          // User is logged in, proceed to send screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SendScreen(initialPaymentData: paymentData),
            ),
          );
        } else {
          // User is not logged in, show simple message
          _showLoginRequiredDialog(context);
        }
      } catch (e) {
        print('[DEEP_LINK] Error checking auth state: $e');
        // Fallback: show login message
        _showLoginRequiredDialog(context);
      }
    }
  }
  
  void _showLoginRequiredDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // No literal colors here; AlertDialog inherits from theme.
        return AlertDialog(
          title: Text(localizations.deep_link_login_required_title),
          content: Text(localizations.deep_link_login_required_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderFactory.create()),
        
        Provider<WalletService>(create: (_) => WalletService()),
        
        ProxyProvider<ServerProvider, LNAddressService>(
          create: (context) => LNAddressService(context.read<ServerProvider>().selectedServer),
          update: (_, serverProvider, previous) => LNAddressService(serverProvider.selectedServer),
        ),
        
        ChangeNotifierProxyProvider<WalletService, WalletProvider>(
          create: (context) => WalletProvider(context.read<WalletService>()),
          update: (_, walletService, previous) => previous ?? WalletProvider(walletService),
        ),
        ChangeNotifierProxyProvider2<LNAddressService, ServerProvider, LNAddressProvider>(
          create: (context) {
            final provider = LNAddressProvider(context.read<LNAddressService>());
            provider.setServerUrl(context.read<ServerProvider>().selectedServer);
            return provider;
          },
          update: (_, lnAddressService, serverProvider, previous) {
            final provider = previous ?? LNAddressProvider(lnAddressService);
            provider.setServerUrl(serverProvider.selectedServer);
            return provider;
          },
        ),
        
        // Currency settings provider - depends on server provider
        ChangeNotifierProxyProvider<ServerProvider, CurrencySettingsProvider>(
          create: (context) {
            final provider = CurrencySettingsProvider();
            final serverUrl = context.read<ServerProvider>().selectedServer;
            if (serverUrl.isNotEmpty) {
              // Initialize asynchronously
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.initialize(serverUrl: serverUrl);
              });
            }
            return provider;
          },
          update: (_, serverProvider, previous) {
            final provider = previous ?? CurrencySettingsProvider();
            final serverUrl = serverProvider.selectedServer;
            if (serverUrl.isNotEmpty) {
              // Update server URL if changed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.updateServerUrl(serverUrl);
              });
            }
            return provider;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeProvidersInParallel(context);
            _setupWalletLNAddressConnection(context);
          });
          
          return Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return MaterialApp(
                navigatorKey: _navigatorKey,
                title: 'LaChispa',
                theme: chispaTheme(),
                locale: languageProvider.currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('es', ''),
                  Locale('en', ''),
                  Locale('pt', ''),
                  Locale('de', ''),
                  Locale('fr', ''),
                  Locale('it', ''),
                  Locale('ru', ''),
                ],
                home: const AuthChecker(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }

  /// Initialize providers in parallel to improve performance
  void _initializeProvidersInParallel(BuildContext context) {
    try {
      final serverProvider = context.read<ServerProvider>();
      // Note: AuthProvider is now initialized by AuthChecker, not here
      Future.wait([
        serverProvider.initialize(),
      ]).catchError((error) {
        print('[MAIN] Error initializing providers: $error');
      });
    } catch (e) {
      print('[MAIN] Error accessing providers: $e');
    }
  }

  /// Set up automatic connection between WalletProvider and LNAddressProvider
  void _setupWalletLNAddressConnection(BuildContext context) {
    try {
      final walletProvider = context.read<WalletProvider>();
      final lnAddressProvider = context.read<LNAddressProvider>();
      
      walletProvider.setOnWalletChangedCallback((walletId) {
        lnAddressProvider.onWalletChanged(walletId);
      });
      
      print('[MAIN] WalletProvider <-> LNAddressProvider connection configured');
    } catch (e) {
      print('[MAIN] Error configuring provider connection: $e');
    }
  }
}