import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendas_models.dart';
import '../../services/vendas_service.dart';
import '../../services/pre_venda_pdf_service.dart';
import '../../services/config_service.dart';
import '../../core/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'nova_pre_venda_screen.dart';

class PreVendasScreen extends StatefulWidget {
  final VoidCallback? onVoltarDashboard;
  final VoidCallback? onAbrirMenu;
  const PreVendasScreen({super.key, this.onVoltarDashboard, this.onAbrirMenu});

  @override
  State<PreVendasScreen> createState() => _PreVendasScreenState();
}

class _PreVendasScreenState extends State<PreVendasScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');
  final _buscaCtrl = TextEditingController();

  late Future<List<PreVenda>> _futuroPreVendas;
  late Future<List<Vendedor>> _futuroVendedores;

  DateTime? _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _dataFim = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int? _vendedorSelecionado;
  bool? _efetivada;
  List<Vendedor> _vendedores = [];
  List<PreVenda> _todasPreVendas = [];
  List<PreVenda> _preVendasFiltradas = [];

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
    _futuroPreVendas = _service.listarPreVendas(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      vendedorId: _vendedorSelecionado,
      efetivada: _efetivada,
    ).then((pv) {
      _todasPreVendas = pv;
      _aplicarBusca(_buscaCtrl.text);
      return pv;
    });
    setState(() {});
  }

  void _aplicarBusca(String termo) {
    final t = termo.toLowerCase().trim();
    setState(() {
      _preVendasFiltradas = t.isEmpty
          ? _todasPreVendas
          : _todasPreVendas.where((p) {
              return p.pkChave.toString().contains(t) ||
                  (p.clienteNome ?? '').toLowerCase().contains(t);
            }).toList();
    });
  }

  Future<void> _selecionarPeriodo() async {
    final inicioController = TextEditingController(text: _dataInicio != null ? _fmtData.format(_dataInicio!) : '');
    final fimController = TextEditingController(text: _dataFim != null ? _fmtData.format(_dataFim!) : '');
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

  void _limparFiltros() {
    _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _dataFim = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _vendedorSelecionado = null;
    _efetivada = null;
    _buscaCtrl.clear();
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pré-Vendas / Condicionais'),
        // ✅ usa callback do pai para abrir drawer
        leading: widget.onVoltarDashboard != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onVoltarDashboard)
            : IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nova Pré-Venda',
            onPressed: () async {
              final criada = await Navigator.of(context, rootNavigator: true).push<PreVenda>(
                MaterialPageRoute(builder: (_) => NovaPreVendaScreen(onPreVendaCriada: _carregar)),
              );
              if (criada != null) _carregar();
            },
          ),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: _limparFiltros, tooltip: 'Limpar filtros'),
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
                        Flexible(
                          child: Text(
                            _dataInicio != null && _dataFim != null
                                ? '${_fmtData.format(_dataInicio!)} — ${_fmtData.format(_dataFim!)}'
                                : 'Selecionar período',
                            style: TextStyle(fontSize: 12, color: _dataInicio != null ? AppTheme.textDark : AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                          ),
                        ),
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
                    hintText: 'Buscar por nº ou cliente...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    suffixIcon: _buscaCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _buscaCtrl.clear(); _aplicarBusca(''); })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_vendedores.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _vendedorSelecionado,
                          decoration: const InputDecoration(labelText: 'Vendedor', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), isDense: true),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ..._vendedores.map((v) => DropdownMenuItem(value: v.pkChave, child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) { _vendedorSelecionado = v; _carregar(); },
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _efetivada,
                        decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), isDense: true),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: false, child: Text('Pendentes')),
                          DropdownMenuItem(value: true, child: Text('Efetivadas')),
                        ],
                        onChanged: (v) { _efetivada = v; _carregar(); },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PreVenda>>(
              future: _futuroPreVendas,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')));
                }

                // ✅ CORREÇÃO: usa lista local se disponível, senão usa snap.data
                final lista = _preVendasFiltradas.isNotEmpty
                    ? _preVendasFiltradas
                    : (snap.data ?? []);

                if (lista.isEmpty) {
                  return const Center(child: Text('Nenhuma pré-venda encontrada.', style: TextStyle(color: AppTheme.textMuted)));
                }

                final pendentes = lista.where((p) => !p.efetivada).length;
                final efetivadas = lista.where((p) => p.efetivada).length;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text('${lista.length} total', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
                          const SizedBox(width: 12),
                          if (pendentes > 0) _ChipTotal(label: '$pendentes pendente${pendentes > 1 ? "s" : ""}', cor: Colors.orange),
                          if (efetivadas > 0) ...[
                            const SizedBox(width: 6),
                            _ChipTotal(label: '$efetivadas efetivada${efetivadas > 1 ? "s" : ""}', cor: Colors.green),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CardPreVenda(preVenda: lista[i], fmt: _fmt, fmtData: _fmtData, onTap: () => _abrirDetalhe(lista[i])),
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

  void _abrirDetalhe(PreVenda preVenda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalhePreVendaSheet(preVenda: preVenda, fmt: _fmt, fmtData: _fmtData, service: _service),
    );
  }
}

class _ChipTotal extends StatelessWidget {
  final String label;
  final Color cor;
  const _ChipTotal({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
    );
  }
}

class _CardPreVenda extends StatelessWidget {
  final PreVenda preVenda;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;
  const _CardPreVenda({required this.preVenda, required this.fmt, required this.fmtData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusCor = preVenda.efetivada ? Colors.green : Colors.orange;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${preVenda.pkChave}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusCor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(preVenda.efetivada ? 'Efetivada' : 'Pendente', style: TextStyle(color: statusCor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(preVenda.clienteNome ?? 'Sem cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(preVenda.vendedorNome ?? '—', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(fmtData.format(preVenda.data), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              if (preVenda.dataEntrega != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.local_shipping_outlined, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Entrega: ${fmtData.format(preVenda.dataEntrega!)}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${preVenda.quantidadeItens} ${preVenda.quantidadeItens == 1 ? "item" : "itens"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Row(children: [
                    Text(fmt.format(preVenda.vrTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalhePreVendaSheet extends StatelessWidget {
  final PreVenda preVenda;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VendasService service;
  const _DetalhePreVendaSheet({required this.preVenda, required this.fmt, required this.fmtData, required this.service});

  @override
  Widget build(BuildContext context) {
    final statusCor = preVenda.efetivada ? Colors.green : Colors.orange;

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
                const Icon(Icons.assignment, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(preVenda.clienteNome ?? 'Sem cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text('#${preVenda.pkChave}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusCor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(preVenda.efetivada ? 'Efetivada' : 'Pendente', style: TextStyle(color: statusCor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _compartilharPdf(context),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Compartilhar PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _visualizarPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Visualizar PDF'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _buscarItens(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final itens = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _InfoRow('Vendedor', preVenda.vendedorNome ?? '—'),
                    _InfoRow('Data', fmtData.format(preVenda.data)),
                    if (preVenda.dataEntrega != null) _InfoRow('Entrega', fmtData.format(preVenda.dataEntrega!)),
                    if (preVenda.condicaoPagamento != null) _InfoRow('Cond. Pgto', preVenda.condicaoPagamento!),
                    const SizedBox(height: 12),
                    const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    if (itens.isEmpty)
                      const Text('Nenhum item encontrado.', style: TextStyle(color: AppTheme.textMuted))
                    else
                      ...itens.map((item) => _ItemPreVendaRow(item: item, fmt: fmt)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                        Text(fmt.format(preVenda.vrTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
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

  Future<List<Map<String, dynamic>>> _buscarItens() async {
    try {
      final detalhe = await service.getPreVendaDetalhe(preVenda.pkChave);
      return detalhe.itens.map((i) => {
        'produto_nome': i.produtoNome ?? 'Produto #${i.produtoId}',
        'quantidade': i.quantidade,
        'vr_unitario_bruto': i.vrUnitarioBruto,
        'vr_total_liquido': i.vrTotalLiquido,
        'vr_desconto_total': i.vrDescontoTotal,
        'item_devolvido': i.itemDevolvido,
        'vendedor_nome': i.vendedorNome,
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _compartilharPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detalhe = await service.getPreVendaDetalhe(preVenda.pkChave);
      final empresa = await ConfigService().getNomeEmpresa();
      await PreVendaPdfService.compartilhar(detalhe, nomeEmpresa: empresa);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red));
    }
  }

  void _visualizarPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detalhe = await service.getPreVendaDetalhe(preVenda.pkChave);
      final empresa = await ConfigService().getNomeEmpresa();
      await PreVendaPdfService.visualizar(detalhe, nomeEmpresa: empresa);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao abrir PDF: $e'), backgroundColor: Colors.red));
    }
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
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 12))),
        ],
      ),
    );
  }
}

class _ItemPreVendaRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat fmt;
  const _ItemPreVendaRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final qtd = item['quantidade'] as double;
    final qtdStr = qtd == qtd.truncateToDouble() ? qtd.toStringAsFixed(0) : qtd.toStringAsFixed(2);

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
                Text(item['produto_nome'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark), softWrap: true, maxLines: 3),
                const SizedBox(height: 2),
                Text('$qtdStr x ${fmt.format(item['vr_unitario_bruto'])}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                if (item['vendedor_nome'] != null) Text('Vendedor: ${item['vendedor_nome']}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                if ((item['vr_desconto_total'] as double) > 0) Text('Desconto: ${fmt.format(item['vr_desconto_total'])}', style: const TextStyle(fontSize: 10, color: Colors.red)),
                if ((item['item_devolvido'] as bool? ?? false)) const Text('⚠️ Devolvido', style: TextStyle(fontSize: 10, color: Colors.orange)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(fmt.format(item['vr_total_liquido']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
        ],
      ),
    );
  }
}