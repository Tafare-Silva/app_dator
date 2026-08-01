import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/vendas_models.dart';
import '../../../services/vendas_service.dart';
import '../../../core/app_theme.dart';

class DashboardVendasScreen extends StatefulWidget {
  final VoidCallback? onAbrirMenu;
  const DashboardVendasScreen({super.key, this.onAbrirMenu});

  @override
  State<DashboardVendasScreen> createState() => _DashboardVendasScreenState();
}

class _DashboardVendasScreenState extends State<DashboardVendasScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  late Future<DashboardVendas> _futuroDashboard;

  // ✅ Padrão: dia atual
  DateTime _dataInicio = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _dataFim = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // null = "Geral" (todas as seções somadas); caso contrário, nome da seção
  // selecionada (ex: "FEMININO", "KIDS", "Sem Seção").
  String? _secaoSelecionada;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuroDashboard = _service.getDashboard(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
    );
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
          colorScheme:
              const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      _dataInicio = range.start;
      _dataFim = range.end;
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        // ✅ Botão menu hamburguer abre o Drawer
        leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: widget.onAbrirMenu, // ✅ usa o callback do pai
      ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Selecionar período',
            onPressed: _selecionarPeriodo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: FutureBuilder<DashboardVendas>(
        future: _futuroDashboard,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text('Erro ao carregar dashboard',
                      style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _carregar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final d = snap.data!;
          // Se a seção selecionada não existe mais no período atual (ex:
          // trocou o período e não teve venda dessa seção), volta pra Geral.
          SecaoDashboard? secaoAtual;
          for (final s in d.secoes) {
            if (s.secao == _secaoSelecionada) {
              secaoAtual = s;
              break;
            }
          }
          final totalVendasView = secaoAtual?.totalVendas ?? d.totalVendas;
          final ticketMedioView = secaoAtual?.ticketMedio ?? d.ticketMedio;
          final quantidadePedidosView = secaoAtual?.quantidadePedidos ?? d.quantidadePedidos;
          final rankingView = secaoAtual?.rankingVendedores ?? d.rankingVendedores;

          return RefreshIndicator(
            onRefresh: () async => _carregar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChipPeriodo(
                  inicio: _dataInicio,
                  fim: _dataFim,
                  fmt: _fmtData,
                  onTap: _selecionarPeriodo,
                ),
                if (d.secoes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SeletorSecao(
                    secoes: d.secoes,
                    selecionada: _secaoSelecionada,
                    onSelecionar: (s) => setState(() => _secaoSelecionada = s),
                  ),
                ],
                const SizedBox(height: 16),
                const _SecaoTitulo(titulo: '📅 Hoje'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CardIndicador(
                        titulo: 'Vendas',
                        valor: _fmt.format(d.totalVendasHoje),
                        icone: Icons.attach_money,
                        cor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardIndicador(
                        titulo: 'Pedidos',
                        valor: d.quantidadePedidosHoje.toString(),
                        icone: Icons.receipt_long,
                        cor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SecaoTitulo(
                  titulo: '📊 ${_secaoSelecionada ?? "Geral"} — '
                      '${_fmtData.format(_dataInicio)} — ${_fmtData.format(_dataFim)}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CardIndicador(
                        titulo: 'Total',
                        valor: _fmt.format(totalVendasView),
                        icone: Icons.monetization_on,
                        cor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardIndicador(
                        titulo: 'Ticket Médio',
                        valor: _fmt.format(ticketMedioView),
                        icone: Icons.trending_up,
                        cor: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CardIndicador(
                  titulo: 'Total de Pedidos no Período',
                  valor: '$quantidadePedidosView pedidos',
                  icone: Icons.list_alt,
                  cor: Colors.purple,
                  larguraTotal: true,
                ),
                const SizedBox(height: 24),
                _SecaoTitulo(titulo: '🏆 Ranking de Vendedores — ${_secaoSelecionada ?? "Geral"}'),
                const SizedBox(height: 8),
                if (rankingView.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhuma venda no período.',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  )
                else
                  ...rankingView.asMap().entries.map(
                        (e) => _CardRanking(
                          posicao: e.key + 1,
                          ranking: e.value,
                          fmt: _fmt,
                          totalGeral: totalVendasView,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Widgets internos (mantidos do original) ───────────────────────────────────

class _ChipPeriodo extends StatelessWidget {
  final DateTime inicio;
  final DateTime fim;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _ChipPeriodo({
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${fmt.format(inicio)} até ${fmt.format(fim)}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: AppTheme.primary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SeletorSecao extends StatelessWidget {
  final List<SecaoDashboard> secoes;
  final String? selecionada;
  final ValueChanged<String?> onSelecionar;

  const _SeletorSecao({
    required this.secoes,
    required this.selecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Geral', selecionada == null, () => onSelecionar(null)),
          for (final s in secoes) ...[
            const SizedBox(width: 8),
            _chip(s.secao, selecionada == s.secao, () => onSelecionar(s.secao)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selecionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selecionado ? AppTheme.primary : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  const _SecaoTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(titulo,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark));
  }
}

class _CardIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final bool larguraTotal;

  const _CardIndicador({
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(titulo,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted),
                        maxLines: 1),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(valor,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                        maxLines: 1),
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

class _CardRanking extends StatelessWidget {
  final int posicao;
  final RankingVendedor ranking;
  final NumberFormat fmt;
  final double totalGeral;

  const _CardRanking({
    required this.posicao,
    required this.ranking,
    required this.fmt,
    required this.totalGeral,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalGeral > 0 ? ranking.totalVendas / totalGeral : 0.0;
    final medalhas = ['🥇', '🥈', '🥉'];
    final emoji =
        posicao <= 3 ? medalhas[posicao - 1] : '$posicao°';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(ranking.vendedorNome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textDark),
                        maxLines: 1),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(fmt.format(ranking.totalVendas),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primary),
                      maxLines: 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: AppTheme.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ranking.quantidadePedidos} pedidos',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
                Text('Ticket: ${fmt.format(ranking.ticketMedio)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}