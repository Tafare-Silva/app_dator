// Entrada da Área do Cliente (app web/mobile separado do app interno).
// Build: flutter build web --target lib/main_cliente.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'cliente/catalogo_screen.dart';
import 'cliente/cliente_state.dart';
import 'core/app_theme.dart';
import 'core/empresas.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ClienteState()..iniciar(),
      child: const ClienteApp(),
    ),
  );
}

class ClienteApp extends StatelessWidget {
  const ClienteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Entrada(),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    if (!s.carregado) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // A chave força recarregar o catálogo ao trocar de loja.
    return s.temLoja ? CatalogoScreen(key: ValueKey(s.loja)) : const _EscolherLoja();
  }
}

class _EscolherLoja extends StatelessWidget {
  const _EscolherLoja();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a loja')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final e in empresasDisponiveis)
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(e.nome),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.read<ClienteState>().escolherLoja(e.id),
              ),
            ),
        ]),
      ),
    );
  }
}
