import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/financeiro_model.dart';
import '../../services/financeiro_service.dart';
import 'financeiro_drilldown_widgets.dart';

class ApuracaoResultadoScreen extends StatefulWidget {
  final VoidCallback? onAbrirMenu;
  const ApuracaoResultadoScreen({super.key, this.onAbrirMenu});

  @override
  State<ApuracaoResultadoScreen> createState() => _ApuracaoResultadoScreenState();
}

class _ApuracaoResultadoScreenState extends State<ApuracaoResultadoScreen> {
  final _service = FinanceiroService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  // 'baixa' = regime de caixa (pagamento/recebimento efetivo) — padrão, é o que
  // reflete o que realmente entrou/saiu do caixa. 'vencimento' = competência.
  String _tipoData = 'baixa';

  bool _lenteVendido = false; // false = Recebido (caixa), true = Vendido (faturamento)

  bool _despesasExpandido = false;
  bool _receitasExpandido = false;

  late Future<ApuracaoResultado> _futuroDre;
  late Future<List<GrupoFinanceiro>> _futuroDespesas;
  late Future<List<GrupoFinanceiro>> _futuroReceitas;
  late Future<VendidoRecebido> _futuroVendidoRecebido;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final porBaixa = _tipoData == 'baixa';
    _futuroDre = _service.getApuracaoResultado(
      dataInicio: porBaixa ? null : _dataInicio,
      dataFim: porBaixa ? null : _dataFim,
      dataBaixaInicio: porBaixa ? _dataInicio : null,
      dataBaixaFim: porBaixa ? _dataFim : null,
    );
    _futuroDespesas = _service.despesasPorPlanoContas(
      dataInicio: porBaixa ? null : _dataInicio,
      dataFim: porBaixa ? null : _dataFim,
      dataBaixaInicio: porBaixa ? _dataInicio : null,
      dataBaixaFim: porBaixa ? _dataFim : null,
    );
    _futuroReceitas = _service.receitasPorPlanoContas(
      dataInicio: porBaixa ? null : _dataInicio,
      dataFim: porBaixa ? null : _dataFim,
      dataBaixaInicio: porBaixa ? _dataInicio : null,
      dataBaixaFim: porBaixa ? _dataFim : null,
    );
    _futuroVendidoRecebido = _service.getVendidoVsRecebido(dataInicio: _dataInicio, dataFim: _dataFim);
    setState(() {});
  }

  Future<void> _selecionarPeriodo() async {
    final result = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (result == null) return;
    _dataInicio = result.start;
    _dataFim = result.end;
    _carregar();
  }

  Future<List<ContaPagar>> _carregarTitulosDespesa(GrupoFinanceiro grupo) {
    final porBaixa = _tipoData == 'baixa';
    return _service.listarContasPagar(
      dataInicio: porBaixa ? null : _dataInicio,
      dataFim: porBaixa ? null : _dataFim,
      dataBaixaInicio: porBaixa ? _dataInicio : null,
      dataBaixaFim: porBaixa ? _dataFim : null,
      planoContasId: grupo.id,
      limit: 200,
    );
  }

  Future<List<ContaPagar>> _carregarTitulosReceita(GrupoFinanceiro grupo) {
    final porBaixa = _tipoData == 'baixa';
    return _service.listarContasReceber(
      dataInicio: porBaixa ? null : _dataInicio,
      dataFim: porBaixa ? null : _dataFim,
      dataBaixaInicio: porBaixa ? _dataInicio : null,
      dataBaixaFim: porBaixa ? _dataFim : null,
      planoContasId: grupo.id,
      limit: 200,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Apuração de Resultados'),
        leading: widget.onAbrirMenu != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu)
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _selecionarPeriodo),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ChipPeriodo(inicio: _dataInicio, fim: _dataFim, fmt: _fmtData, onTap: _selecionarPeriodo),
            const SizedBox(height: 12),
            _buildToggleTipoData(),
            const SizedBox(height: 16),
            FutureBuilder<ApuracaoResultado>(
              future: _futuroDre,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const Text('Erro ao carregar apuração.', style: TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  );
                }
                final dre = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardsIndicador(dre),
                    const SizedBox(height: 16),
                    _buildGraficoResumo(dre),
                    const SizedBox(height: 16),
                    _buildCardVendidoRecebido(),
                    const SizedBox(height: 20),
                    _buildSecao(
                      titulo: 'Despesas por Plano de Contas',
                      cor: AppTheme.error,
                      icone: Icons.arrow_upward_rounded,
                      futuro: _futuroDespesas,
                      expandido: _despesasExpandido,
                      onToggle: () => setState(() => _despesasExpandido = !_despesasExpandido),
                      carregarTitulos: _carregarTitulosDespesa,
                    ),
                    const SizedBox(height: 12),
                    _buildSecao(
                      titulo: 'Receitas por Plano de Contas',
                      cor: Colors.green,
                      icone: Icons.arrow_downward_rounded,
                      futuro: _futuroReceitas,
                      expandido: _receitasExpandido,
                      onToggle: () => setState(() => _receitasExpandido = !_receitasExpandido),
                      carregarTitulos: _carregarTitulosReceita,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTipoData() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        const Text('Considerar por:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        _ToggleChip(
          label: 'Caixa (pagto/recebto)',
          selecionado: _tipoData == 'baixa',
          onTap: () {
            setState(() => _tipoData = 'baixa');
            _carregar();
          },
        ),
        _ToggleChip(
          label: 'Competência (vencto)',
          selecionado: _tipoData == 'vencimento',
          onTap: () {
            setState(() => _tipoData = 'vencimento');
            _carregar();
          },
        ),
      ],
    );
  }

  Widget _buildCardsIndicador(ApuracaoResultado dre) {
    return Row(
      children: [
        Expanded(
          child: _CardIndicador(
            titulo: 'Despesas',
            valor: _fmt.format(dre.totalDespesas),
            icone: Icons.arrow_upward,
            cor: AppTheme.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CardIndicador(
            titulo: 'Receitas (Recebido)',
            valor: _fmt.format(dre.totalReceitas),
            icone: Icons.arrow_downward,
            cor: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CardIndicador(
            titulo: 'Saldo',
            valor: _fmt.format(dre.saldo),
            icone: Icons.account_balance,
            cor: dre.saldo >= 0 ? AppTheme.primary : AppTheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoResumo(ApuracaoResultado dre) {
    final maxY = [dre.totalReceitas, dre.totalDespesas, dre.saldo.abs()]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const labels = ['Receitas', 'Despesas', 'Saldo'];
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[i], style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: dre.totalReceitas, color: Colors.green, width: 34, borderRadius: BorderRadius.circular(6)),
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: dre.totalDespesas, color: AppTheme.error, width: 34, borderRadius: BorderRadius.circular(6)),
                ]),
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(
                    toY: dre.saldo.abs(),
                    color: dre.saldo >= 0 ? AppTheme.primary : Colors.orange,
                    width: 34,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardVendidoRecebido() {
    return FutureBuilder<VendidoRecebido>(
      future: _futuroVendidoRecebido,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final vvr = snap.data!;
        final valorLente = _lenteVendido ? vvr.totalVendido : vvr.totalRecebido;

        return Card(
          color: Colors.blue.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.compare_arrows, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Vendido x Recebido',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleChip(
                        label: 'Vendido',
                        selecionado: _lenteVendido,
                        onTap: () => setState(() => _lenteVendido = true),
                        expandido: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleChip(
                        label: 'Recebido',
                        selecionado: !_lenteVendido,
                        onTap: () => setState(() => _lenteVendido = false),
                        expandido: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_fmt.format(valorLente),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _lenteVendido ? Colors.orange : Colors.green)),
                const SizedBox(height: 6),
                Text(
                  _lenteVendido
                      ? 'Total faturado no período (inclui vendas em crediário ainda não recebidas).'
                      : 'Total que efetivamente entrou no caixa no período (inclui recebimentos de crediário de vendas anteriores).',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                if (vvr.diferenca != 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    vvr.diferenca > 0
                        ? 'Diferença de ${_fmt.format(vvr.diferenca)} vendida ainda não recebida (crediário em aberto).'
                        : 'Recebido ${_fmt.format(-vvr.diferenca)} a mais do que foi vendido no período (recebimentos de vendas anteriores).',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecao({
    required String titulo,
    required Color cor,
    required IconData icone,
    required Future<List<GrupoFinanceiro>> futuro,
    required bool expandido,
    required VoidCallback onToggle,
    required Future<List<ContaPagar>> Function(GrupoFinanceiro) carregarTitulos,
  }) {
    return FutureBuilder<List<GrupoFinanceiro>>(
      future: futuro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final grupos = snap.data ?? [];
        final totalGeral = grupos.fold(0.0, (s, g) => s + g.total);
        if (grupos.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GrandTotalCard(
              titulo: titulo,
              total: totalGeral,
              quantidadeGrupos: grupos.length,
              fmt: _fmt,
              cor: cor,
              icone: icone,
              expandido: expandido,
              onToggle: onToggle,
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: expandido
                  ? Column(
                      children: [
                        for (final grupo in grupos)
                          GrupoExpansivelCard(
                            grupo: grupo,
                            totalGeral: totalGeral,
                            cor: paletaGruposFinanceiros[grupos.indexOf(grupo) % paletaGruposFinanceiros.length],
                            fmt: _fmt,
                            carregarTitulos: () => carregarTitulos(grupo),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}

class _CardIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _CardIndicador({required this.titulo, required this.valor, required this.icone, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 18),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(titulo, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cor), maxLines: 1),
            ),
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
  final bool expandido;

  const _ToggleChip({required this.label, required this.selecionado, required this.onTap, this.expandido = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expandido ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selecionado ? Colors.white : AppTheme.primary,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _ChipPeriodo extends StatelessWidget {
  final DateTime inicio;
  final DateTime fim;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _ChipPeriodo({required this.inicio, required this.fim, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text('${fmt.format(inicio)} — ${fmt.format(fim)}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.edit, color: AppTheme.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
