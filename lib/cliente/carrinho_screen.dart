import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'cliente_tema.dart';
import 'login_cliente_sheet.dart';
import 'produto_screen.dart';
import 'widgets_cliente.dart';

class CarrinhoScreen extends StatefulWidget {
  /// Chamado depois do condicional gerado (a aba volta para o Início).
  final VoidCallback onConcluido;
  final VoidCallback onVerCatalogo;
  const CarrinhoScreen({super.key, required this.onConcluido, required this.onVerCatalogo});
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
          title: const Text('Condicional gerado!', textAlign: TextAlign.center),
          content: Text(
              'Nº ${r['numero']}\n${r['itens']} peça(s) • ${brl.format(r['total'])}\n\n'
              'Separamos suas peças. Passe na loja para experimentar.',
              textAlign: TextAlign.center),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi')),
          ],
        ),
      );
      widget.onConcluido();
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
          ? EstadoVazio(
              icone: Icons.shopping_bag_outlined,
              titulo: 'Seu carrinho está vazio',
              texto: 'Escolha as peças que você gostou e gere seu condicional.',
              acao: 'Ver produtos',
              onAcao: widget.onVerCatalogo)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final it = itens[i];
                final p = it.produto;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => ProdutoScreen(p: p))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 80, height: 100, child: FotoProduto(url: s.api.fotoUrlSync(p.id))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.nome, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(brl.format(p.preco * it.quantidade),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: ClienteTema.marca)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              decoration: BoxDecoration(
                                  color: ClienteTema.fundo, borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                _Mini(Icons.remove, () => s.remover(p.id)),
                                SizedBox(
                                    width: 24,
                                    child: Text('${it.quantidade}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.w600))),
                                _Mini(Icons.add, () {
                                  if (!s.adicionar(p)) avisarLimite(context);
                                }),
                              ]),
                            ),
                            const Spacer(),
                            IconButton(
                                tooltip: 'Remover',
                                icon: const Icon(Icons.delete_outline, color: ClienteTema.suave),
                                onPressed: () => s.removerTudo(p.id)),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
      bottomNavigationBar: itens.isEmpty
          ? null
          : Container(
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
              ]),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${s.totalPecas} peça(s)', style: const TextStyle(color: ClienteTema.suave)),
                    Text(brl.format(s.totalValor),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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

class _Mini extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  const _Mini(this.icone, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(7), child: Icon(icone, size: 18)),
      );
}
