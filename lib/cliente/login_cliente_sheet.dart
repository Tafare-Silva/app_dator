import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cliente_api.dart';
import 'cliente_state.dart';

/// Pede CPF -> código recebido no WhatsApp. Devolve true se o cliente entrou.
Future<bool> pedirLogin(BuildContext context, ClienteState estado) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LoginSheet(estado: estado),
  );
  return ok == true;
}

class _LoginSheet extends StatefulWidget {
  final ClienteState estado;
  const _LoginSheet({required this.estado});
  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  final _cpf = TextEditingController();
  final _codigo = TextEditingController();
  String? _celularMascarado; // != null => etapa do código
  String? _erro;
  bool _bloqueioCadastro = false; // sem_cadastro / sem_celular: não adianta tentar de novo
  bool _carregando = false;

  String get _cpfDigitos => _cpf.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _executar(Future<void> Function() f) async {
    setState(() {
      _carregando = true;
      _erro = null;
      _bloqueioCadastro = false;
    });
    try {
      await f();
    } on ClienteApiErro catch (e) {
      _erro = e.mensagem;
      _bloqueioCadastro = e.codigo == 'sem_cadastro' || e.codigo == 'sem_celular';
    } catch (_) {
      _erro = 'Algo deu errado. Tente de novo.';
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _pedirCodigo() => _executar(() async {
        if (_cpfDigitos.length != 11) throw ClienteApiErro('Digite os 11 números do CPF.');
        final cel = await widget.estado.api.solicitarCodigo(_cpfDigitos);
        _celularMascarado = cel;
        _codigo.clear();
      });

  Future<void> _confirmar() => _executar(() async {
        if (_codigo.text.length != 6) throw ClienteApiErro('Digite o código de 6 números.');
        await widget.estado.entrar(_cpfDigitos, _codigo.text);
        if (mounted) Navigator.pop(context, true);
      });

  @override
  Widget build(BuildContext context) {
    final etapaCodigo = _celularMascarado != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(etapaCodigo ? 'Digite o código' : 'Entrar para gerar o condicional',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!etapaCodigo) ...[
            const Text('Informe seu CPF. Enviaremos um código para o WhatsApp cadastrado na loja.'),
            const SizedBox(height: 16),
            TextField(
              controller: _cpf,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              decoration: const InputDecoration(labelText: 'CPF (só números)'),
              onSubmitted: (_) => _pedirCodigo(),
            ),
          ] else ...[
            Text('Enviamos um código para $_celularMascarado.'),
            const SizedBox(height: 16),
            TextField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: const InputDecoration(labelText: 'Código'),
              onSubmitted: (_) => _confirmar(),
            ),
          ],
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bloqueioCadastro ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_erro!),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregando ? null : (etapaCodigo ? _confirmar : _pedirCodigo),
            child: _carregando
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(etapaCodigo ? 'Confirmar' : 'Enviar código'),
          ),
          if (etapaCodigo)
            TextButton(
              onPressed: _carregando ? null : () => setState(() { _celularMascarado = null; _erro = null; }),
              child: const Text('Trocar CPF / pedir novo código'),
            ),
        ]),
      ),
    );
  }
}
