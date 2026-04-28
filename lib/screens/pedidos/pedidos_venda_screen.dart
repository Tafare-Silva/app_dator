import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendas_models.dart';
import '../../services/1vendas_service.dart';
import '../../core/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PedidosVendaScreen extends StatefulWidget {
  const PedidosVendaScreen({super.key});

  @override
  State<PedidosVendaScreen> createState() => _PedidosVendaScreenState();
}

class _PedidosVendaScreenState extends State<PedidosVendaScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  late Future<List<PedidoVenda>> _futuroPedidos;
  late Future<List<Vendedor>> _futuroVendedores;

  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime.now();
  int? _vendedorSelecionado;
  List<Vendedor> _vendedores = [];

  @override
  void initState() {
    super.initState();
    _futuroVendedores = _service.listarVendedores();
    _futuroVendedores.then((v) => setState(() => _vendedores = v));
    _carregar();
  }

  void _carregar() {
    _futuroPedidos = _service.listarPedidos(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      vendedorId: _vendedorSelecionado,
    );
    setState(() {});
  }

  Future<void> _selecionarPeriodo() async {
      // ✅ SOLUÇÃO 3: Diálogo customizado com campos de data com máscara
      final inicioController = TextEditingController(
        text: _dataInicio != null ? _fmtData.format(_dataInicio!) : '',
      );
      final fimController = TextEditingController(
        text: _dataFim != null ? _fmtData.format(_dataFim!) : '',
      );

      final maskFormatter = MaskTextInputFormatter(
        mask: '##/##/####',  // dd/mm/yyyy
        filter: {"#": RegExp(r'[0-9]')},
      );

      final result = await showDialog<DateTimeRange?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selecionar Período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo início COM MÁSCARA
              TextFormField(
                controller: inicioController,
                decoration: const InputDecoration(
                  labelText: 'Data Início (dd/mm/yyyy)',
                  hintText: '01/01/2025',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [maskFormatter],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Campo fim COM MÁSCARA
              TextFormField(
                controller: fimController,
                decoration: const InputDecoration(
                  labelText: 'Data Fim (dd/mm/yyyy)',
                  hintText: '31/12/2025',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [maskFormatter],
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  // Parse das datas (dd/mm/yyyy)
                  final inicio = _parseDataBR(inicioController.text);
                  final fim = _parseDataBR(fimController.text);

                  if (inicio != null && fim != null) {
                    Navigator.pop(
                      context,
                      DateTimeRange(start: inicio, end: fim),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data inválida')),
                    );
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao processar datas')),
                  );
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

    // ✅ FUNÇÃO AUXILIAR para converter dd/mm/yyyy em DateTime
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
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _selecionarPeriodo),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selecionarPeriodo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${_fmtData.format(_dataInicio)} — ${_fmtData.format(_dataFim)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                if (_vendedores.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _vendedorSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Vendedor',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._vendedores.map((v) => DropdownMenuItem(
                            value: v.pkChave,
                            child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) {
                      _vendedorSelecionado = v;
                      _carregar();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Lista com totalizador
          Expanded(
            child: FutureBuilder<List<PedidoVenda>>(
              future: _futuroPedidos,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: ElevatedButton(
                        onPressed: _carregar, child: const Text('Tentar novamente')),
                  );
                }

                final pedidos = snap.data ?? [];

                if (pedidos.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pedido encontrado.',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }

                // Totalizadores
                final totalGeral = pedidos.fold(0.0, (s, p) => s + p.vrTotal);

                return Column(
                  children: [
                    // Barra de totais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${pedidos.length} ${pedidos.length == 1 ? "pedido" : "pedidos"}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.primary),
                              ),
                            ],
                          ),
                          Text(
                            _fmt.format(totalGeral),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),

                    // Lista
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pedidos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CardPedido(
                          pedido: pedidos[i],
                          fmt: _fmt,
                          fmtData: _fmtData,
                          onTap: () => _abrirDetalhe(pedidos[i]),
                        ),
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
      builder: (_) => _DetalheSheet(
        pedidoId: pedido.pkChave,
        titulo: pedido.clienteNome ?? 'Pedido #${pedido.pkChave}',
        fmt: _fmt,
        fmtData: _fmtData,
        service: _service,
      ),
    );
  }
}

// ── Card do pedido ────────────────────────────────────────────────────────────

class _CardPedido extends StatelessWidget {
  final PedidoVenda pedido;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;

  const _CardPedido({
    required this.pedido,
    required this.fmt,
    required this.fmtData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt, color: AppTheme.primary),
        ),
        title: Text(
          pedido.clienteNome ?? 'Consumidor Final',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pedido.vendedorNome ?? "—"} • ${fmtData.format(pedido.data)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            Text(
              '${pedido.quantidadeItens} ${pedido.quantidadeItens == 1 ? "item" : "itens"}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fmt.format(pedido.vrTotal),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet de detalhe do pedido ─────────────────────────────────────────

class _DetalheSheet extends StatefulWidget {
  final int pedidoId;
  final String titulo;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VendasService service;

  const _DetalheSheet({
    required this.pedidoId,
    required this.titulo,
    required this.fmt,
    required this.fmtData,
    required this.service,
  });

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '#${widget.pedidoId}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(),
          // Conteúdo
          Expanded(
            child: FutureBuilder<PedidoVenda>(
              future: _futuroPedido,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || snap.data == null) {
                  return const Center(child: Text('Erro ao carregar pedido.'));
                }

                final p = snap.data!;
                final itens = p.itens ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Informações do cabeçalho
                    _InfoRow('Vendedor', p.vendedorNome ?? '—'),
                    _InfoRow('Data', widget.fmtData.format(p.data)),
                    if (p.vrFrete > 0) _InfoRow('Frete', widget.fmt.format(p.vrFrete)),
                    const SizedBox(height: 12),
                    const Text('Itens',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    ...itens.map((item) => _ItemRow(item: item, fmt: widget.fmt)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark)),
                        Text(
                          widget.fmt.format(p.vrTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary),
                        ),
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
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 13)),
          ),
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
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.produtoNome ?? 'Produto #${item.produtoId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '$qtdStr x ${fmt.format(item.vrUnitarioBruto)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                if (item.vrDescontoTotal > 0)
                  Text('Desconto: ${fmt.format(item.vrDescontoTotal)}',
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                if (item.itemDevolvido)
                  const Text('⚠️ Devolvido',
                      style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ),
          ),
          Text(
            fmt.format(item.vrTotalLiquido),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}