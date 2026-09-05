import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendas_models.dart';
import '../../services/vendas_service.dart';
import '../../core/app_theme.dart';

/// Soma o dashboard das 3 lojas -- pensada como tela separada (não um toggle
/// dentro do Dashboard normal) de propósito, pra não arriscar mexer numa tela
/// já bastante testada. Só consulta -- reaproveita os mesmos números que já
/// aparecem no dashboard de cada loja individual, só que somados/lado a lado.
class DashboardConsolidadoScreen extends StatefulWidget {
  const DashboardConsolidadoScreen({super.key});

  @override
  State<DashboardConsolidadoScreen> createState() => _DashboardConsolidadoScreenState();
}

class _DashboardConsolidadoScreenState extends State<DashboardConsolidadoScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  late Future<DashboardConsolidado> _futuro;

  DateTime _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dataFim = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuro = _service.getDashboardConsolidado(dataInicio: _dataInicio, dataFim: _dataFim);
    setState(() {});
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _dataInicio = range.start;
        _dataFim = range.end;
      });
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Dashboard Consolidado')),
      body: FutureBuilder<DashboardConsolidado>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text('Erro ao carregar dashboard consolidado',
                        style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _carregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final d = snap.data!;
          final lojasOrdenadas = [...d.porLoja]
            ..sort((a, b) => b.dados.totalVendas.compareTo(a.dados.totalVendas));

          return RefreshIndicator(
            onRefresh: () async => _carregar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChipPeriodoConsolidado(
                  inicio: _dataInicio,
                  fim: _dataFim,
                  fmt: _fmtData,
                  onTap: _selecionarPeriodo,
                ),
                const SizedBox(height: 16),
                const Text('🏬 Total (3 lojas)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CardTotal(
                        titulo: 'Vendas no período',
                        valor: _fmt.format(d.totalVendas),
                        icone: Icons.attach_money,
                        cor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardTotal(
                        titulo: 'Pedidos',
                        valor: '${d.quantidadePedidos}',
                        icone: Icons.receipt_long,
                        cor: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CardTotal(
                  titulo: 'Vendas hoje',
                  valor: '${_fmt.format(d.totalVendasHoje)} · ${d.quantidadePedidosHoje} pedido(s)',
                  icone: Icons.today,
                  cor: Colors.green,
                  larguraTotal: true,
                ),
                const SizedBox(height: 24),
                const Text('📊 Comparativo por loja',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                ...lojasOrdenadas.map((loja) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CardLoja(loja: loja, fmt: _fmt),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChipPeriodoConsolidado extends StatelessWidget {
  final DateTime inicio;
  final DateTime fim;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _ChipPeriodoConsolidado({
    required this.inicio,
    required this.fim,
    required this.fmt,
    required this.onTap,
  });

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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${fmt.format(inicio)} até ${fmt.format(fim)}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _CardTotal extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final bool larguraTotal;

  const _CardTotal({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.larguraTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: cor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(valor,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardLoja extends StatelessWidget {
  final DashboardPorLoja loja;
  final NumberFormat fmt;

  const _CardLoja({required this.loja, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (loja.erro != null) {
      return Card(
        color: AppTheme.error.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loja.empresaNome,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const Text('Não foi possível carregar esta loja agora.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loja.empresaNome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MetricaLoja(rotulo: 'Vendas', valor: fmt.format(loja.dados.totalVendas))),
                Expanded(child: _MetricaLoja(rotulo: 'Pedidos', valor: '${loja.dados.quantidadePedidos}')),
                Expanded(child: _MetricaLoja(rotulo: 'Ticket médio', valor: fmt.format(loja.dados.ticketMedio))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricaLoja extends StatelessWidget {
  final String rotulo;
  final String valor;
  const _MetricaLoja({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
      ],
    );
  }
}
