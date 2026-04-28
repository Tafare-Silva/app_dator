import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../core/app_theme.dart';
import '../mesa_detalhe/mesa_detalhe_screen.dart';
import '../consulta_precos/consulta_precos_screen.dart';
import '../configuracoes/configuracoes_screen.dart';

class MesasScreen extends StatefulWidget {
  final String nomeUsuario;
  final VoidCallback onLogout;

  const MesasScreen({
    super.key,
    required this.nomeUsuario,
    required this.onLogout,
  });

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  final _service = MesaService();
  late Future<List<Mesa>> _futuroMesas;

  @override
  void initState() {
    super.initState();
    _carregarMesas();
  }

  void _carregarMesas() {
    _futuroMesas = _service.listarMesas();
    setState(() {});
  }

  void _abrirMesa(Mesa mesa) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MesaDetalheScreen(mesa: mesa)),
    ).then((_) => _carregarMesas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMesas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: _MenuLateral(
        nomeUsuario: widget.nomeUsuario,
        onLogout: widget.onLogout,
      ),
      body: FutureBuilder<List<Mesa>>(
        future: _futuroMesas,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text('Erro ao carregar mesas',
                      style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _carregarMesas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final mesas = snap.data ?? [];
          if (mesas.isEmpty) {
            return const Center(
              child: Text('Nenhuma mesa cadastrada.',
                  style: TextStyle(color: AppTheme.textMuted)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _carregarMesas(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: mesas.length,
              itemBuilder: (_, i) => _MesaCard(
                mesa: mesas[i],
                onTap: () => _abrirMesa(mesas[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuLateral extends StatelessWidget {
  final String nomeUsuario;
  final VoidCallback onLogout;

  const _MenuLateral({required this.nomeUsuario, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            accountName: Text(nomeUsuario,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('Operador de mesa'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant, color: AppTheme.primary),
            title: const Text('Mesas'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: AppTheme.primary),
            title: const Text('Consultar Preços'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConsultaPrecosScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: AppTheme.textMuted),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Sair', style: TextStyle(color: AppTheme.error)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MesaCard extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;

  const _MesaCard({required this.mesa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_restaurant, size: 36, color: AppTheme.primary),
              const SizedBox(height: 10),
              Text(
                mesa.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (mesa.observacoes != null && mesa.observacoes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(mesa.observacoes!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}