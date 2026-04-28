import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class ConsultaPrecosScreen extends StatefulWidget {
  const ConsultaPrecosScreen({super.key});

  @override
  State<ConsultaPrecosScreen> createState() => _ConsultaPrecosScreenState();
}

class _ConsultaPrecosScreenState extends State<ConsultaPrecosScreen> {
  final _service = ProdutoService();
  final _buscaCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Produto> _produtos = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _carregando = true);
    try {
      final resultado = await _service.buscarProdutos(
          busca: _buscaCtrl.text.trim().isEmpty ? null : _buscaCtrl.text.trim());
      setState(() => _produtos = resultado);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar produtos.')),
        );
      }
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Consulta de Preços')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaCtrl.clear();
                          _buscar();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _buscar(),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _produtos.isEmpty
                    ? const Center(
                        child: Text('Nenhum produto encontrado.',
                            style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _produtos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = _produtos[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Text(
                                p.nome ?? 'Produto #${p.pkChave}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark),
                              ),
                              trailing: Text(
                                _fmt.format(p.precoVenda),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primary),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}