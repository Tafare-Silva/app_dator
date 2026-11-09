import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/empresas.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'cliente_tema.dart';
import 'produto_screen.dart';
import 'widgets_cliente.dart';

/// Aba "Início": cabeçalho com busca, filtros e vitrine de produtos.
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
  bool get _filtrando =>
      _busca.text.trim().isNotEmpty || _divisao != null || _genero != null || _colecao != null || _novidades;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _carregarMais();
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
      _carregando = false;
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

  void _limparFiltros() {
    _busca.clear();
    _divisao = _genero = _colecao = null;
    _novidades = false;
    _recarregar();
  }

  Widget _chip(String rotulo, String? atual, List<String> opcoes, void Function(String?) set) {
    if (opcoes.isEmpty) return const SizedBox.shrink();
    final ativo = atual != null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String?>(
        onSelected: (v) {
          setState(() => set(v));
          _recarregar();
        },
        itemBuilder: (_) => [
          const PopupMenuItem<String?>(value: null, child: Text('Todos')),
          ...opcoes.map((o) => PopupMenuItem<String?>(value: o, child: Text(o))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: ativo ? ClienteTema.marca : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ativo ? ClienteTema.marca : const Color(0xFFDDDDE3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(atual ?? rotulo,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: ativo ? Colors.white : ClienteTema.texto)),
            Icon(Icons.keyboard_arrow_down, size: 18, color: ativo ? Colors.white : ClienteTema.suave),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final nomeLoja = empresasDisponiveis
        .firstWhere((e) => e.id == s.loja, orElse: () => const Empresa(id: '', nome: ''))
        .nome;
    final primeiroNome = (s.nome ?? '').trim().split(' ').first;

    return RefreshIndicator(
      color: ClienteTema.marca,
      onRefresh: () => _recarregar(comFiltros: true),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Cabeçalho
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [ClienteTema.marcaEscura, ClienteTema.marca],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(primeiroNome.isEmpty ? 'Olá! 👋' : 'Olá, $primeiroNome 👋',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(nomeLoja.isEmpty ? 'Catálogo' : nomeLoja,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Trocar de loja',
                        icon: const Icon(Icons.storefront_outlined, color: Colors.white),
                        onPressed: () => _s.escolherLoja(''),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _busca,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'O que você procura?',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _busca.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
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
                  ]),
                ),
              ),
            ),
          ),
          // Filtros
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(children: [
                if (_filtros.temNovidades)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _novidades = !_novidades);
                        _recarregar();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _novidades ? ClienteTema.marca : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _novidades ? ClienteTema.marca : const Color(0xFFDDDDE3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome, size: 16, color: _novidades ? Colors.white : ClienteTema.marca),
                          const SizedBox(width: 6),
                          Text('Novidades',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _novidades ? Colors.white : ClienteTema.texto)),
                        ]),
                      ),
                    ),
                  ),
                _chip('Categoria', _divisao, _filtros.divisoes, (v) => _divisao = v),
                _chip('Gênero', _genero, _filtros.generos, (v) => _genero = v),
                _chip('Coleção', _colecao, _filtros.colecoes, (v) => _colecao = v),
                if (_filtrando)
                  TextButton(onPressed: _limparFiltros, child: const Text('Limpar')),
              ]),
            ),
          ),
          ..._vitrine(),
        ],
      ),
    );
  }

  List<Widget> _vitrine() {
    if (_itens.isEmpty) {
      if (_carregando) return [_grade(skeleton: true)];
      if (_erro != null) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EstadoVazio(
                icone: Icons.wifi_off,
                titulo: 'Não foi possível carregar',
                texto: _erro,
                acao: 'Tentar de novo',
                onAcao: () => _recarregar(comFiltros: true)),
          )
        ];
      }
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(
            icone: Icons.search_off,
            titulo: _filtrando ? 'Nada encontrado' : 'Novidades chegando em breve',
            texto: _filtrando ? 'Tente outra busca ou limpe os filtros.' : 'Ainda não há peças disponíveis por aqui.',
            acao: _filtrando ? 'Limpar filtros' : null,
            onAcao: _filtrando ? _limparFiltros : null,
          ),
        )
      ];
    }
    return [
      _grade(),
      if (_carregando)
        const SliverToBoxAdapter(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: ClienteTema.marca, strokeWidth: 3)))),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  static const _delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.58);

  Widget _grade({bool skeleton = false}) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverGrid(
          gridDelegate: _delegate,
          delegate: SliverChildBuilderDelegate(
            (_, i) => skeleton ? const _CardEsqueleto() : _CardProduto(p: _itens[i]),
            childCount: skeleton ? 6 : _itens.length,
          ),
        ),
      );
}

class _CardEsqueleto extends StatelessWidget {
  const _CardEsqueleto();
  @override
  Widget build(BuildContext context) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Esqueleto()),
        SizedBox(height: 10),
        Esqueleto(altura: 14, radius: 6),
        SizedBox(height: 6),
        Esqueleto(altura: 14, radius: 6),
        SizedBox(height: 10),
      ]);
}

class _CardProduto extends StatelessWidget {
  final ProdutoCatalogo p;
  const _CardProduto({required this.p});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final qtd = s.carrinho[p.id]?.quantidade ?? 0;
    final detalhe = [p.tamanho, p.cor].where((e) => e != null && e.trim().isNotEmpty).join(' • ');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProdutoScreen(p: p))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: Hero(
                tag: 'foto-${p.id}',
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(16), child: FotoProduto(url: s.api.fotoUrlSync(p.id))),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: qtd == 0 ? Colors.white : ClienteTema.marca,
                shape: qtd == 0 ? const CircleBorder() : const StadiumBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: qtd == 0 ? const CircleBorder() : const StadiumBorder(),
                  onTap: () {
                    if (!s.adicionar(p)) avisarLimite(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: qtd == 0 ? 9 : 12, vertical: 9),
                    child: qtd == 0
                        ? const Icon(Icons.add_shopping_cart, size: 20, color: ClienteTema.marca)
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('$qtd',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.25)),
        if (detalhe.isNotEmpty)
          Text(detalhe, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: ClienteTema.suave)),
        const SizedBox(height: 2),
        Text(brl.format(p.preco),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ClienteTema.marca)),
      ]),
    );
  }
}
