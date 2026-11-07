import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'catalogo_screen.dart' show brl;
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'login_cliente_sheet.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});
  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  bool _enviando = false; // trava duplo clique

  Future<void> _gerar() async {
    if (_enviando) return;
    final s = context.read<ClienteState>();
    // O login só é exigido aqui, ao gerar o condicional.
    if (!s.logado && !await pedirLogin(context, s)) return;
    if (!mounted) return;
    setState(() => _enviando = true);
    try {
      final r = await s.gerarCondicional();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Condicional gerado!'),
          content: Text('Número ${r['numero']} • ${r['itens']} peça(s) • ${brl.format(r['total'])}\n\n'
              'Separamos suas peças. Passe na loja para experimentar.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ClienteApiErro catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.status == 401 ? 'Sua sessão expirou. Toque em gerar de novo para entrar.' : e.mensagem)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final itens = s.carrinho.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Meu carrinho')),
      body: itens.isEmpty
          ? const Center(child: Text('Seu carrinho está vazio.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final it = itens[i];
                final p = it.produto;
                return ListTile(
                  title: Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${brl.format(p.preco)} cada'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => s.remover(p.id)),
                    Text('${it.quantidade}'),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => s.adicionar(p)),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => s.removerTudo(p.id)),
                  ]),
                );
              },
            ),
      bottomNavigationBar: itens.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${s.totalPecas} peça(s)'),
                    Text(brl.format(s.totalValor), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _enviando ? null : _gerar,
                    child: _enviando
                        ? const SizedBox(
                            height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Gerar condicional'),
                  ),
                ]),
              ),
            ),
    );
  }
}
