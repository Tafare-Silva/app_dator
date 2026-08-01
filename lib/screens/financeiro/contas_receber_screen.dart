import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../models/financeiro_model.dart';
import '../../models/cliente_model.dart';
import '../../services/financeiro_service.dart';
import '../../services/cliente_service.dart';
import '../../services/financeiro_pdf_service.dart';

class ContasReceberScreen extends StatefulWidget {
  final VoidCallback? onAbrirMenu;
  const ContasReceberScreen({super.key, this.onAbrirMenu});

  @override
  State<ContasReceberScreen> createState() => _ContasReceberScreenState();
}

class _ContasReceberScreenState extends State<ContasReceberScreen> {
  final _service = FinanceiroService();
  final _clienteService = ClienteService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  // Período (vencimento)
  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  // Período (baixa)
  DateTime? _dataBaixaInicio;
  DateTime? _dataBaixaFim;

  Cliente? _clienteSelecionado;
  FiltroItem? _planoContas;
  FiltroItem? _centroCustos;
  String? _situacao = 'NORMAL';
  bool _considerarTudo = false;

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

  bool get _mostrandoRecebidos => _situacao == 'PAGAS';

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

  // ── Resumo calculado localmente ──────────────────
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
      final useVencimento = (!_mostrandoRecebidos || _tipoDataFiltro == 'vencimento') && !_considerarTudo;
      final useBaixa = _mostrandoRecebidos && _tipoDataFiltro == 'baixa' && !_considerarTudo;

      final lista = await _service.listarContasReceber(
        dataInicio: useVencimento ? _dataInicio : null,
        dataFim: useVencimento ? _dataFim : null,
        dataBaixaInicio: useBaixa ? (_dataBaixaInicio ?? _dataInicio) : null,
        dataBaixaFim: useBaixa ? (_dataBaixaFim ?? _dataFim) : null,
        pessoaId: _clienteSelecionado?.pkChave,
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
      _clienteSelecionado = null;
      _planoContas = null;
      _centroCustos = null;
      _situacao = 'NORMAL';
      _tipoDataFiltro = 'vencimento';
      _buscaCtrl.clear();
    });
    _carregar();
  }

  Future<void> _selecionarPeriodo({bool baixa = false}) async {
    final inicio = baixa ? (_dataBaixaInicio ?? _dataInicio) : _dataInicio;
    final fim = baixa ? (_dataBaixaFim ?? _dataFim) : _dataFim;

    final result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: inicio, end: fim),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
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

  Future<void> _buscarCliente() async {
    final cliente = await showDialog<Cliente>(
      context: context,
      builder: (_) => _BuscaClienteDialog(service: _clienteService),
    );
    if (cliente != null) {
      setState(() => _clienteSelecionado = cliente);
      _carregar();
    }
  }

  void _abrirDetalhe(ContaPagar c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalheSheet(conta: c, fmt: _fmt, fmtData: _fmtData),
    );
  }

  void _gerarPdf() {
    if (_filtrados.isEmpty) return;
    final nome = _clienteSelecionado?.nome ?? "Diversos";
    FinanceiroPdfService.gerarRelatorioAberto(nome, _filtrados, cliente: _clienteSelecionado);
  }

  void _cobrarVencidos() {
    final vencidos = _filtrados.where((t) => !t.pago && t.vencido).toList();
    if (vencidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum título vencido para cobrar.')));
      return;
    }

    final total = vencidos.fold(0.0, (acc, t) => acc + t.valorOriginal);
    final titulosStr = vencidos.map((t) => '• Venc: ${_fmtData.format(t.dataVencimento)} - Doc: ${t.documento ?? "S/N"} - ${_fmt.format(t.valorOriginal)}').join('\n');

    final msg = '''
*Cobrança - ${_clienteSelecionado?.nome ?? vencidos.first.pessoaNome}*
Olá, notamos que existem títulos vencidos em seu nome que totalizam *${_fmt.format(total)}*.

*Títulos:*
$titulosStr

Por favor, entre em contato para regularização.
''';
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _filtrados.isEmpty && !_carregando ? null : (_carregando ? null : _resumoLocal);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Contas a Receber'),
        leading: widget.onAbrirMenu != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu)
            : null,
        actions: [
          IconButton(
            icon: Icon(_filtrosExpandidos ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _filtrosExpandidos = !_filtrosExpandidos),
          ),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: _limparFiltros),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _filtrosExpandidos ? _buildFiltros() : const SizedBox.shrink(),
          ),
          if (resumo != null) _buildResumo(resumo),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(child: Text(_erro!))
                    : _filtrados.isEmpty
                        ? const Center(child: Text('Nenhum título encontrado.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) => _CardContaReceber(
                              conta: _filtrados[i],
                              fmt: _fmt,
                              fmtData: _fmtData,
                              onTap: () => _abrirDetalhe(_filtrados[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _situacao == 'NORMAL' && _filtrados.isNotEmpty ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'pdf',
            onPressed: _gerarPdf,
            backgroundColor: Colors.red,
            child: const Icon(Icons.picture_as_pdf, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'whatsapp',
            onPressed: _cobrarVencidos,
            backgroundColor: Colors.green,
            child: const Icon(Icons.message, color: Colors.white),
          ),
        ],
      ) : null,
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _situacao,
            decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'NORMAL', child: Text('A Receber')),
              DropdownMenuItem(value: 'PAGAS', child: Text('Recebidos')),
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
          // --- Busca de Cliente (igual à pré-venda) ---
          InkWell(
            onTap: _buscarCliente,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_clienteSelecionado?.nome ?? 'Filtrar por Cliente...', style: TextStyle(color: _clienteSelecionado != null ? AppTheme.textDark : AppTheme.textMuted, fontSize: 14))),
                  if (_clienteSelecionado != null) IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () { setState(() => _clienteSelecionado = null); _carregar(); },
                  ),
                  const Icon(Icons.search, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          if (_clienteSelecionado != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Text('Considerar todo o período:', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Switch.adaptive(
                value: _considerarTudo,
                activeColor: AppTheme.primary,
                onChanged: (v) { setState(() => _considerarTudo = v); _carregar(); },
              ),
            ]),
          ],
          const SizedBox(height: 8),
          if (_mostrandoRecebidos) ...[
            Row(children: [
              const Text('Filtrar por:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Vencimento',
                selecionado: _tipoDataFiltro == 'vencimento',
                onTap: () { setState(() => _tipoDataFiltro = 'vencimento'); _carregar(); },
              ),
              const SizedBox(width: 6),
              _ToggleChip(
                label: 'Recebimento',
                selecionado: _tipoDataFiltro == 'baixa',
                onTap: () { setState(() => _tipoDataFiltro = 'baixa'); _carregar(); },
              ),
            ]),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: () => _selecionarPeriodo(baixa: _mostrandoRecebidos && _tipoDataFiltro == 'baixa'),
            child: _CampoFiltroData(
              label: _mostrandoRecebidos && _tipoDataFiltro == 'baixa' ? 'Período de Recebimento' : 'Período de Vencimento',
              texto: () {
                if (_mostrandoRecebidos && _tipoDataFiltro == 'baixa') {
                  final ini = _dataBaixaInicio ?? _dataInicio;
                  final fim = _dataBaixaFim ?? _dataFim;
                  return '${_fmtData.format(ini)} — ${_fmtData.format(fim)}';
                }
                return '${_fmtData.format(_dataInicio)} — ${_fmtData.format(_dataFim)}';
              }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo(ResumoContasPagar r) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: _mostrandoRecebidos
          ? Row(children: [
              _ResumoChip(label: 'Recebido', valor: _fmt.format(r.totalPago), cor: Colors.green),
              const Spacer(),
              Text('${r.titulosPagos} títulos', style: const TextStyle(fontSize: 11)),
            ])
          : Row(children: [
              _ResumoChip(label: 'Vencido', valor: _fmt.format(r.totalVencido), cor: Colors.red),
              const SizedBox(width: 10),
              _ResumoChip(label: 'A receber', valor: _fmt.format(r.totalAVencer), cor: Colors.orange),
              const Spacer(),
              Text('${r.titulosPendentes} a receber', style: const TextStyle(fontSize: 11, color: Colors.orange)),
            ]),
    );
  }
}

class _BuscaClienteDialog extends StatefulWidget {
  final ClienteService service;
  const _BuscaClienteDialog({required this.service});

  @override
  State<_BuscaClienteDialog> createState() => _BuscaClienteDialogState();
}

class _BuscaClienteDialogState extends State<_BuscaClienteDialog> {
  final _ctrl = TextEditingController();
  List<Cliente> _resultados = [];
  bool _buscando = false;
  Timer? _debounce;

  void _buscar(String termo) {
    _debounce?.cancel();
    if (termo.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _buscando = true);
      try {
        final r = await widget.service.buscarClientes(termo);
        if (mounted) setState(() => _resultados = r);
      } finally {
        if (mounted) setState(() => _buscando = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Buscar Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl, autofocus: true,
              decoration: InputDecoration(hintText: 'Nome do cliente...', prefixIcon: const Icon(Icons.search), 
                suffixIcon: _buscando ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null),
              onChanged: _buscar,
            ),
            const SizedBox(height: 8),
            Flexible(child: ListView.builder(
              shrinkWrap: true,
              itemCount: _resultados.length,
              itemBuilder: (_, i) {
                final c = _resultados[i];
                return ListTile(
                  dense: true, leading: const Icon(Icons.person_outline), title: Text(c.nome),
                  subtitle: Text(c.cnpjCpf ?? ''), onTap: () => Navigator.pop(context, c),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

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
        child: Text(label, style: TextStyle(fontSize: 12, color: selecionado ? Colors.white : AppTheme.primary)),
      ),
    );
  }
}

class _CampoFiltroData extends StatelessWidget {
  final String label;
  final String texto;
  const _CampoFiltroData({required this.label, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.primary)),
        Text(texto, style: const TextStyle(fontSize: 12)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.bold)),
      Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cor)),
    ]);
  }
}

class _CardContaReceber extends StatelessWidget {
  final ContaPagar conta;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;
  const _CardContaReceber({required this.conta, required this.fmt, required this.fmtData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = conta.pago ? Colors.green : (conta.vencido ? Colors.red : AppTheme.primary);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(conta.pessoaNome ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(fmt.format(conta.valorOriginal), style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Text('Doc: ${conta.documento ?? "S/N"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const Spacer(),
                Text('Emissão: ${fmtData.format(conta.dataOperacao)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today, size: 12, color: cor),
                const SizedBox(width: 4),
                Text('Venc: ${fmtData.format(conta.dataVencimento)}', style: TextStyle(fontSize: 12, color: cor)),
                const Spacer(),
                Text(conta.pago ? 'Recebido' : (conta.vencido ? 'Vencido' : 'A Receber'), style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheSheet extends StatelessWidget {
  final ContaPagar conta;
  final NumberFormat fmt;
  final DateFormat fmtData;
  const _DetalheSheet({required this.conta, required this.fmt, required this.fmtData});

  void _compartilharWhatsApp() {
    final msg = '''
*Cobrança - ${conta.pessoaNome}*
Olá, informamos que consta em nosso sistema um título com vencimento em ${fmtData.format(conta.dataVencimento)}.
Valor: ${fmt.format(conta.valorOriginal)}
Documento: ${conta.documento ?? '—'}
Parcela: ${conta.parcela}
''';
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Detalhes do Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            if (!conta.pago) IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: _compartilharWhatsApp,
              tooltip: 'Compartilhar',
            ),
          ]),
          const Divider(),
          _Info('Cliente', conta.pessoaNome ?? '—'),
          _Info('Valor', fmt.format(conta.valorOriginal)),
          _Info('Vencimento', fmtData.format(conta.dataVencimento)),
          _Info('Emissão', fmtData.format(conta.dataOperacao)),
          _Info('Documento', conta.documento ?? '—'),
          _Info('Parcela', conta.parcela),
          _Info('Status', conta.pago ? 'Recebido' : (conta.vencido ? 'Vencido' : 'A Receber')),
          if (conta.observacoes?.isNotEmpty == true) _Info('Observações', conta.observacoes!),
          if (!conta.pago) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Enviar via WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _compartilharWhatsApp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String valor;
  const _Info(this.label, this.valor);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(valor, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
