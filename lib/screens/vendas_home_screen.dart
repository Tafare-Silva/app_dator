import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'dashboard/dashboard_vendas_screen.dart';
import 'pedidos/pedidos_venda_screen.dart';
import 'pre_vendas/pre_vendas_screen.dart';

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

  late final List<Widget> _telas = [
    const DashboardVendasScreen(),
    const PedidosVendaScreen(),
    const PreVendasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_abaSelecionada],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaSelecionada,
        onDestinationSelected: (i) => setState(() => _abaSelecionada = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primary),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppTheme.primary),
            label: 'Pré-Vendas',
          ),
        ],
      ),
    );
  }
}