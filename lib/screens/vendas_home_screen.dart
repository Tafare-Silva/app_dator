import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import 'login/auth_provider.dart';
import 'configuracoes/configuracoes_screen.dart';
import 'dashboard/dashboard_vendas_screen.dart';
import 'dashboard/dashboard_consolidado_screen.dart';
import 'pedidos/pedidos_venda_screen.dart';
import 'pre_vendas/pre_vendas_screen.dart';
import 'pre_vendas/devolucao_condicional_screen.dart';
import 'produtos/produtos_screen.dart';
import 'estatisticas/estatisticas_screen.dart';
import 'financeiro/contas_pagar_screen.dart';
import 'financeiro/contas_receber_screen.dart';
import 'financeiro/despesas_por_categoria_screen.dart';
import 'financeiro/apuracao_resultado_screen.dart';


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
      DevolucaoCondicionalScreen(onVoltarDashboard: _irParaDashboard, onAbrirMenu: _abrirDrawer),
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
            icon: Icon(Icons.assignment_return_outlined),
            selectedIcon: Icon(Icons.assignment_return, color: AppTheme.primary),
            label: 'Devolução',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppTheme.primary),
            label: 'Condicional',
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
    final empresaNome = Provider.of<AuthProvider>(context).empresaNome;

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
                      if (empresaNome != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(empresaNome,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icone: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  selecionado: abaSelecionada == 0,
                  onTap: () => onNavegar(0)
                ),
                if (ehAdmin)
                  _DrawerItem(
                    icone: Icons.store_outlined,
                    label: 'Dashboard Consolidado',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardConsolidadoScreen()));
                    }
                  ),

                // --- SESSÃO: MOVIMENTAÇÕES ---
                ExpansionTile(
                  leading: const Icon(Icons.swap_horiz, color: AppTheme.primary),
                  title: const Text('Movimentações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  initiallyExpanded: abaSelecionada == 1 || abaSelecionada == 2,
                  children: [
                    _DrawerItem(
                      icone: Icons.assignment_return_outlined,
                      label: 'Devolução de Condicional',
                      selecionado: abaSelecionada == 1,
                      onTap: () => onNavegar(1),
                    ),
                    _DrawerItem(icone: Icons.assignment_outlined, label: 'Pré-Vendas', selecionado: abaSelecionada == 2, onTap: () => onNavegar(2)),
                    _DrawerItem(
                      icone: Icons.receipt_long_outlined,
                      label: 'Pedidos de Venda',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                          builder: (_) => PedidosVendaScreen(
                            onVoltarDashboard: () => Navigator.of(context, rootNavigator: true).pop(),
                          ),
                        ));
                      }
                    ),
                  ],
                ),

                // --- SESSÃO: FINANCEIRO ---
                // Contas a Receber é liberada para qualquer usuário logado (vendedores,
                // caixas, admins). Contas a Pagar, Despesas por Categoria e Apuração de
                // Resultados continuam restritas a administradores.
                ExpansionTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary),
                  title: const Text('Financeiro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  children: [
                    _DrawerItem(
                      icone: Icons.arrow_downward,
                      label: 'Contas a Receber',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ContasReceberScreen()));
                      }
                    ),
                    if (ehAdmin) ...[
                      _DrawerItem(
                        icone: Icons.arrow_upward,
                        label: 'Contas a Pagar',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ContasPagarScreen()));
                        }
                      ),
                      _DrawerItem(
                        icone: Icons.category_outlined,
                        label: 'Despesas por Categoria',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const DespesasPorCategoriaScreen()));
                        }
                      ),
                      _DrawerItem(
                        icone: Icons.insights_outlined,
                        label: 'Apuração de Resultados',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const ApuracaoResultadoScreen()));
                        }
                      ),
                    ],
                  ],
                ),

                // --- SESSÃO: CONSULTAS ---
                ExpansionTile(
                  leading: const Icon(Icons.search, color: AppTheme.primary),
                  title: const Text('Consultas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  initiallyExpanded: abaSelecionada == 3,
                  children: [
                    _DrawerItem(icone: Icons.inventory_2_outlined, label: 'Produtos', selecionado: abaSelecionada == 3, onTap: () => onNavegar(3)),
                    if (ehAdmin)
                      _DrawerItem(
                        icone: Icons.bar_chart_outlined,
                        label: 'Estatísticas',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EstatisticasScreen()));
                        }
                      ),
                  ],
                ),

                const Divider(),
                _DrawerItem(
                  icone: Icons.settings_outlined,
                  label: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()));
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      leading: Icon(icone, color: selecionado ? AppTheme.primary : AppTheme.textMuted, size: 20),
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: selecionado ? AppTheme.primary : AppTheme.textDark,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal)),
      selected: selecionado,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
