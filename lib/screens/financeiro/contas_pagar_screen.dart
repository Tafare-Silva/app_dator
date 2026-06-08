import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/financeiro_model.dart';
import '../../services/financeiro_service.dart';

class ContasPagarScreen extends StatefulWidget {
  final VoidCallback? onAbrirMenu;
  const ContasPagarScreen({super.key, this.onAbrirMenu});

  @override
  State<ContasPagarScreen> createState() => _ContasPagarScreenState();
}

class _ContasPagarScreenState extends State<ContasPagarScreen> {
  final _service = FinanceiroService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  // Período (vencimento)
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  // Período (baixa)
  DateTime? _dataBaixaInicio;
  DateTime? _dataBaixaFim;

  FiltroItem? _planoContas;
  FiltroItem? _centroCustos;
  String? _situacao = 'NORMAL';

  // Tipo de data a filtrar quando PAGAS: 'vencimento' ou 'baixa'
  String _tipoDataFiltro = 'vencimento';

  List<FiltroItem> _planosContas = [];
  List<FiltroItem> _centrosCustos = [];
  List<ContaPagar> _titulos = [];
  List<ContaPagar> _filtrados = [];
  bool _carregando = false;
  String? _erro;

  final _buscaCtrl = TextEditingController();
  bool _filtrosExpandidos = true;

  bool get _mostrandoPagas => _situacao == 'PAGAS';

  @override
  void initState() {
    super.initState();
    _carregarFiltros();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  // ── Resumo calculado localmente a partir dos dados exibidos ──────────────────
  ResumoContasPagar get _resumoLocal {
    final hoje = DateTime.now();
    double vencido = 0, aVencer = 0, totalPago = 0, jurosMulta = 0, desconto = 0;
    int pendentes = 0, pagos = 0;
    for (final c in _filtrados) {
      if (c.pago) {
        pagos++;
        totalPago += c.valorPago;
        jurosMulta += c.juros + c.multa + c.adicional;
        desconto += c.desconto;
      } else {
        pendentes++;
        if (c.dataVencimento.isBefore(hoje)) {
          vencido += c.valorOriginal;
        } else {
          aVencer += c.valorOriginal;
        }
      }
    }
    return ResumoContasPagar(
      titulosPendentes: pendentes,
      titulosPagos: pagos,
      totalVencido: vencido,
      totalAVencer: aVencer,
      total: vencido + aVencer,
      totalPago: totalPago,
      totalJurosMulta: jurosMulta,
      totalDesconto: desconto,
    );
  }

  // ── Carregamento ──────────────────────────────────────────────────────────────

  Future<void> _carregarFiltros() async {
    try {
      final results = await Future.wait([
        _service.listarPlanosContas(),
        _service.listarCentrosCustos(),
      ]);
      if (mounted) {
        setState(() {
          _planosContas = results[0];
          _centrosCustos = results[1];
        });
      }
    } catch (_) {}
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      // Monta os parâmetros de data conforme o tipo selecionado
      final useVencimento = !_mostrandoPagas || _tipoDataFiltro == 'vencimento';
      final useBaixa = _mostrandoPagas && _tipoDataFiltro == 'baixa';

      final lista = await _service.listarContasPagar(
        dataInicio: useVencimento ? _dataInicio : null,
        dataFim: useVencimento ? _dataFim : null,
        dataBaixaInicio: useBaixa ? (_dataBaixaInicio ?? _dataInicio) : null,
        dataBaixaFim: useBaixa ? (_dataBaixaFim ?? _dataFim) : null,
        planoContasId: _planoContas?.pkChave,
        centroCustosId: _centroCustos?.pkChave,
        situacao: _situacao,
      );
      if (!mounted) return;
      setState(() {
        _titulos = lista;
        _carregando = false;
      });
      _aplicarBusca(_buscaCtrl.text);
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  void _aplicarBusca(String termo) {
    final t = termo.toLowerCase().trim();
    setState(() {
      _filtrados = t.isEmpty
          ? _titulos
          : _titulos.where((c) =>
              (c.pessoaNome ?? '').toLowerCase().contains(t) ||
              (c.documento ?? '').toLowerCase().contains(t) ||
              c.pkChave.toString().contains(t)).toList();
    });
  }

  void _limparFiltros() {
    setState(() {
      _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
      _dataBaixaInicio = null;
      _dataBaixaFim = null;
      _planoContas = null;
      _centroCustos = null;
      _situacao = null;
      _tipoDataFiltro = 'vencimento';
      _buscaCtrl.clear();
    });
    _carregar();
  }

  // ── Seletor de período com calendário ────────────────────────────────────────

  Future<void> _selecionarPeriodo({bool baixa = false}) async {
    final inicio = baixa ? (_dataBaixaInicio ?? _dataInicio) : _dataInicio;
    final fim = baixa ? (_dataBaixaFim ?? _dataFim) : _dataFim;

    final result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: inicio, end: fim),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );

    if (result == null) return;
    setState(() {
      if (baixa) {
        _dataBaixaInicio = result.start;
        _dataBaixaFim = result.end;
      } else {
        _dataInicio = result.start;
        _dataFim = result.end;
      }
    });
    _carregar();
  }

  void _abrirDetalhe(ContaPagar c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalheSheet(conta: c, fmt: _fmt, fmtData: _fmtData),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final resumo = _filtrados.isEmpty && !_carregando ? null : (_carregando ? null : _resumoLocal);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        leading: widget.onAbrirMenu != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu)
            : null,
        actions: [
          IconButton(
            icon: Icon(_filtrosExpandidos ? Icons.filter_list_off : Icons.filter_list),
            tooltip: _filtrosExpandidos ? 'Ocultar filtros' : 'Mostrar filtros',
            onPressed: () => setState(() => _filtrosExpandidos = !_filtrosExpandidos),
          ),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: _limparFiltros, tooltip: 'Limpar filtros'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ────────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _filtrosExpandidos ? _buildFiltros() : const SizedBox.shrink(),
          ),

          // ── Resumo ─────────────────────────────────────────────────────────
          if (resumo != null) _buildResumo(resumo),

          // ── Lista ──────────────────────────────────────────────────────────
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ]))
                    : _filtrados.isEmpty
                        ? const Center(child: Text('Nenhum título encontrado.', style: TextStyle(color: AppTheme.textMuted)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) => _CardContaPagar(
                              conta: _filtrados[i],
                              fmt: _fmt,
                              fmtData: _fmtData,
                              onTap: () => _abrirDetalhe(_filtrados[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // ── Status ─────────────────────────────────────────────────────────
          DropdownButtonFormField<String?>(
            initialValue: _situacao,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.flag_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'NORMAL', child: Text('A Pagar')),
              DropdownMenuItem(value: 'PAGAS', child: Text('Pagas')),
            ],
            onChanged: (v) {
              setState(() {
                _situacao = v;
                _tipoDataFiltro = 'vencimento';
                if (v != 'PAGAS') { _dataBaixaInicio = null; _dataBaixaFim = null; }
              });
              _carregar();
            },
          ),
          const SizedBox(height: 8),

          // ── Tipo de data (só quando Pagas) ─────────────────────────────────
          if (_mostrandoPagas) ...[
            Row(children: [
              const Text('Filtrar por:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Vencimento',
                selecionado: _tipoDataFiltro == 'vencimento',
                onTap: () { setState(() => _tipoDataFiltro = 'vencimento'); _carregar(); },
              ),
              const SizedBox(width: 6),
              _ToggleChip(
                label: 'Pagamento',
                selecionado: _tipoDataFiltro == 'baixa',
                onTap: () { setState(() => _tipoDataFiltro = 'baixa'); _carregar(); },
              ),
            ]),
            const SizedBox(height: 8),
          ],

          // ── Período ────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _selecionarPeriodo(baixa: _mostrandoPagas && _tipoDataFiltro == 'baixa'),
            child: _CampoFiltroData(
              label: _mostrandoPagas && _tipoDataFiltro == 'baixa' ? 'Período de Pagamento' : 'Período de Vencimento',
              icone: _mostrandoPagas && _tipoDataFiltro == 'baixa' ? Icons.check_circle_outline : Icons.date_range,
              cor: _mostrandoPagas && _tipoDataFiltro == 'baixa' ? Colors.green : AppTheme.primary,
              texto: () {
                if (_mostrandoPagas && _tipoDataFiltro == 'baixa') {
                  final ini = _dataBaixaInicio ?? _dataInicio;
                  final fim = _dataBaixaFim ?? _dataFim;
                  return '${_fmtData.format(ini)} — ${_fmtData.format(fim)}';
                }
                return '${_fmtData.format(_dataInicio)} — ${_fmtData.format(_dataFim)}';
              }(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Busca ──────────────────────────────────────────────────────────
          TextField(
            controller: _buscaCtrl,
            onChanged: _aplicarBusca,
            decoration: InputDecoration(
              hintText: 'Buscar por fornecedor ou documento...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: _buscaCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _buscaCtrl.clear(); _aplicarBusca(''); })
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // ── Plano + Centro ─────────────────────────────────────────────────
          Row(children: [
            if (_planosContas.isNotEmpty)
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _planoContas?.pkChave,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Plano de Contas', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ..._planosContas.map((p) => DropdownMenuItem(value: p.pkChave, child: Text(p.nome, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { setState(() => _planoContas = v != null ? _planosContas.firstWhere((p) => p.pkChave == v) : null); _carregar(); },
                ),
              ),
            const SizedBox(width: 8),
            if (_centrosCustos.isNotEmpty)
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _centroCustos?.pkChave,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Centro Custo', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ..._centrosCustos.map((c) => DropdownMenuItem(value: c.pkChave, child: Text(c.nome, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { setState(() => _centroCustos = v != null ? _centrosCustos.firstWhere((c) => c.pkChave == v) : null); _carregar(); },
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildResumo(ResumoContasPagar r) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: _mostrandoPagas
          ? Row(children: [
              _ResumoChip(label: 'Total Pago', valor: _fmt.format(r.totalPago), cor: Colors.green),
              const SizedBox(width: 10),
              _ResumoChip(label: 'Juros/Multa', valor: _fmt.format(r.totalJurosMulta), cor: Colors.orange),
              const SizedBox(width: 10),
              _ResumoChip(label: 'Desconto', valor: _fmt.format(r.totalDesconto), cor: Colors.blue),
              const Spacer(),
              Text('${r.titulosPagos} títulos', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ])
          : Row(children: [
              _ResumoChip(label: 'Vencido', valor: _fmt.format(r.totalVencido), cor: Colors.red),
              const SizedBox(width: 10),
              _ResumoChip(label: 'A vencer', valor: _fmt.format(r.totalAVencer), cor: Colors.orange),
              const SizedBox(width: 10),
              _ResumoChip(label: 'Total', valor: _fmt.format(r.total), cor: AppTheme.primary),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                Text('${r.titulosPendentes} a pagar', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                if (r.titulosPagos > 0) Text('${r.titulosPagos} pagos', style: const TextStyle(fontSize: 11, color: Colors.green)),
              ]),
            ]),
    );
  }
}

// ── Widgets de apoio ──────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selecionado ? Colors.white : AppTheme.primary, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _CampoFiltroData extends StatelessWidget {
  final String label;
  final String texto;
  final IconData icone;
  final Color? cor;
  const _CampoFiltroData({required this.label, required this.texto, required this.icone, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? AppTheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icone, size: 16, color: c),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 10, color: c)),
          Text(texto, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
        ])),
        Icon(Icons.edit_calendar, size: 14, color: c),
      ]),
    );
  }
}

class _ResumoChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _ResumoChip({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
      Text(valor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor)),
    ]);
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _CardContaPagar extends StatelessWidget {
  final ContaPagar conta;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;
  const _CardContaPagar({required this.conta, required this.fmt, required this.fmtData, required this.onTap});

  Color get _corStatus {
    if (conta.pago) return Colors.green;
    if (conta.vencido) return Colors.red;
    final diff = conta.dataVencimento.difference(DateTime.now()).inDays;
    if (diff <= 2) return Colors.orange;
    return AppTheme.primary;
  }

  String get _labelStatus {
    if (conta.pago) return 'Pago';
    if (conta.vencido) return 'Vencido';
    final diff = conta.dataVencimento.difference(DateTime.now()).inDays;
    if (diff == 0) return 'Vence hoje';
    if (diff == 1) return 'Vence amanhã';
    return 'A Pagar';
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corStatus;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: fornecedor + badge
              Row(children: [
                Expanded(child: Text(conta.pessoaNome ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(_labelStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
                ),
              ]),
              const SizedBox(height: 4),

              // Linha 2: datas
              Row(children: [
                Icon(Icons.calendar_today, size: 12, color: cor),
                const SizedBox(width: 4),
                Text('Venc: ${fmtData.format(conta.dataVencimento)}',
                    style: TextStyle(fontSize: 12, color: cor)),
                if (conta.pago && conta.dataBaixa != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                  const SizedBox(width: 2),
                  Text('Pago: ${fmtData.format(conta.dataBaixa!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ]),
              const SizedBox(height: 4),

              // Linha 3: doc/parc (esquerda) + valor (direita)
              Row(children: [
                Expanded(
                  child: Text(
                    conta.documento?.isNotEmpty == true
                        ? 'Doc: ${conta.documento}  Parc: ${conta.parcela}'
                        : 'Parcela: ${conta.parcela}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Valor: original riscado + pago (se houve ajuste)
                if (conta.pago && conta.temAjustes) ...[
                  Text(fmt.format(conta.valorOriginal),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 4),
                  Text(fmt.format(conta.valorPago),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                ] else
                  Text(fmt.format(conta.valorOriginal),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                          color: conta.pago ? Colors.green : AppTheme.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              ]),

              // Linha 4: plano/centro (opcional)
              if (conta.planoContasNome != null || conta.centroCustosNome != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [if (conta.planoContasNome != null) conta.planoContasNome!,
                     if (conta.centroCustosNome != null) conta.centroCustosNome!].join('  ·  '),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detalhe ───────────────────────────────────────────────────────────────────

class _DetalheSheet extends StatelessWidget {
  final ContaPagar conta;
  final NumberFormat fmt;
  final DateFormat fmtData;
  const _DetalheSheet({required this.conta, required this.fmt, required this.fmtData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(conta.pessoaNome ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                if (conta.pago && conta.temAjustes)
                  Text(fmt.format(conta.valorOriginal),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted,
                          decoration: TextDecoration.lineThrough)),
                Text(fmt.format(conta.pago ? conta.valorPago : conta.valorOriginal),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                        color: conta.pago ? Colors.green : AppTheme.primary)),
              ]),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _InfoRow('Título', '#${conta.pkChave}'),
                _InfoRow('Parcela', conta.parcela),
                if (conta.documento?.isNotEmpty == true) _InfoRow('Documento', conta.documento!),
                _InfoRow('Vencimento', fmtData.format(conta.dataVencimento)),
                _InfoRow('Emissão', fmtData.format(conta.dataOperacao)),
                _InfoRow('Status', conta.pago ? 'Pago' : conta.vencido ? 'Vencido' : 'A Pagar'),

                // Breakdown de pagamento (sempre visível quando pago)
                if (conta.pago) ...[
                  const SizedBox(height: 4),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text('Detalhes do Pagamento',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  _InfoRow('Valor Original', fmt.format(conta.valorOriginal)),
                  _InfoRow('Juros', conta.juros != 0 ? fmt.format(conta.juros) : '—'),
                  _InfoRow('Multa', conta.multa != 0 ? fmt.format(conta.multa) : '—'),
                  _InfoRow('Adicional', conta.adicional != 0 ? fmt.format(conta.adicional) : '—'),
                  _InfoRow('Desconto', conta.desconto != 0 ? '- ${fmt.format(conta.desconto)}' : '—'),
                  _InfoRow('Valor Pago', fmt.format(conta.valorPago), destaque: true),
                  if (conta.dataBaixa != null)
                    _InfoRow('Data Pgto', fmtData.format(conta.dataBaixa!)),
                  const Divider(),
                ],

                if (conta.tipoPagamento != null) _InfoRow('Forma Pgto', conta.tipoPagamento!),
                if (conta.planoContasNome != null) _InfoRow('Plano Contas', conta.planoContasNome!),
                if (conta.centroCustosNome != null) _InfoRow('Centro Custo', conta.centroCustosNome!),
                if (conta.observacoes?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  const Text('Observações',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(conta.observacoes!, style: const TextStyle(fontSize: 13)),
                ],
              ],
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
  final bool destaque;
  const _InfoRow(this.label, this.valor, {this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
        Expanded(child: Text(valor, style: TextStyle(
          fontSize: destaque ? 14 : 13,
          fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
          color: destaque ? Colors.green : AppTheme.textDark,
        ))),
      ]),
    );
  }
}
