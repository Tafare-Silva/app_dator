import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/empresas.dart';
import 'carrinho_screen.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'login_cliente_sheet.dart';
import 'titulos_screen.dart';

final brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  static const _pagina = 30;
  final _scroll = ScrollController();
  final _busca = TextEditingController();
  Timer? _debounce;

  final List<ProdutoCatalogo> _itens = [];
  Filtros _filtros = Filtros.vazio;
  String? _divisao, _genero, _colecao;
  bool _novidades = false;
  bool _carregando = false, _fim = false;
  String? _erro;
  int _geracao = 0; // descarta respostas de buscas antigas

  ClienteState get _s => context.read<ClienteState>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _carregarMais();
    });
    _recarregar(comFiltros: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _recarregar({bool comFiltros = false}) async {
    _geracao++;
    setState(() {
      _itens.clear();
      _fim = false;
      _erro = null;
    });
    if (comFiltros) {
      try {
        final f = await _s.api.filtros();
        if (mounted) setState(() => _filtros = f);
      } catch (_) {}
    }
    await _carregarMais();
  }

  Future<void> _carregarMais() async {
    if (_carregando || _fim) return;
    final g = _geracao;
    setState(() => _carregando = true);
    try {
      final r = await _s.api.catalogo(
        busca: _busca.text.trim(), divisao: _divisao, genero: _genero, colecao: _colecao,
        novidades: _novidades, offset: _itens.length, limit: _pagina,
      );
      if (!mounted || g != _geracao) return;
      setState(() {
        _itens.addAll(r);
        _fim = r.length < _pagina;
      });
    } on ClienteApiErro catch (e) {
      if (mounted && g == _geracao) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted && g == _geracao) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirCarrinho() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CarrinhoScreen()));
  }

  Future<void> _abrirTitulos() async {
    final s = _s;
    if (!s.logado && !await pedirLogin(context, s)) return;
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TitulosScreen()));
  }

  Widget _chip(String rotulo, String? atual, List<String> opcoes, void Function(String?) set) {
    if (opcoes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String?>(
        onSelected: (v) {
          setState(() => set(v));
          _recarregar();
        },
        itemBuilder: (_) => [
          PopupMenuItem<String?>(value: null, child: Text('Todos ($rotulo)')),
          ...opcoes.map((o) => PopupMenuItem<String?>(value: o, child: Text(o))),
        ],
        child: Chip(
          label: Text(atual ?? rotulo),
          backgroundColor: atual != null ? Theme.of(context).colorScheme.primaryContainer : null,
          avatar: const Icon(Icons.arrow_drop_down, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final nomeLoja = empresasDisponiveis.firstWhere((e) => e.id == s.loja,
        orElse: () => const Empresa(id: '', nome: '')).nome;
    return Scaffold(
      appBar: AppBar(
        title: Text(nomeLoja.isEmpty ? 'Catálogo' : nomeLoja),
        actions: [
          IconButton(
            tooltip: 'Trocar de loja',
            icon: const Icon(Icons.store_outlined),
            onPressed: () => _s.escolherLoja(''),
          ),
          IconButton(tooltip: 'Meus títulos', icon: const Icon(Icons.receipt_long_outlined), onPressed: _abrirTitulos),
          Badge(
            isLabelVisible: s.totalPecas > 0,
            label: Text('${s.totalPecas}'),
            alignment: const AlignmentDirectional(-4, 4),
            child: IconButton(
                tooltip: 'Carrinho', icon: const Icon(Icons.shopping_bag_outlined), onPressed: _abrirCarrinho),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _busca,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar produto',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busca.clear();
                          _recarregar();
                        }),
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _recarregar);
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(children: [
            if (_filtros.temNovidades)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Novidades'),
                  selected: _novidades,
                  onSelected: (v) {
                    setState(() => _novidades = v);
                    _recarregar();
                  },
                ),
              ),
            _chip('Categoria', _divisao, _filtros.divisoes, (v) => _divisao = v),
            _chip('Gênero', _genero, _filtros.generos, (v) => _genero = v),
            _chip('Coleção', _colecao, _filtros.colecoes, (v) => _colecao = v),
          ]),
        ),
        Expanded(child: _corpo(s)),
      ]),
      bottomNavigationBar: s.totalPecas == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ElevatedButton.icon(
                  onPressed: _abrirCarrinho,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text('Ver carrinho (${s.totalPecas}) • ${brl.format(s.totalValor)}'),
                ),
              ),
            ),
    );
  }

  Widget _corpo(ClienteState s) {
    if (_itens.isEmpty) {
      if (_carregando) return const Center(child: CircularProgressIndicator());
      if (_erro != null) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_erro!),
            TextButton(onPressed: () => _recarregar(comFiltros: true), child: const Text('Tentar de novo')),
          ]),
        );
      }
      return const Center(
          child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum produto encontrado.', textAlign: TextAlign.center)));
    }
    return RefreshIndicator(
      onRefresh: () => _recarregar(comFiltros: true),
      child: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.62),
        itemCount: _itens.length + (_carregando ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _itens.length) return const Center(child: CircularProgressIndicator());
          return _CardProduto(p: _itens[i]);
        },
      ),
    );
  }
}

class _CardProduto extends StatelessWidget {
  final ProdutoCatalogo p;
  const _CardProduto({required this.p});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final qtd = s.carrinho[p.id]?.quantidade ?? 0;
    final detalhe = [p.tamanho, p.cor].where((e) => e != null && e.trim().isNotEmpty).join(' • ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: FutureBuilder<String>(
            future: s.api.fotoUrl(p.id),
            builder: (_, snap) => snap.hasData
                ? Image.network(snap.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined)))
                : const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        if (detalhe.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(detalhe, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 4, 6),
          child: Row(children: [
            Expanded(child: Text(brl.format(p.preco), style: const TextStyle(fontWeight: FontWeight.bold))),
            if (qtd == 0)
              IconButton.filled(
                tooltip: 'Adicionar ao carrinho',
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                onPressed: () {
                  if (!s.adicionar(p)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Limite de ${ClienteState.maxPecas} peças por condicional.')));
                  }
                },
              )
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => s.remover(p.id)),
                Text('$qtd'),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (!s.adicionar(p)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Limite de ${ClienteState.maxPecas} peças por condicional.')));
                      }
                    }),
              ]),
          ]),
        ),
      ]),
    );
  }
}
