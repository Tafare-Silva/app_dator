import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../core/app_theme.dart';

class BuscaProdutoScreen extends StatefulWidget {
  final String nomeMesa;
  const BuscaProdutoScreen({super.key, required this.nomeMesa});

  @override
  State<BuscaProdutoScreen> createState() => _BuscaProdutoScreenState();
}

class _BuscaProdutoScreenState extends State<BuscaProdutoScreen> {
  final _produtoService = ProdutoService();
  final _itemService = ItemMesaService();
  final _buscaCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Produto> _produtos = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _carregando = true);
    try {
      final resultado = await _produtoService.buscarProdutos(
          busca: _buscaCtrl.text.trim().isEmpty ? null : _buscaCtrl.text.trim());
      setState(() => _produtos = resultado);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar produtos.')),
        );
      }
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _selecionarProduto(Produto produto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdicionarItemSheet(
        produto: produto,
        nomeMesa: widget.nomeMesa,
        fmt: _fmt,
        itemService: _itemService,
        onAdicionado: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('Adicionar — ${widget.nomeMesa}')),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _buscaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaCtrl.clear();
                          _buscar();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _buscar(),
            ),
          ),

          // Lista
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _produtos.isEmpty
                    ? const Center(
                        child: Text('Nenhum produto encontrado.',
                            style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _produtos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ProdutoTile(
                          produto: _produtos[i],
                          fmt: _fmt,
                          onTap: () => _selecionarProduto(_produtos[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  final Produto produto;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _ProdutoTile(
      {required this.produto, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          produto.nome ?? 'Produto #${produto.pkChave}',
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
        trailing: Text(
          fmt.format(produto.precoVenda),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.primary),
        ),
      ),
    );
  }
}

// ── Bottom Sheet para confirmar quantidade e observação ───────────────────────

class _AdicionarItemSheet extends StatefulWidget {
  final Produto produto;
  final String nomeMesa;
  final NumberFormat fmt;
  final ItemMesaService itemService;
  final VoidCallback onAdicionado;

  const _AdicionarItemSheet({
    required this.produto,
    required this.nomeMesa,
    required this.fmt,
    required this.itemService,
    required this.onAdicionado,
  });

  @override
  State<_AdicionarItemSheet> createState() => _AdicionarItemSheetState();
}

class _AdicionarItemSheetState extends State<_AdicionarItemSheet> {
  double _quantidade = 1;
  final _obsCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _salvando = true);
    try {
      await widget.itemService.adicionarItem(
        nomeMesa: widget.nomeMesa,
        produtoId: widget.produto.pkChave,
        quantidade: _quantidade,
        vrUnitario: widget.produto.precoVenda,
        observacao: _obsCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context); // fecha o sheet
        widget.onAdicionado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.produto.nome} adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao adicionar item.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.produto.precoVenda * _quantidade;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            widget.produto.nome ?? 'Produto',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark),
          ),
          Text(
            widget.fmt.format(widget.produto.precoVenda),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Seletor de quantidade
          const Text('Quantidade',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _BotaoQtd(
                icon: Icons.remove,
                onTap: _quantidade > 1
                    ? () => setState(() => _quantidade--)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _quantidade.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _BotaoQtd(
                icon: Icons.add,
                onTap: () => setState(() => _quantidade++),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Observação
          TextField(
            controller: _obsCtrl,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              hintText: 'Ex: sem cebola, bem passado...',
              prefixIcon: Icon(Icons.chat_bubble_outline),
            ),
            maxLength: 250,
          ),
          const SizedBox(height: 16),

          // Botão confirmar
          ElevatedButton(
            onPressed: _salvando ? null : _confirmar,
            child: _salvando
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    'Adicionar • ${widget.fmt.format(total)}',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BotaoQtd extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BotaoQtd({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(
              color: onTap != null ? AppTheme.primary : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: onTap != null ? AppTheme.primary : Colors.grey[400]),
      ),
    );
  }
}
