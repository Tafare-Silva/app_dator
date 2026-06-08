import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/estatisticas_model.dart';
import '../../models/vendas_models.dart';
import '../../services/estatisticas_service.dart';
import '../../services/vendas_service.dart';
import '../../core/app_theme.dart';

class EstatisticasScreen extends StatefulWidget {
  final VoidCallback? onVoltarDashboard;
  final VoidCallback? onAbrirMenu;
  const EstatisticasScreen({super.key, this.onVoltarDashboard, this.onAbrirMenu});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen>
    with SingleTickerProviderStateMixin {
  final _service = EstatisticasService();
  final _vendasService = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  late TabController _tabController;

  DateTime? _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _dataFim = DateTime.now();

  int? _vendedorId;
  String? _marca;
  String? _divisao;
  String? _colecao;

  List<Vendedor> _vendedores = [];
  FiltrosEstatistica? _filtros;

  Future<List<ItemCurvaABC>>? _futuroABC;
  Future<List<ItemVendasGrupo>>? _futuroPorMarca;
  Future<List<ItemVendasGrupo>>? _futuroPorDivisao;
  Future<List<ItemVendasGrupo>>? _futuroPorColecao;
  Future<List<ItemVendasGrupo>>? _futuroPorGenero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _carregarAbaAtual();
    });
    _carregarInicial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarInicial() async {
    final vendedores = await _vendasService.listarVendedores();
    final filtros = await _service.getFiltros();
    setState(() {
      _vendedores = vendedores;
      _filtros = filtros;
    });
    _carregarAbaAtual();
  }

  void _carregarAbaAtual() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _futuroABC = _service.getCurvaABC(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao, colecao: _colecao);
        case 1:
          _futuroPorMarca = _service.getPorMarca(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, divisao: _divisao, colecao: _colecao);
        case 2:
          _futuroPorDivisao = _service.getPorDivisao(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, colecao: _colecao);
        case 3:
          _futuroPorColecao = _service.getPorColecao(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao);
        case 4:
          _futuroPorGenero = _service.getPorGenero(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao, colecao: _colecao);
      }
    });
  }

  void _carregarTudo() {
    setState(() {
      _futuroABC = _service.getCurvaABC(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao, colecao: _colecao);
      _futuroPorMarca = _service.getPorMarca(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, divisao: _divisao, colecao: _colecao);
      _futuroPorDivisao = _service.getPorDivisao(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, colecao: _colecao);
      _futuroPorColecao = _service.getPorColecao(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao);
      _futuroPorGenero = _service.getPorGenero(dataInicio: _dataInicio, dataFim: _dataFim, vendedorId: _vendedorId, marca: _marca, divisao: _divisao, colecao: _colecao);
    });
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (range != null) {
      _dataInicio = range.start;
      _dataFim = range.end;
      _carregarTudo();
    }
  }

  Future<void> _abrirFiltros() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltrosSheet(
        vendedores: _vendedores,
        filtros: _filtros,
        vendedorId: _vendedorId,
        marca: _marca,
        divisao: _divisao,
        colecao: _colecao,
        onAplicar: (vId, m, d, c) {
          setState(() { _vendedorId = vId; _marca = m; _divisao = d; _colecao = c; });
          _carregarTudo();
        },
      ),
    );
  }

  bool get _temFiltroAtivo => _vendedorId != null || _marca != null || _divisao != null || _colecao != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Estatísticas'),
        leading: widget.onVoltarDashboard != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onVoltarDashboard)
            : IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _selecionarPeriodo),
          IconButton(
            icon: Badge(isLabelVisible: _temFiltroAtivo, child: const Icon(Icons.filter_list)),
            onPressed: _abrirFiltros,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarTudo),
        ],
        // ✅ TabBar com cores bem visíveis sobre o fundo azul
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Curva ABC'),
            Tab(text: 'Marca'),
            Tab(text: 'Divisão'),
            Tab(text: 'Coleção'),
            Tab(text: 'Gênero'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chip do período + limpar filtros
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: _selecionarPeriodo,
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    _dataInicio != null && _dataFim != null
                        ? '${_fmtData.format(_dataInicio!)} — ${_fmtData.format(_dataFim!)}'
                        : 'Todo o período',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (_temFiltroAtivo)
                    GestureDetector(
                      onTap: () {
                        setState(() { _vendedorId = null; _marca = null; _divisao = null; _colecao = null; });
                        _carregarTudo();
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.filter_alt_off, size: 14, color: AppTheme.error),
                          SizedBox(width: 4),
                          Text('Limpar filtros', style: TextStyle(fontSize: 11, color: AppTheme.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AbaABC(futuro: _futuroABC, fmt: _fmt),
                _AbaGrupo(futuro: _futuroPorMarca, fmt: _fmt, cor: Colors.blue),
                _AbaGrupo(futuro: _futuroPorDivisao, fmt: _fmt, cor: Colors.purple),
                _AbaGrupo(futuro: _futuroPorColecao, fmt: _fmt, cor: Colors.teal),
                _AbaGrupo(futuro: _futuroPorGenero, fmt: _fmt, cor: Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aba Curva ABC ─────────────────────────────────────────────────────────────

class _AbaABC extends StatelessWidget {
  final Future<List<ItemCurvaABC>>? futuro;
  final NumberFormat fmt;
  const _AbaABC({required this.futuro, required this.fmt});

  Color _corCurva(String curva) {
    switch (curva) {
      case 'A': return Colors.green;
      case 'B': return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (futuro == null) return const Center(child: CircularProgressIndicator());
    return FutureBuilder<List<ItemCurvaABC>>(
      future: futuro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}', style: const TextStyle(color: AppTheme.textMuted)));
        }
        final lista = snap.data ?? [];
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhum dado no período.', style: TextStyle(color: AppTheme.textMuted)));
        }

        final totalA = lista.where((e) => e.curva == 'A').length;
        final totalB = lista.where((e) => e.curva == 'B').length;
        final totalC = lista.where((e) => e.curva == 'C').length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primary.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ChipCurva('A', totalA, Colors.green),
                  _ChipCurva('B', totalB, Colors.orange),
                  _ChipCurva('C', totalC, Colors.red),
                  Text('${lista.length} produtos', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = lista[i];
                  final cor = _corCurva(item.curva);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text(item.curva, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cor))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.produtoNome ?? 'Produto #${item.produtoId}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantidadePedidos} pedidos • ${item.pctIndividual.toStringAsFixed(1)}% do total',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (item.pctIndividual / 100).clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey[200],
                                  color: cor,
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(fmt.format(item.totalVendido),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChipCurva extends StatelessWidget {
  final String curva;
  final int total;
  final Color cor;
  const _ChipCurva(this.curva, this.total, this.cor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text('$curva: $total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cor)),
    );
  }
}

// ── Aba Genérica ──────────────────────────────────────────────────────────────

class _AbaGrupo extends StatelessWidget {
  final Future<List<ItemVendasGrupo>>? futuro;
  final NumberFormat fmt;
  final Color cor;
  const _AbaGrupo({required this.futuro, required this.fmt, required this.cor});

  @override
  Widget build(BuildContext context) {
    if (futuro == null) return const Center(child: CircularProgressIndicator());
    return FutureBuilder<List<ItemVendasGrupo>>(
      future: futuro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro ao carregar.', style: const TextStyle(color: AppTheme.textMuted)));
        }
        final lista = snap.data ?? [];
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhum dado no período.', style: TextStyle(color: AppTheme.textMuted)));
        }

        final totalGeral = lista.fold(0.0, (s, e) => s + e.totalVendido);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cor.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${lista.length} grupos', style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
                  Text('Total: ${fmt.format(totalGeral)}', style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = lista[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(fmt.format(item.totalVendido),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cor)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (item.pct / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: cor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantidadePedidos} pedidos', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text(
                                'Qtd: ${item.quantidadeVendida % 1 == 0 ? item.quantidadeVendida.toStringAsFixed(0) : item.quantidadeVendida.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              Text('${item.pct.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Bottom Sheet de Filtros ───────────────────────────────────────────────────

class _FiltrosSheet extends StatefulWidget {
  final List<Vendedor> vendedores;
  final FiltrosEstatistica? filtros;
  final int? vendedorId;
  final String? marca;
  final String? divisao;
  final String? colecao;
  final void Function(int?, String?, String?, String?) onAplicar;

  const _FiltrosSheet({
    required this.vendedores,
    required this.filtros,
    required this.vendedorId,
    required this.marca,
    required this.divisao,
    required this.colecao,
    required this.onAplicar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  int? _vendedorId;
  String? _marca;
  String? _divisao;
  String? _colecao;

  @override
  void initState() {
    super.initState();
    _vendedorId = widget.vendedorId;
    _marca = widget.marca;
    _divisao = widget.divisao;
    _colecao = widget.colecao;
  }

  @override
  Widget build(BuildContext context) {
    final filtros = widget.filtros;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                TextButton(
                  onPressed: () => setState(() { _vendedorId = null; _marca = null; _divisao = null; _colecao = null; }),
                  child: const Text('Limpar', style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.vendedores.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                value: _vendedorId,
                decoration: const InputDecoration(labelText: 'Vendedor', isDense: true),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...widget.vendedores.map((v) => DropdownMenuItem(value: v.pkChave, child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _vendedorId = v),
              ),
              const SizedBox(height: 12),
            ],
            if (filtros != null && filtros.marcas.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _marca,
                decoration: const InputDecoration(labelText: 'Marca', isDense: true),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...filtros.marcas.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _marca = v),
              ),
              const SizedBox(height: 12),
            ],
            if (filtros != null && filtros.divisoes.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _divisao,
                decoration: const InputDecoration(labelText: 'Divisão', isDense: true),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...filtros.divisoes.map((d) => DropdownMenuItem(value: d['codigo'], child: Text(d['nome'] ?? d['codigo'], overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _divisao = v),
              ),
              const SizedBox(height: 12),
            ],
            if (filtros != null && filtros.colecoes.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _colecao,
                decoration: const InputDecoration(labelText: 'Coleção', isDense: true),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...filtros.colecoes.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _colecao = v),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onAplicar(_vendedorId, _marca, _divisao, _colecao);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Aplicar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}