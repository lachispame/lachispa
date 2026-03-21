import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/server_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/ln_address_provider.dart';
import 'services/wallet_service.dart';
import 'services/ln_address_service.dart';
import 'screens/1welcome_screen.dart';

void main() {
  runApp(const LaChispaApp());
}

class LaChispaApp extends StatefulWidget {
  const LaChispaApp({super.key});

  @override
  State<LaChispaApp> createState() => _LaChispaAppState();
}

class _LaChispaAppState extends State<LaChispaApp> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderFactory.create()),
        Provider<WalletService>(create: (_) => WalletService()),
        ProxyProvider<ServerProvider, LNAddressService>(
          create: (context) =>
              LNAddressService(context.read<ServerProvider>().selectedServer),
          update: (_, serverProvider, previous) {
            previous?.updateServerUrl(serverProvider.selectedServer);
            return previous ?? LNAddressService(serverProvider.selectedServer);
          },
        ),
        ChangeNotifierProxyProvider<WalletService, WalletProvider>(
          create: (context) => WalletProvider(context.read<WalletService>()),
          update: (_, walletService, previous) =>
              previous ?? WalletProvider(walletService),
        ),
        ChangeNotifierProxyProvider2<LNAddressService, ServerProvider,
            LNAddressProvider>(
          create: (context) {
            final provider =
                LNAddressProvider(context.read<LNAddressService>());
            provider
                .setServerUrl(context.read<ServerProvider>().selectedServer);
            return provider;
          },
          update: (_, lnAddressService, serverProvider, previous) {
            final provider = previous ?? LNAddressProvider(lnAddressService);
            provider.setServerUrl(serverProvider.selectedServer);
            return provider;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeProvidersInParallel(context);
              _setupWalletLNAddressConnection(context);
            });
          }

          return MaterialApp(
            title: 'LaChispa',
            theme: ThemeData(
              fontFamily: 'Inter',
              useMaterial3: true,
            ),
            home: const WelcomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  void _initializeProvidersInParallel(BuildContext context) {
    try {
      final serverProvider = context.read<ServerProvider>();
      final authProvider = context.read<AuthProvider>();
      Future.wait([
        serverProvider.initialize(),
        authProvider.initialize(),
      ]).catchError((error) {
        print('[MAIN] Error initializing providers: $error');
      });
    } catch (e) {
      print('[MAIN] Error accessing providers: $e');
    }
  }

  void _setupWalletLNAddressConnection(BuildContext context) {
    try {
      final walletProvider = context.read<WalletProvider>();
      final lnAddressProvider = context.read<LNAddressProvider>();

      walletProvider.setOnWalletChangedCallback((walletId) {
        lnAddressProvider.onWalletChanged(walletId);
      });

      print(
          '[MAIN] WalletProvider <-> LNAddressProvider connection configured');
    } catch (e) {
      print('[MAIN] Error configuring provider connection: $e');
    }
  }
}
