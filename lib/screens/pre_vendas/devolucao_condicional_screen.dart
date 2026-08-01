import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_theme.dart';
import '../../models/cliente_model.dart';
import '../../models/vendas_models.dart';
import '../../services/cliente_service.dart';
import '../../services/vendas_service.dart';

class DevolucaoCondicionalScreen extends StatefulWidget {
  const DevolucaoCondicionalScreen({super.key});

  @override
  State<DevolucaoCondicionalScreen> createState() => _DevolucaoCondicionalScreenState();
}

class _DevolucaoCondicionalScreenState extends State<DevolucaoCondicionalScreen> {
  final _vendasService = VendasService();
  final _clienteService = ClienteService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');
  final _numeroCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();

  // 'numero' ou 'cliente'
  String _modoBusca = 'numero';

  bool _carregando = false;
  bool _processando = false;
  String? _erro;
  Cliente? _clienteSelecionado;
  List<PreVendaDetalhe> _resultados = [];

  // Total de itens no momento em que a busca trouxe os condicionais — fixo
  // até a próxima busca, usado como base pros contadores "devolvendo/ficam".
  int _totalOriginal = 0;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  int get _totalRestante => _resultados.fold(0, (s, g) => s + g.itens.length);
  int get _totalDevolvido => _totalOriginal - _totalRestante;

  // ── Busca ─────────────────────────────────────────────────────────────────────

  Future<void> _buscarPorNumero() async {
    final id = int.tryParse(_numeroCtrl.text.trim());
    if (id == null) {
      setState(() => _erro = 'Digite um número de condicional válido.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
      _resultados = [];
      _totalOriginal = 0;
    });
    try {
      final detalhe = await _vendasService.getPreVendaDetalhe(id);
      if (detalhe.efetivada) {
        setState(() => _erro = 'O condicional #$id já foi efetivado — não é possível devolver itens.');
      } else {
        setState(() {
          _resultados = [detalhe];
          _totalOriginal = detalhe.itens.length;
        });
      }
    } catch (_) {
      setState(() => _erro = 'Condicional #$id não encontrado.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarCliente() async {
    final cliente = await showDialog<Cliente>(
      context: context,
      builder: (_) => _BuscaClienteDialog(service: _clienteService),
    );
    if (cliente == null) return;

    setState(() {
      _clienteSelecionado = cliente;
      _carregando = true;
      _erro = null;
      _resultados = [];
      _totalOriginal = 0;
    });
    try {
      final abertos = await _vendasService.listarPreVendas(
        clienteId: cliente.pkChave,
        efetivada: false,
        // O padrão do serviço só traz "hoje" — aqui precisamos de todo o
        // histórico de condicionais em aberto do cliente.
        dataInicio: DateTime(2020, 1, 1),
        dataFim: DateTime.now().add(const Duration(days: 365)),
      );
      if (abertos.isEmpty) {
        setState(() => _erro = 'Nenhum condicional em aberto para ${cliente.nome}.');
        return;
      }
      final detalhes = await Future.wait(
        abertos.map((pv) => _vendasService.getPreVendaDetalhe(pv.pkChave)),
      );
      setState(() {
        _resultados = detalhes;
        _totalOriginal = detalhes.fold(0, (s, g) => s + g.itens.length);
      });
    } catch (_) {
      setState(() => _erro = 'Erro ao buscar condicionais do cliente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Leitura / devolução ──────────────────────────────────────────────────────

  Future<void> _abrirScanner() async {
    final codigo = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (codigo != null && mounted) _processarCodigo(codigo);
  }

  void _processarCodigoDigitado() {
    final codigo = _codigoCtrl.text.trim();
    _codigoCtrl.clear();
    if (codigo.isNotEmpty) _processarCodigo(codigo);
  }

  void _processarCodigo(String codigo) {
    final pk = int.tryParse(codigo.trim());
    if (pk == null) {
      _mostrarMensagem('Código inválido: $codigo', erro: true);
      return;
    }

    for (final grupo in _resultados) {
      for (final item in grupo.itens) {
        if (item.produtoId == pk) {
          _devolverItem(grupo, item);
          return;
        }
      }
    }
    _mostrarMensagem('Código $codigo não pertence a nenhum condicional encontrado.', erro: true);
  }

  Future<void> _devolverItem(PreVendaDetalhe grupo, ItemVenda item) async {
    setState(() => _processando = true);
    try {
      await _vendasService.devolverItemPreVenda(grupo.pkChave, item.pkChave);
      setState(() => grupo.itens.removeWhere((i) => i.pkChave == item.pkChave));
      _mostrarUndo(grupo, item);
    } catch (e) {
      _mostrarMensagem('Erro: $e', erro: true);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _restaurarItem(PreVendaDetalhe grupo, ItemVenda item) async {
    setState(() => _processando = true);
    try {
      final novo = await _vendasService.restaurarItemPreVenda(grupo.pkChave, item);
      setState(() => grupo.itens.add(novo));
      _mostrarMensagem('${item.produtoNome ?? "Item"} voltou pro condicional.');
    } catch (e) {
      _mostrarMensagem('Erro ao desfazer: $e', erro: true);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarUndo(PreVendaDetalhe grupo, ItemVenda item) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.produtoNome ?? "Item"} devolvido.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'DESFAZER',
          textColor: Colors.white,
          onPressed: () => _restaurarItem(grupo, item),
        ),
      ),
    );
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: erro ? Colors.red : Colors.green),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Devolução de Condicional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Ler código de barras',
            onPressed: _resultados.isEmpty ? null : _abrirScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SegmentoBusca(
                        label: 'Por Número',
                        icone: Icons.tag,
                        selecionado: _modoBusca == 'numero',
                        onTap: () => setState(() => _modoBusca = 'numero'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentoBusca(
                        label: 'Por Cliente',
                        icone: Icons.person_outline,
                        selecionado: _modoBusca == 'cliente',
                        onTap: () => setState(() => _modoBusca = 'cliente'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_modoBusca == 'numero')
                  TextField(
                    controller: _numeroCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Número do condicional',
                      hintText: 'Ex: 82372',
                      prefixIcon: const Icon(Icons.numbers),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _buscarPorNumero,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _buscarPorNumero(),
                  )
                else
                  InkWell(
                    onTap: _selecionarCliente,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                              ),
                            ),
                          ),
                          const Icon(Icons.search, size: 16, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                if (_resultados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codigoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Digitar código do item',
                            prefixIcon: Icon(Icons.keyboard),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _processarCodigoDigitado(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _habilitadoSeNaoProcessando(_processarCodigoDigitado),
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _EstatChip(rotulo: 'No condicional', valor: _totalOriginal, cor: AppTheme.textDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _EstatChip(rotulo: 'Devolvendo', valor: _totalDevolvido, cor: Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _EstatChip(rotulo: 'Ficam', valor: _totalRestante, cor: Colors.green)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
                        ),
                      )
                    : _resultados.isEmpty
                        ? const Center(
                            child: Text('Busque um condicional por número ou cliente.',
                                style: TextStyle(color: AppTheme.textMuted)),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              for (final grupo in _resultados) ...[
                                _CabecalhoCondicional(grupo: grupo, fmt: _fmt, fmtData: _fmtData),
                                if (grupo.itens.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('Todos os itens deste condicional foram devolvidos.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  )
                                else
                                  for (final item in grupo.itens)
                                    _ItemDevolucao(
                                      item: item,
                                      fmt: _fmt,
                                      onTap: _processando ? null : () => _devolverItem(grupo, item),
                                    ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _habilitadoSeNaoProcessando(VoidCallback fn) => _processando ? null : fn;
}

// ── Cabeçalho do condicional ────────────────────────────────────────────────────

class _CabecalhoCondicional extends StatelessWidget {
  final PreVendaDetalhe grupo;
  final NumberFormat fmt;
  final DateFormat fmtData;

  const _CabecalhoCondicional({required this.grupo, required this.fmt, required this.fmtData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Condicional #${grupo.pkChave} — ${fmtData.format(grupo.data)}'
              '${grupo.clienteNome != null ? " — ${grupo.clienteNome}" : ""}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item de devolução ────────────────────────────────────────────────────────────
// Todo item que aparece na lista é, por definição, "ainda no condicional" — o
// que já foi devolvido é removido de verdade (ver _devolverItem), não fica
// aqui marcado. Tocar no item devolve.

class _ItemDevolucao extends StatelessWidget {
  final ItemVenda item;
  final NumberFormat fmt;
  final VoidCallback? onTap;

  const _ItemDevolucao({required this.item, required this.fmt, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.radio_button_unchecked, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.produtoNome ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    maxLines: 2,
                  ),
                  Text('Cód: ${item.produtoId}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Text(fmt.format(item.vrTotalLiquido),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ],
        ),
      ),
    );
  }
}

// ── Chip de estatística (contador) ──────────────────────────────────────────────

class _EstatChip extends StatelessWidget {
  final String rotulo;
  final int valor;
  final Color cor;

  const _EstatChip({required this.rotulo, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text('$valor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
          Text(rotulo, style: TextStyle(fontSize: 10, color: cor)),
        ],
      ),
    );
  }
}

// ── Toggle de modo de busca ──────────────────────────────────────────────────────

class _SegmentoBusca extends StatelessWidget {
  final String label;
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;

  const _SegmentoBusca({required this.label, required this.icone, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? AppTheme.primary : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: selecionado ? Colors.white : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selecionado ? Colors.white : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de busca de cliente (cópia do padrão usado em Nova Pré-Venda) ──────

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
  Object? _debounceToken;

  void _buscar(String termo) async {
    final meuToken = Object();
    _debounceToken = meuToken;
    if (termo.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (_debounceToken != meuToken || !mounted) return;
    setState(() => _buscando = true);
    try {
      final r = await widget.service.buscarClientes(termo);
      if (mounted && _debounceToken == meuToken) setState(() => _resultados = r);
    } finally {
      if (mounted && _debounceToken == meuToken) setState(() => _buscando = false);
    }
  }

  @override
  void dispose() {
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
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline, color: AppTheme.primary),
                      title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
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

// ── Scanner (mesmo padrão testado em Nova Pré-Venda / Produtos) ────────────────

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  // Sem restrição de "formats" (deixa o mobile_scanner reconhecer sozinho) +
  // resolução 4K + torch ligado + detecção sem intervalo — combinação que se
  // mostrou mais confiável nos outros dois módulos que já usam scanner.
  final _controller = MobileScannerController(
    cameraResolution: const Size(3840, 2160),
    torchEnabled: true,
    detectionSpeed: DetectionSpeed.unrestricted,
  );
  bool _escaneado = false;

  // Exige a MESMA leitura duas vezes seguidas antes de aceitar.
  String? _ultimoCodigoLido;
  int _leiturasConsecutivas = 0;
  static const _leiturasNecessarias = 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _larguraJanela = 260.0;
  static const _alturaJanela = 120.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler Código do Item'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tamanho = constraints.biggest;
          final scanWindow = Rect.fromCenter(
            center: tamanho.center(Offset.zero),
            width: _larguraJanela,
            height: _alturaJanela,
          );
          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: (capture) {
                  if (_escaneado) return;
                  final codigo = capture.barcodes.firstOrNull?.rawValue;
                  if (codigo == null) return;

                  if (codigo == _ultimoCodigoLido) {
                    _leiturasConsecutivas++;
                  } else {
                    _ultimoCodigoLido = codigo;
                    _leiturasConsecutivas = 1;
                  }

                  if (_leiturasConsecutivas >= _leiturasNecessarias) {
                    _escaneado = true;
                    Navigator.pop(context, codigo);
                  } else {
                    setState(() {});
                  }
                },
              ),
              Center(
                child: Container(
                  width: _larguraJanela,
                  height: _alturaJanela,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _leiturasConsecutivas > 0 ? Colors.amber : AppTheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_leiturasConsecutivas > 0)
                Positioned(
                  bottom: 90, left: 0, right: 0,
                  child: Text(
                    'Confirmando leitura de "$_ultimoCodigoLido"...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
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
          );
        },
      ),
    );
  }
}
