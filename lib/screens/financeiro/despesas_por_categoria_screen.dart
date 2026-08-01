import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/financeiro_model.dart';
import '../../services/financeiro_service.dart';
import 'financeiro_drilldown_widgets.dart';

class DespesasPorCategoriaScreen extends StatefulWidget {
  final VoidCallback? onAbrirMenu;
  const DespesasPorCategoriaScreen({super.key, this.onAbrirMenu});

  @override
  State<DespesasPorCategoriaScreen> createState() => _DespesasPorCategoriaScreenState();
}

class _DespesasPorCategoriaScreenState extends State<DespesasPorCategoriaScreen> {
  final _service = FinanceiroService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  bool _porCentroCusto = false;
  bool _totalExpandido = true;

  // 'PAGAS' = despesas já efetivadas (baixadas) — dinheiro que realmente saiu.
  // 'NORMAL' = previsão de despesa — títulos lançados mas ainda em aberto no Contas a Pagar.
  String _situacao = 'PAGAS';

  late Future<List<GrupoFinanceiro>> _futuroGrupos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuroGrupos = _porCentroCusto
        ? _service.despesasPorCentroCusto(dataInicio: _dataInicio, dataFim: _dataFim, situacao: _situacao)
        : _service.despesasPorPlanoContas(dataInicio: _dataInicio, dataFim: _dataFim, situacao: _situacao);
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

  Future<List<ContaPagar>> _carregarTitulosDoGrupo(GrupoFinanceiro grupo) {
    return _service.listarContasPagar(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      planoContasId: _porCentroCusto ? null : grupo.id,
      centroCustosId: _porCentroCusto ? grupo.id : null,
      situacao: _situacao,
      limit: 200,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Despesas por Categoria'),
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
            _buildToggleSituacao(),
            const SizedBox(height: 10),
            _buildToggleAgrupamento(),
            const SizedBox(height: 16),
            FutureBuilder<List<GrupoFinanceiro>>(
              future: _futuroGrupos,
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
                        const Text('Erro ao carregar despesas.', style: TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  );
                }
                final grupos = snap.data ?? [];
                final totalGeral = grupos.fold(0.0, (s, g) => s + g.total);

                if (grupos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Nenhuma despesa no período.', style: TextStyle(color: AppTheme.textMuted))),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GrupoPieChart(grupos: grupos, totalGeral: totalGeral),
                    const SizedBox(height: 16),
                    GrandTotalCard(
                      titulo: _situacao == 'PAGAS' ? 'Total de Despesas Efetivadas' : 'Previsão de Despesas (a pagar)',
                      total: totalGeral,
                      quantidadeGrupos: grupos.length,
                      fmt: _fmt,
                      cor: _situacao == 'PAGAS' ? AppTheme.error : Colors.orange,
                      icone: _situacao == 'PAGAS' ? Icons.arrow_upward_rounded : Icons.pending_actions,
                      expandido: _totalExpandido,
                      onToggle: () => setState(() => _totalExpandido = !_totalExpandido),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _totalExpandido
                          ? Column(
                              children: [
                                for (final grupo in grupos)
                                  GrupoExpansivelCard(
                                    grupo: grupo,
                                    totalGeral: totalGeral,
                                    cor: paletaGruposFinanceiros[
                                        grupos.indexOf(grupo) % paletaGruposFinanceiros.length],
                                    fmt: _fmt,
                                    carregarTitulos: () => _carregarTitulosDoGrupo(grupo),
                                  ),
                              ],
                            )
                          : const SizedBox(width: double.infinity),
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

  Widget _buildToggleSituacao() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        const Text('Considerar:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        _ToggleChip(
          label: 'Efetivadas (pagas)',
          selecionado: _situacao == 'PAGAS',
          onTap: () {
            setState(() => _situacao = 'PAGAS');
            _carregar();
          },
        ),
        _ToggleChip(
          label: 'Previsão (a pagar)',
          selecionado: _situacao == 'NORMAL',
          onTap: () {
            setState(() => _situacao = 'NORMAL');
            _carregar();
          },
        ),
      ],
    );
  }

  Widget _buildToggleAgrupamento() {
    return Row(
      children: [
        Expanded(
          child: _SegmentoAgrupamento(
            label: 'Plano de Contas',
            icone: Icons.account_tree_outlined,
            selecionado: !_porCentroCusto,
            onTap: () {
              setState(() => _porCentroCusto = false);
              _carregar();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SegmentoAgrupamento(
            label: 'Centro de Custos',
            icone: Icons.store_outlined,
            selecionado: _porCentroCusto,
            onTap: () {
              setState(() => _porCentroCusto = true);
              _carregar();
            },
          ),
        ),
      ],
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

class _SegmentoAgrupamento extends StatelessWidget {
  final String label;
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;

  const _SegmentoAgrupamento({
    required this.label,
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? AppTheme.primary : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: selecionado ? Colors.white : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selecionado ? Colors.white : AppTheme.textMuted)),
          ],
        ),
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
