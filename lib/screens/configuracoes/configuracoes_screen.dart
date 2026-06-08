import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/config_service.dart';
import '../../services/services.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _config = ConfigService();
  final _impressaoService = ImpressaoService();

  final _nomeEmpresaCtrl = TextEditingController();
  final _servidorIpCtrl = TextEditingController();
  final _servidorPortaCtrl = TextEditingController();
  final _impressoraIpCtrl = TextEditingController();
  final _impressoraPortaCtrl = TextEditingController();

  bool _salvando = false;
  bool _testando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    _nomeEmpresaCtrl.text = await _config.getNomeEmpresa();
    _servidorIpCtrl.text = await _config.getServidorIp();
    _servidorPortaCtrl.text = (await _config.getServidorPorta()).toString();
    _impressoraIpCtrl.text = await _config.getImpressoraIp();
    _impressoraPortaCtrl.text = (await _config.getImpressoraPorta()).toString();
    setState(() {});
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await _config.salvar(
      nomeEmpresa: _nomeEmpresaCtrl.text.trim(),
      servidorIp: _servidorIpCtrl.text.trim(),
      servidorPorta: int.tryParse(_servidorPortaCtrl.text.trim()),
      impressoraIp: _impressoraIpCtrl.text.trim(),
      impressoraPorta: int.tryParse(_impressoraPortaCtrl.text.trim()),
    );
    setState(() => _salvando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testarImpressora() async {
    final ip = _impressoraIpCtrl.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o IP da impressora.')),
      );
      return;
    }
    setState(() => _testando = true);
    final ok = await _impressaoService.testarConexao(
      impressoraIp: ip,
      impressoraPorta: int.tryParse(_impressoraPortaCtrl.text.trim()) ?? 9100,
    );
    setState(() => _testando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✅ Impressora acessível!' : '❌ Impressora não respondeu.'),
          backgroundColor: ok ? Colors.green : AppTheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeEmpresaCtrl.dispose();
    _servidorIpCtrl.dispose();
    _servidorPortaCtrl.dispose();
    _impressoraIpCtrl.dispose();
    _impressoraPortaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Secao(titulo: '🏪 Empresa', children: [
            _Campo(
              controller: _nomeEmpresaCtrl,
              label: 'Nome da Empresa (impresso no PDF)',
              hint: 'Ex: PURO ESTILO ADULTO BANDEIRANTES',
              teclado: TextInputType.text,
            ),
          ]),
          const SizedBox(height: 24),
          _Secao(titulo: '🖥️ Servidor Backend', children: [
            _Campo(
              controller: _servidorIpCtrl,
              label: 'IP do Servidor',
              hint: 'Ex: 192.168.1.100',
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Campo(
              controller: _servidorPortaCtrl,
              label: 'Porta',
              hint: '8000',
              teclado: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 24),
          _Secao(titulo: '🖨️ Impressora Térmica (Cozinha)', children: [
            _Campo(
              controller: _impressoraIpCtrl,
              label: 'IP da Impressora',
              hint: 'Ex: 192.168.1.200',
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Campo(
              controller: _impressoraPortaCtrl,
              label: 'Porta',
              hint: '9100',
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _testando ? null : _testarImpressora,
              icon: _testando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering),
              label: const Text('Testar conexão com impressora'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
              ),
            ),
          ]),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Secao({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType teclado;

  const _Campo({
    required this.controller,
    required this.label,
    required this.hint,
    required this.teclado,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}