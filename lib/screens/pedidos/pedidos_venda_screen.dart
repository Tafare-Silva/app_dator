import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendas_models.dart';
import '../../services/vendas_service.dart';
import '../../core/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PedidosVendaScreen extends StatefulWidget {
  final VoidCallback? onVoltarDashboard;
  final VoidCallback? onAbrirMenu;
  const PedidosVendaScreen({super.key, this.onVoltarDashboard, this.onAbrirMenu});

  @override
  State<PedidosVendaScreen> createState() => _PedidosVendaScreenState();
}

class _PedidosVendaScreenState extends State<PedidosVendaScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');
  final _buscaCtrl = TextEditingController();

  late Future<List<PedidoVenda>> _futuroPedidos;
  late Future<List<Vendedor>> _futuroVendedores;

  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int? _vendedorSelecionado;
  List<Vendedor> _vendedores = [];
  List<PedidoVenda> _todosPedidos = [];
  List<PedidoVenda> _pedidosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _futuroVendedores = _service.listarVendedores();
    _futuroVendedores.then((v) => setState(() => _vendedores = v));
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _carregar() {
    _futuroPedidos = _service.listarPedidos(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      vendedorId: _vendedorSelecionado,
    ).then((pedidos) {
      _todosPedidos = pedidos;
      _aplicarBusca(_buscaCtrl.text);
      return pedidos;
    });
    setState(() {});
  }

  void _aplicarBusca(String termo) {
    final t = termo.toLowerCase().trim();
    setState(() {
      _pedidosFiltrados = t.isEmpty
          ? _todosPedidos
          : _todosPedidos.where((p) {
              return p.pkChave.toString().contains(t) ||
                  (p.clienteNome ?? '').toLowerCase().contains(t);
            }).toList();
    });
  }

  Future<void> _selecionarPeriodo() async {
    final inicioController = TextEditingController(text: _fmtData.format(_dataInicio));
    final fimController = TextEditingController(text: _fmtData.format(_dataFim));
    final mask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});

    final result = await showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: inicioController, decoration: const InputDecoration(labelText: 'Data Início (dd/mm/yyyy)', border: OutlineInputBorder()), inputFormatters: [mask], keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextFormField(controller: fimController, decoration: const InputDecoration(labelText: 'Data Fim (dd/mm/yyyy)', border: OutlineInputBorder()), inputFormatters: [mask], keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final inicio = _parseDataBR(inicioController.text);
              final fim = _parseDataBR(fimController.text);
              if (inicio != null && fim != null) {
                Navigator.pop(context, DateTimeRange(start: inicio, end: fim));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data inválida')));
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      _dataInicio = result.start;
      _dataFim = result.end;
      _carregar();
    }
  }

  DateTime? _parseDataBR(String data) {
    try {
      final parts = data.split('/');
      if (parts.length != 3) return null;
      final dia = int.tryParse(parts[0]);
      final mes = int.tryParse(parts[1]);
      final ano = int.tryParse(parts[2]);
      if (dia == null || mes == null || ano == null) return null;
      return DateTime(ano, mes, dia);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pedidos de Venda'),
        // ✅ botão voltar ou menu, usando callbacks do pai
        leading: widget.onVoltarDashboard != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onVoltarDashboard)
            : IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _selecionarPeriodo),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selecionarPeriodo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text('${_fmtData.format(_dataInicio)} — ${_fmtData.format(_dataFim)}', style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _buscaCtrl,
                  onChanged: _aplicarBusca,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nº do pedido ou cliente...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    suffixIcon: _buscaCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _buscaCtrl.clear(); _aplicarBusca(''); })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                if (_vendedores.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: _vendedorSelecionado,
                    decoration: const InputDecoration(labelText: 'Vendedor', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), isDense: true),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._vendedores.map((v) => DropdownMenuItem(value: v.pkChave, child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) { _vendedorSelecionado = v; _carregar(); },
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PedidoVenda>>(
              future: _futuroPedidos,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')));
                }

                // ✅ usa lista local se disponível, senão usa snap.data
                final lista = _pedidosFiltrados.isNotEmpty
                    ? _pedidosFiltrados
                    : (snap.data ?? []);

                if (lista.isEmpty) {
                  return const Center(child: Text('Nenhum pedido encontrado.', style: TextStyle(color: AppTheme.textMuted)));
                }

                final totalGeral = lista.fold(0.0, (s, p) => s + p.vrTotal);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.receipt_long, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('${lista.length} ${lista.length == 1 ? "pedido" : "pedidos"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
                          ]),
                          Text(_fmt.format(totalGeral), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CardPedido(pedido: lista[i], fmt: _fmt, fmtData: _fmtData, onTap: () => _abrirDetalhe(lista[i])),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(PedidoVenda pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalheSheet(pedidoId: pedido.pkChave, titulo: pedido.clienteNome ?? 'Pedido #${pedido.pkChave}', fmt: _fmt, fmtData: _fmtData, service: _service),
    );
  }
}

class _CardPedido extends StatelessWidget {
  final PedidoVenda pedido;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;
  const _CardPedido({required this.pedido, required this.fmt, required this.fmtData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('#${pedido.pkChave}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary))),
        ),
        title: Text(pedido.clienteNome ?? 'Consumidor Final', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pedido.vendedorNome ?? "—"} • ${fmtData.format(pedido.data)}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            Text('${pedido.quantidadeItens} ${pedido.quantidadeItens == 1 ? "item" : "itens"}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fmt.format(pedido.vrTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DetalheSheet extends StatefulWidget {
  final int pedidoId;
  final String titulo;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VendasService service;
  const _DetalheSheet({required this.pedidoId, required this.titulo, required this.fmt, required this.fmtData, required this.service});

  @override
  State<_DetalheSheet> createState() => _DetalheSheetState();
}

class _DetalheSheetState extends State<_DetalheSheet> {
  late Future<PedidoVenda> _futuroPedido;

  @override
  void initState() {
    super.initState();
    _futuroPedido = widget.service.getPedidoDetalhe(widget.pedidoId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('#${widget.pedidoId}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<PedidoVenda>(
              future: _futuroPedido,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError || snap.data == null) return const Center(child: Text('Erro ao carregar pedido.'));
                final p = snap.data!;
                final itens = p.itens ?? [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _InfoRow('Vendedor', p.vendedorNome ?? '—'),
                    _InfoRow('Data', widget.fmtData.format(p.data)),
                    if (p.vrFrete > 0) _InfoRow('Frete', widget.fmt.format(p.vrFrete)),
                    const SizedBox(height: 12),
                    const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    ...itens.map((i) => _ItemRow(item: i, fmt: widget.fmt)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                        Text(widget.fmt.format(p.vrTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  const _InfoRow(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemVenda item;
  final NumberFormat fmt;
  const _ItemRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final qtdStr = item.quantidade == item.quantidade.truncateToDouble()
        ? item.quantidade.toStringAsFixed(0)
        : item.quantidade.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produtoNome ?? 'Produto #${item.produtoId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text('$qtdStr x ${fmt.format(item.vrUnitarioBruto)}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                if (item.vendedorNome != null) Text('Vendedor: ${item.vendedorNome}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                if (item.vrDescontoTotal > 0) Text('Desconto: ${fmt.format(item.vrDescontoTotal)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                if (item.itemDevolvido) const Text('⚠️ Devolvido', style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ),
          ),
          Text(fmt.format(item.vrTotalLiquido), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
        ],
      ),
    );
  }
}