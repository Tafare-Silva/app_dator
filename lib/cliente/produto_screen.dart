import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'cliente_tema.dart';
import 'widgets_cliente.dart';

void avisarLimite(BuildContext context) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(const SnackBar(content: Text('Limite de ${ClienteState.maxPecas} peças por condicional.')));

class ProdutoScreen extends StatelessWidget {
  final ProdutoCatalogo p;
  const ProdutoScreen({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    final qtd = s.carrinho[p.id]?.quantidade ?? 0;
    final infos = <(String, String?)>[
      ('Tamanho', p.tamanho),
      ('Cor', p.cor),
      ('Categoria', p.divisao),
      ('Coleção', p.colecao),
      ('Referência', p.referencia),
    ].where((e) => e.$2 != null && e.$2!.trim().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.55,
          pinned: true,
          backgroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: ClienteTema.texto), onPressed: () => Navigator.pop(context)),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(tag: 'foto-${p.id}', child: FotoProduto(url: s.api.fotoUrlSync(p.id))),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25)),
              const SizedBox(height: 10),
              Text(brl.format(p.preco),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ClienteTema.marca)),
              const SizedBox(height: 20),
              if (infos.isNotEmpty)
                Container(
                  decoration: BoxDecoration(color: ClienteTema.fundo, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    for (var i = 0; i < infos.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Text(infos[i].$1, style: const TextStyle(color: ClienteTema.suave)),
                          const Spacer(),
                          Flexible(
                              child: Text(infos[i].$2!,
                                  textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w500))),
                        ]),
                      ),
                    ],
                  ]),
                ),
              const SizedBox(height: 16),
              const Row(children: [
                Icon(Icons.verified_outlined, size: 20, color: ClienteTema.suave),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Peça separada na loja assim que você gerar o condicional.',
                        style: TextStyle(color: ClienteTema.suave, fontSize: 13))),
              ]),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: qtd == 0
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Adicionar ao carrinho'),
                    onPressed: () {
                      if (!s.adicionar(p)) avisarLimite(context);
                    },
                  )
                : Row(children: [
                    Container(
                      decoration: BoxDecoration(
                          color: ClienteTema.fundo, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => s.remover(p.id)),
                        SizedBox(
                            width: 28,
                            child: Text('$qtd',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                        IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (!s.adicionar(p)) avisarLimite(context);
                            }),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Continuar comprando'),
                      ),
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}
