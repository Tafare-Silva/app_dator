import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../services/config_service.dart';
import '../../core/app_theme.dart';
import '../produtos/busca_produto_screen.dart';
import '../conta/conta_screen.dart';

class MesaDetalheScreen extends StatefulWidget {
  final Mesa mesa;
  const MesaDetalheScreen({super.key, required this.mesa});

  @override
  State<MesaDetalheScreen> createState() => _MesaDetalheScreenState();
}

class _MesaDetalheScreenState extends State<MesaDetalheScreen> {
  final _service = ItemMesaService();
  final _impressaoService = ImpressaoService();
  final _config = ConfigService();
  late Future<List<ItemMesa>> _futuroItens;
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _imprimindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuroItens = _service.listarItens(widget.mesa.nome);
    setState(() {});
  }

  Future<void> _imprimirNaCozinha() async {
    final impressoraIp = await _config.getImpressoraIp();
    if (impressoraIp.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configure o IP da impressora em Configurações.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }
    setState(() => _imprimindo = true);
    try {
      final porta = await _config.getImpressoraPorta();
      await _impressaoService.imprimirPedido(
        nomeMesa: widget.mesa.nome,
        impressoraIp: impressoraIp,
        impressoraPorta: porta,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pedido enviado para a cozinha!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao imprimir. Verifique a impressora.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _adicionarProduto() async {
    final adicionado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuscaProdutoScreen(nomeMesa: widget.mesa.nome),
      ),
    );
    if (adicionado == true) _carregar();
  }

  Future<void> _removerItem(ItemMesa item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover item'),
        content: Text(
            'Remover "${item.produto?.nome ?? 'item'}" da comanda?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remover', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await _service.removerItem(widget.mesa.nome, item.pkChave);
        _carregar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao remover item.')),
          );
        }
      }
    }
  }

  void _verConta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContaScreen(nomeMesa: widget.mesa.nome),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.mesa.nome),
        actions: [
          _imprimindo
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Imprimir na cozinha',
                  onPressed: _imprimirNaCozinha,
                ),
          TextButton.icon(
            onPressed: _verConta,
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text('Conta',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarProduto,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<ItemMesa>>(
        future: _futuroItens,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snap.data ?? [];

          if (itens.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_outlined,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Comanda vazia',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  const Text('Toque em Adicionar para lançar produtos.',
                      style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          final total = itens.fold(0.0, (s, i) => s + i.vrTotal);

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _carregar(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ItemCard(
                      item: itens[i],
                      fmt: _fmt,
                      onRemover: () => _removerItem(itens[i]),
                    ),
                  ),
                ),
              ),

              // Total fixo no rodapé
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${itens.length} ${itens.length == 1 ? 'item' : 'itens'}',
                        style: const TextStyle(color: AppTheme.textMuted)),
                    Text(
                      _fmt.format(total),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemMesa item;
  final NumberFormat fmt;
  final VoidCallback onRemover;

  const _ItemCard({
    required this.item,
    required this.fmt,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.produto?.nome ?? 'Produto #${item.fkProdutosProduto}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantidade.toStringAsFixed(item.quantidade == item.quantidade.truncate() ? 0 : 2)} x ${fmt.format(item.vrUnitarioBruto)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted),
                  ),
                  if (item.observacoesItem != null &&
                      item.observacoesItem!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📝 ${item.observacoesItem}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(item.vrTotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRemover,
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.error, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}