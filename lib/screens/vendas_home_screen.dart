import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import 'login/auth_provider.dart';
import 'configuracoes/configuracoes_screen.dart';
import 'dashboard/dashboard_vendas_screen.dart';
import 'pedidos/pedidos_venda_screen.dart';
import 'pre_vendas/pre_vendas_screen.dart';
import 'produtos/produtos_screen.dart';
import 'estatisticas/estatisticas_screen.dart';
import 'financeiro/contas_pagar_screen.dart';


class VendasHomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final VoidCallback onLogout;

  const VendasHomeScreen({
    super.key,
    required this.nomeUsuario,
    required this.onLogout,
  });

  @override
  State<VendasHomeScreen> createState() => _VendasHomeScreenState();
}

class _VendasHomeScreenState extends State<VendasHomeScreen> {
  int _abaSelecionada = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _irParaDashboard() => setState(() => _abaSelecionada = 0);
  void _abrirDrawer() => _scaffoldKey.currentState?.openDrawer();

  bool _ehAdmin(BuildContext context) {
    final grupo = (Provider.of<AuthProvider>(context, listen: false).grupo ?? '').toUpperCase();
    return grupo.contains('ADMINISTRADOR');
  }

  @override
  Widget build(BuildContext context) {
    final ehAdmin = _ehAdmin(context);

    final telas = [
      DashboardVendasScreen(onAbrirMenu: _abrirDrawer),
      PedidosVendaScreen(onVoltarDashboard: _irParaDashboard, onAbrirMenu: _abrirDrawer),
      PreVendasScreen(onVoltarDashboard: _irParaDashboard, onAbrirMenu: _abrirDrawer),
      ProdutosScreen(onVoltarDashboard: _irParaDashboard, onAbrirMenu: _abrirDrawer),
      
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        nomeUsuario: widget.nomeUsuario,
        onLogout: widget.onLogout,
        ehAdmin: ehAdmin,
        onNavegar: (index) {
          Navigator.pop(context);
          setState(() => _abaSelecionada = index);
        },
        abaSelecionada: _abaSelecionada,
      ),
      body: telas[_abaSelecionada],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaSelecionada,
        onDestinationSelected: (i) => setState(() => _abaSelecionada = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primary),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppTheme.primary),
            label: 'Pré-Vendas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppTheme.primary),
            label: 'Produtos',
          ),
          
        ],

      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String nomeUsuario;
  final VoidCallback onLogout;
  final void Function(int) onNavegar;
  final int abaSelecionada;
  final bool ehAdmin;

  const _AppDrawer({
    required this.nomeUsuario,
    required this.onLogout,
    required this.onNavegar,
    required this.abaSelecionada,
    required this.ehAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bem-vindo,',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(nomeUsuario,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(icone: Icons.dashboard_outlined, label: 'Dashboard', selecionado: abaSelecionada == 0, onTap: () => onNavegar(0)),
          _DrawerItem(icone: Icons.receipt_long_outlined, label: 'Pedidos de Venda', selecionado: abaSelecionada == 1, onTap: () => onNavegar(1)),
          _DrawerItem(icone: Icons.assignment_outlined, label: 'Pré-Vendas', selecionado: abaSelecionada == 2, onTap: () => onNavegar(2)),
          _DrawerItem(icone: Icons.inventory_2_outlined, label: 'Produtos', selecionado: abaSelecionada == 3, onTap: () => onNavegar(3)),
          // ✅ Estatísticas só para administradores
          if (ehAdmin)
            _DrawerItem(
              icone: Icons.bar_chart_outlined,
              label: 'Estatísticas',
              selecionado: false,
              onTap: () {
                Navigator.pop(context); // fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EstatisticasScreen(),
                  ),
                );
              },
            ),
          if (ehAdmin) ...[
            const Divider(),
            _DrawerItem(
              icone: Icons.account_balance_wallet_outlined,
              label: 'Contas a Pagar',
              selecionado: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const ContasPagarScreen(),
                  ),
                );
              },
            ),
          ],
          const Divider(),
          _DrawerItem(
            icone: Icons.settings_outlined,
            label: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()));
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Sair', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;
  final bool selecionado;

  const _DrawerItem({
    required this.icone,
    required this.label,
    required this.onTap,
    this.selecionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: selecionado ? AppTheme.primary : AppTheme.textMuted),
      title: Text(label,
          style: TextStyle(
              color: selecionado ? AppTheme.primary : AppTheme.textDark,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal)),
      selected: selecionado,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}