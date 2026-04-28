import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'screens/login/auth_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/mesas/mesas_screen.dart';
import 'screens/vendas_home_screen.dart';

const _gruposVendas = ['VENDEDORES', 'GERENTE', 'SUPERVISOR', 'ADMINISTRADORES'];

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const RestauranteApp(),
    ),
  );
}

class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Suporte a localização em português
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.estaLogado) {
      return LoginScreen(onLoginSucesso: () {});
    }

    final grupo = (auth.grupo ?? '').toUpperCase();
    final ehModuloVendas = _gruposVendas.any((g) => grupo.contains(g));

    if (ehModuloVendas) {
      return VendasHomeScreen(
        nomeUsuario: auth.nomeUsuario ?? '',
        onLogout: () => context.read<AuthProvider>().logout(),
      );
    }

    return MesasScreen(
      nomeUsuario: auth.nomeUsuario ?? '',
      onLogout: () => context.read<AuthProvider>().logout(),
    );
  }
}