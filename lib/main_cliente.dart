// Entrada da Área do Cliente (app web/mobile separado do app interno).
// Build: flutter build web --target lib/main_cliente.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'cliente/carrinho_screen.dart';
import 'cliente/catalogo_screen.dart';
import 'cliente/cliente_state.dart';
import 'cliente/cliente_tema.dart';
import 'cliente/titulos_screen.dart';
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
      theme: ClienteTema.theme,
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
    if (!s.carregado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ClienteTema.marca)));
    }
    // A chave força recarregar o catálogo ao trocar de loja.
    return s.temLoja ? _Casca(key: ValueKey(s.loja)) : const _EscolherLoja();
  }
}

/// Barra de navegação inferior: Início / Carrinho / Meus títulos.
class _Casca extends StatefulWidget {
  const _Casca({super.key});
  @override
  State<_Casca> createState() => _CascaState();
}

class _CascaState extends State<_Casca> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    return Scaffold(
      // Início fica montado (mantém rolagem e filtros); as outras abas carregam ao abrir.
      body: IndexedStack(index: _aba, children: [
        const CatalogoScreen(),
        _aba == 1
            ? CarrinhoScreen(onConcluido: () => setState(() => _aba = 0), onVerCatalogo: () => setState(() => _aba = 0))
            : const SizedBox.shrink(),
        _aba == 2 ? const TitulosScreen() : const SizedBox.shrink(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Início'),
          NavigationDestination(
            icon: Badge(
                isLabelVisible: s.totalPecas > 0,
                label: Text('${s.totalPecas}'),
                child: const Icon(Icons.shopping_bag_outlined)),
            selectedIcon: Badge(
                isLabelVisible: s.totalPecas > 0,
                label: Text('${s.totalPecas}'),
                child: const Icon(Icons.shopping_bag)),
            label: 'Carrinho',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Meus títulos'),
        ],
      ),
    );
  }
}

class _EscolherLoja extends StatelessWidget {
  const _EscolherLoja();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [ClienteTema.marcaEscura, ClienteTema.marca],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 40),
                SizedBox(height: 16),
                Text('Bem-vinda(o)!',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Escolha a loja para ver as peças e montar seu condicional.',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            for (final e in empresasDisponiveis)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: ClienteTema.marca.withValues(alpha: 0.1),
                      child: const Icon(Icons.storefront, color: ClienteTema.marca),
                    ),
                    title: Text(e.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.read<ClienteState>().escolherLoja(e.id),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
