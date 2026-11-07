import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'catalogo_screen.dart' show brl;
import 'cliente_api.dart';
import 'cliente_state.dart';

class TitulosScreen extends StatefulWidget {
  const TitulosScreen({super.key});
  @override
  State<TitulosScreen> createState() => _TitulosScreenState();
}

class _TitulosScreenState extends State<TitulosScreen> {
  late Future<({double total, double totalVencido, List<TituloCliente> titulos})> _f;
  final _data = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _f = _carregar();
  }

  Future<({double total, double totalVencido, List<TituloCliente> titulos})> _carregar() async {
    final s = context.read<ClienteState>();
    try {
      return await s.api.titulos();
    } on ClienteApiErro catch (e) {
      if (e.status == 401) {
        s.sessaoExpirou();
        if (mounted) Navigator.pop(context);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.watch<ClienteState>().nome;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus títulos em aberto')),
      body: FutureBuilder(
        future: _f,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(snap.error is ClienteApiErro ? (snap.error as ClienteApiErro).mensagem : 'Não foi possível carregar.'),
                TextButton(onPressed: () => setState(() => _f = _carregar()), child: const Text('Tentar de novo')),
              ]),
            );
          }
          final d = snap.data!;
          if (d.titulos.isEmpty) {
            return Center(child: Text('${nome ?? 'Você'}, nenhum título em aberto. 🎉'));
          }
          return ListView(padding: const EdgeInsets.all(12), children: [
            Card(
              child: ListTile(
                title: const Text('Total em aberto'),
                trailing: Text(brl.format(d.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: d.totalVencido > 0
                    ? Text('Vencido: ${brl.format(d.totalVencido)}', style: const TextStyle(color: Colors.red))
                    : null,
              ),
            ),
            ...d.titulos.map((t) => Card(
                  child: ListTile(
                    leading: Icon(t.vencido ? Icons.warning_amber_rounded : Icons.schedule,
                        color: t.vencido ? Colors.red : Colors.grey),
                    title: Text('Vence em ${_data.format(t.vencimento)}'),
                    subtitle: Text([
                      if (t.documento != null) 'Doc. ${t.documento}',
                      if (t.parcela != null) 'Parcela ${t.parcela}',
                      if (t.vencido) 'VENCIDO',
                    ].join(' • ')),
                    trailing: Text(brl.format(t.valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
          ]);
        },
      ),
    );
  }
}
