import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_theme.dart';
import '../../models/cliente_model.dart';
import '../../models/produto_model.dart';
import '../../models/vendas_models.dart';
import '../../services/cliente_service.dart';
import '../../services/produto_service.dart';
import '../../services/vendas_service.dart';

class _ItemForm {
  final ProdutoResumo produto;
  double quantidade;
  double vrUnitario;
  double desconto;
  int? vendedorId;
  String? vendedorNome;

  _ItemForm({
    required this.produto,
    this.quantidade = 1,
    required this.vrUnitario,
    this.desconto = 0,
    this.vendedorId,
    this.vendedorNome,
  });

  double get total => quantidade * vrUnitario - desconto;
}

class NovaPreVendaScreen extends StatefulWidget {
  final VoidCallback? onPreVendaCriada;
  const NovaPreVendaScreen({super.key, this.onPreVendaCriada});

  @override
  State<NovaPreVendaScreen> createState() => _NovaPreVendaScreenState();
}

class _NovaPreVendaScreenState extends State<NovaPreVendaScreen> {
  final _vendasService = VendasService();
  final _clienteService = ClienteService();
  final _produtoService = ProdutoService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  // Cabeçalho
  Cliente? _clienteSelecionado;
  Vendedor? _vendedorCabecalho;
  DateTime _data = DateTime.now();
  List<Vendedor> _vendedores = [];

  // Itens
  final List<_ItemForm> _itens = [];

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _vendasService.listarVendedores().then((v) {
      if (mounted) setState(() => _vendedores = v);
    });
  }

  double get _totalGeral => _itens.fold(0, (acc, i) => acc + i.total);

  // ── Busca de cliente ──────────────────────────────────────────────────────────

  Future<void> _selecionarCliente() async {
    final cliente = await showDialog<Cliente>(
      context: context,
      builder: (_) => _BuscaClienteDialog(service: _clienteService),
    );
    if (cliente != null) setState(() => _clienteSelecionado = cliente);
  }

  // ── Busca de produto ──────────────────────────────────────────────────────────

  Future<void> _adicionarProdutoPorCodigo(String codigo) async {
    // Tenta como pk_chave (código interno) e como código de barras
    final pk = int.tryParse(codigo.trim());
    List<ProdutoResumo> lista;
    if (pk != null) {
      lista = await _produtoService.listarProdutos(pkChaveExato: pk, limit: 1);
      if (lista.isEmpty) {
        lista = await _produtoService.listarProdutos(codigoBarras: codigo, limit: 1);
      }
    } else {
      lista = await _produtoService.listarProdutos(codigoBarras: codigo, limit: 1);
    }

    if (!mounted) return;
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto não encontrado: $codigo')),
      );
      return;
    }
    _adicionarOuIncrementar(lista.first);
  }

  Future<void> _adicionarProdutoDialog() async {
    final produto = await showDialog<ProdutoResumo>(
      context: context,
      builder: (_) => _BuscaProdutoDialog(service: _produtoService),
    );
    if (produto != null) _adicionarOuIncrementar(produto);
  }

  void _adicionarOuIncrementar(ProdutoResumo produto) {
    setState(() {
      _itens.add(_ItemForm(
        produto: produto,
        vrUnitario: produto.precoVenda,
        vendedorId: _vendedorCabecalho?.pkChave,
        vendedorNome: _vendedorCabecalho?.nome,
      ));
    });
  }

  Future<void> _abrirScanner() async {
    final codigo = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (codigo != null && mounted) await _adicionarProdutoPorCodigo(codigo);
  }

  // ── Edição de item ────────────────────────────────────────────────────────────

  void _editarItem(int idx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarItemSheet(
        item: _itens[idx],
        vendedores: _vendedores,
        onSalvar: (item) => setState(() => _itens[idx] = item),
        onRemover: () => setState(() => _itens.removeAt(idx)),
      ),
    );
  }

  // ── Salvar ────────────────────────────────────────────────────────────────────

  Future<void> _salvar() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final input = PreVendaInput(
        clienteId: _clienteSelecionado?.pkChave,
        vendedorId: _vendedorCabecalho?.pkChave,
        data: _data,
        itens: _itens
            .map((i) => ItemPreVendaInput(
                  produtoId: i.produto.pkChave,
                  quantidade: i.quantidade,
                  vrUnitarioBruto: i.vrUnitario,
                  vrDescontoTotal: i.desconto,
                  vendedorId: i.vendedorId,
                ))
            .toList(),
      );
      final criada = await _vendasService.criarPreVenda(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pré-venda #${criada.pkChave} criada!')),
      );
      widget.onPreVendaCriada?.call();
      Navigator.pop(context, criada);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nova Pré-Venda'),
        actions: [
          if (_salvando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _salvar,
              child: const Text('SALVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Cabeçalho ─────────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cabeçalho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                        const SizedBox(height: 10),
                        // Cliente
                        InkWell(
                          onTap: _selecionarCliente,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _clienteSelecionado?.nome ?? 'Selecionar cliente...',
                                    style: TextStyle(
                                      color: _clienteSelecionado != null ? AppTheme.textDark : AppTheme.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.search, size: 16, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Vendedor
                        DropdownButtonFormField<int?>(
                          initialValue: _vendedorCabecalho?.pkChave,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Vendedor',
                            prefixIcon: Icon(Icons.badge_outlined),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Nenhum')),
                            ..._vendedores.map((v) => DropdownMenuItem(
                                  value: v.pkChave,
                                  child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) {
                            final vend = _vendedores.firstWhere(
                              (x) => x.pkChave == v,
                              orElse: () => Vendedor(pkChave: 0, ativo: true),
                            );
                            setState(() {
                              _vendedorCabecalho = v != null ? vend : null;
                              for (final item in _itens) {
                                item.vendedorId = v;
                                item.vendedorNome = v != null ? vend.nome : null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        // Data
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _data,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              locale: const Locale('pt', 'BR'),
                            );
                            if (d != null) setState(() => _data = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 15, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text('Data: ${_fmtData.format(_data)}', style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Itens ─────────────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Itens (${_itens.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                              tooltip: 'Ler código de barras',
                              onPressed: _abrirScanner,
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                              tooltip: 'Buscar produto',
                              onPressed: _adicionarProdutoDialog,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (_itens.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Text('Nenhum item', style: TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_itens.length, (i) => _CardItem(
                            item: _itens[i],
                            fmt: _fmt,
                            onTap: () => _editarItem(i),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // ── Rodapé ───────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Text(_fmt.format(_totalGeral), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: const Icon(Icons.check),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog busca cliente ──────────────────────────────────────────────────────

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
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Buscar Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome do cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscando
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
              onChanged: _buscar,
            ),
            const SizedBox(height: 8),
            if (_resultados.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhum resultado', style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultados.length,
                  itemBuilder: (_, i) {
                    final c = _resultados[i];
                    final info = <String>[];
                    if (c.cnpjCpf?.isNotEmpty == true) { info.add('CPF: ${c.cnpjCpf}'); }
                    if (c.celular?.isNotEmpty == true) {
                      info.add(c.celular!);
                    } else if (c.fone?.isNotEmpty == true) {
                      info.add(c.fone!);
                    }
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline, color: AppTheme.primary),
                      title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: info.isNotEmpty ? Text(info.join('  ·  '), style: const TextStyle(fontSize: 11)) : null,
                      trailing: Text('#${c.pkChave}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog busca produto ──────────────────────────────────────────────────────

class _BuscaProdutoDialog extends StatefulWidget {
  final ProdutoService service;
  const _BuscaProdutoDialog({required this.service});

  @override
  State<_BuscaProdutoDialog> createState() => _BuscaProdutoDialogState();
}

class _BuscaProdutoDialogState extends State<_BuscaProdutoDialog> {
  final _ctrl = TextEditingController();
  List<ProdutoResumo> _resultados = [];
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
        final r = await widget.service.listarProdutos(busca: termo.trim(), limit: 30);
        if (mounted) setState(() => _resultados = r);
      } finally {
        if (mounted) setState(() => _buscando = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Buscar Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome ou referência...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscando
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
              onChanged: _buscar,
            ),
            const SizedBox(height: 8),
            if (_resultados.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhum resultado', style: TextStyle(color: AppTheme.textMuted)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultados.length,
                  itemBuilder: (_, i) {
                    final p = _resultados[i];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.primary),
                      ),
                      title: Text(p.nome ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Cód: ${p.pkChave}  ·  ${fmt.format(p.precoVenda)}  ·  Est: ${p.estoque.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Card item ─────────────────────────────────────────────────────────────────

class _CardItem extends StatelessWidget {
  final _ItemForm item;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _CardItem({required this.item, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final qtdStr = item.quantidade == item.quantidade.truncateToDouble()
        ? item.quantidade.toStringAsFixed(0)
        : item.quantidade.toStringAsFixed(2);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.produto.nome ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2),
                  Text(
                    '$qtdStr × ${fmt.format(item.vrUnitario)}${item.desconto > 0 ? '  Desc: ${fmt.format(item.desconto)}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  if (item.vendedorNome != null)
                    Text('Vendedor: ${item.vendedorNome}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const Icon(Icons.edit_outlined, size: 14, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet edição de item ──────────────────────────────────────────────────────

class _EditarItemSheet extends StatefulWidget {
  final _ItemForm item;
  final List<Vendedor> vendedores;
  final ValueChanged<_ItemForm> onSalvar;
  final VoidCallback onRemover;
  const _EditarItemSheet({required this.item, required this.vendedores, required this.onSalvar, required this.onRemover});

  @override
  State<_EditarItemSheet> createState() => _EditarItemSheetState();
}

class _EditarItemSheetState extends State<_EditarItemSheet> {
  late final TextEditingController _qtdCtrl;
  late final TextEditingController _precoCtrl;
  late final TextEditingController _descontoCtrl;
  int? _vendedorId;

  @override
  void initState() {
    super.initState();
    final qtd = widget.item.quantidade;
    _qtdCtrl = TextEditingController(
        text: qtd == qtd.truncateToDouble() ? qtd.toStringAsFixed(0) : qtd.toStringAsFixed(2));
    _precoCtrl = TextEditingController(text: widget.item.vrUnitario.toStringAsFixed(2));
    _descontoCtrl = TextEditingController(text: widget.item.desconto.toStringAsFixed(2));
    _vendedorId = widget.item.vendedorId;
  }

  @override
  void dispose() {
    _qtdCtrl.dispose();
    _precoCtrl.dispose();
    _descontoCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? widget.item.quantidade;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? widget.item.vrUnitario;
    final desc = double.tryParse(_descontoCtrl.text.replaceAll(',', '.')) ?? widget.item.desconto;
    final vend = widget.vendedores.firstWhere((v) => v.pkChave == _vendedorId, orElse: () => Vendedor(pkChave: 0, ativo: true));
    widget.onSalvar(_ItemForm(
      produto: widget.item.produto,
      quantidade: qtd,
      vrUnitario: preco,
      desconto: desc,
      vendedorId: _vendedorId,
      vendedorNome: _vendedorId != null ? vend.nome : null,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text(widget.item.produto.nome ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark), maxLines: 2),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _qtdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Qtd', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço Unit.', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _descontoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Desconto', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: _vendedorId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Vendedor (item)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [
              const DropdownMenuItem(value: null, child: Text('Usar vendedor do cabeçalho')),
              ...widget.vendedores.map((v) => DropdownMenuItem(value: v.pkChave, child: Text(v.nome ?? '—', overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _vendedorId = v),
          ),
          const SizedBox(height: 16),
          Row(children: [
            OutlinedButton.icon(
              onPressed: () { widget.onRemover(); Navigator.pop(context); },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remover', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
              child: const Text('Confirmar'),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Scanner (igual ao módulo de Produtos) ─────────────────────────────────────

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final _controller = MobileScannerController();
  bool _escaneado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler Código de Barras'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_escaneado) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _escaneado = true;
                Navigator.pop(context, barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              'Aponte para o código de barras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
