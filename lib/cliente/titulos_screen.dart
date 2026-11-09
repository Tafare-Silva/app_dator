import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';
import 'cliente_tema.dart';
import 'login_cliente_sheet.dart';
import 'widgets_cliente.dart';

/// Aba "Meus títulos": pede login se o cliente ainda não entrou.
class TitulosScreen extends StatefulWidget {
  const TitulosScreen({super.key});
  @override
  State<TitulosScreen> createState() => _TitulosScreenState();
}

typedef _Dados = ({double total, double totalVencido, List<TituloCliente> titulos});

class _TitulosScreenState extends State<TitulosScreen> {
  Future<_Dados>? _f;
  final _data = DateFormat('dd/MM/yyyy');

  Future<_Dados> _carregar() async {
    final s = context.read<ClienteState>();
    try {
      return await s.api.titulos();
    } on ClienteApiErro catch (e) {
      if (e.status == 401) s.sessaoExpirou();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ClienteState>();
    if (!s.logado) {
      _f = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Meus títulos')),
        body: EstadoVazio(
          icone: Icons.lock_outline,
          titulo: 'Entre para ver seus títulos',
          texto: 'Use seu CPF e o código enviado ao seu WhatsApp.',
          acao: 'Entrar',
          onAcao: () => pedirLogin(context, s),
        ),
      );
    }
    _f ??= _carregar();
    return Scaffold(
      appBar: AppBar(title: const Text('Meus títulos')),
      body: FutureBuilder<_Dados>(
        future: _f,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: ClienteTema.marca));
          }
          if (snap.hasError) {
            if (!s.logado) return const SizedBox.shrink(); // sessão expirou: o build refaz a tela de login
            return EstadoVazio(
              icone: Icons.wifi_off,
              titulo: 'Não foi possível carregar',
              texto: snap.error is ClienteApiErro ? (snap.error as ClienteApiErro).mensagem : null,
              acao: 'Tentar de novo',
              onAcao: () => setState(() => _f = _carregar()),
            );
          }
          final d = snap.data!;
          if (d.titulos.isEmpty) {
            return const EstadoVazio(
                icone: Icons.celebration_outlined,
                titulo: 'Tudo em dia!',
                texto: 'Você não tem nenhum título em aberto.');
          }
          return RefreshIndicator(
            color: ClienteTema.marca,
            onRefresh: () async {
              setState(() => _f = _carregar());
              await _f;
            },
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ClienteTema.marcaEscura, ClienteTema.marca]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total em aberto', style: TextStyle(color: Colors.white70)),
                  Text(brl.format(d.total),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                  if (d.totalVencido > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('Vencido: ${brl.format(d.totalVencido)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              ...d.titulos.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: (t.vencido ? Colors.red : ClienteTema.suave).withValues(alpha: 0.1),
                          child: Icon(t.vencido ? Icons.warning_amber_rounded : Icons.schedule,
                              color: t.vencido ? Colors.red : ClienteTema.suave),
                        ),
                        title: Text('Vence em ${_data.format(t.vencimento)}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text([
                          if (t.documento != null) 'Doc. ${t.documento}',
                          if (t.parcela != null) 'Parcela ${t.parcela}',
                          if (t.vencido) 'VENCIDO',
                        ].join(' • ')),
                        trailing: Text(brl.format(t.valor),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  )),
            ]),
          );
        },
      ),
    );
  }
}
