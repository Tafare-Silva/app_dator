import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/produto_model.dart';
import '../../services/produto_service.dart';
import '../../core/app_theme.dart';

class ProdutosScreen extends StatefulWidget {
  final VoidCallback? onVoltarDashboard;
  final VoidCallback? onAbrirMenu;
  const ProdutosScreen({super.key, this.onVoltarDashboard, this.onAbrirMenu});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _service = ProdutoService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _buscaCtrl = TextEditingController();

  List<ProdutoResumo> _produtos = [];
  List<ProdutoResumo> _produtosFiltrados = [];
  bool _carregando = false;
  String? _erro;
  bool _apenasAtivos = true;
  _TipoBusca _tipoBusca = _TipoBusca.nome;

  // ✅ Não carrega nada no initState — usuário precisa buscar
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar({String? busca, String? codigoBarras, int? pkChaveExato}) async {
  setState(() { _carregando = true; _erro = null; });
  try {
    final produtos = await _service.listarProdutos(
      apenasAtivos: _apenasAtivos,
      busca: busca,
      codigoBarras: codigoBarras,
      pkChaveExato: pkChaveExato,
      limit: 500,
    );
    setState(() {
      _produtos = produtos;
      _produtosFiltrados = produtos;
      _carregando = false;
    });
  } catch (e) {
    setState(() { _erro = 'Erro ao carregar produtos.'; _carregando = false; });
  }
}

  void _onBuscaChanged(String termo) {
  if (termo.isEmpty) {
    setState(() { _produtos = []; _produtosFiltrados = []; });
    return;
  }
  // Para nome: filtra localmente se já carregou, senão vai na API
  if (_tipoBusca == _TipoBusca.nome) {
    if (_produtos.isNotEmpty) {
      setState(() {
        _produtosFiltrados = _produtos
            .where((p) => (p.nome ?? '').toLowerCase().contains(termo.toLowerCase()))
            .toList();
      });
    } else {
      _carregar(busca: termo);
    }
  }
  // Para código e código de barras: aguarda o usuário confirmar (Enter ou câmera)
  // não faz nada enquanto digita para evitar chamadas desnecessárias
}

  // Dispara busca ao pressionar Enter/confirmar no teclado
  void _onBuscaSubmitted(String termo) {
  if (termo.isEmpty) return;
  if (_tipoBusca == _TipoBusca.nome) {
    _carregar(busca: termo);
  } else if (_tipoBusca == _TipoBusca.codigo) {
    // ✅ busca exata por pk_chave via API
    final pk = int.tryParse(termo.trim());
    if (pk != null) {
      _carregar(pkChaveExato: pk);
    }
  } else {
    // código de barras — busca na tabela e no pk_chave
    _carregar(codigoBarras: termo);
  }
}

  Future<void> _abrirCamera() async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (resultado != null && mounted) {
      _buscaCtrl.text = resultado;
      setState(() => _tipoBusca = _TipoBusca.codigoBarras);
      _carregar(codigoBarras: resultado);
    }
  }

  void _abrirDetalhe(ProdutoResumo produto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalheProdutoSheet(produto: produto, fmt: _fmt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Produtos'),
        // ✅ usa callback do pai para abrir drawer
        leading: widget.onVoltarDashboard != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onVoltarDashboard)
            : IconButton(icon: const Icon(Icons.menu), onPressed: widget.onAbrirMenu),
        actions: [
          IconButton(
            icon: Icon(_apenasAtivos ? Icons.visibility : Icons.visibility_off, color: _apenasAtivos ? AppTheme.primary : AppTheme.textMuted),
            tooltip: _apenasAtivos ? 'Apenas ativos' : 'Todos',
            onPressed: () { setState(() { _apenasAtivos = !_apenasAtivos; _buscaCtrl.clear(); _produtos = []; _produtosFiltrados = []; }); },
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor tipo busca
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: _TipoBusca.values.map((tipo) {
                final sel = _tipoBusca == tipo;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _tipoBusca = tipo; _buscaCtrl.clear(); _produtosFiltrados = _produtos; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? AppTheme.primary : Colors.transparent, width: 2))),
                      child: Text(tipo.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? AppTheme.primary : AppTheme.textMuted)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Campo busca
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaCtrl,
                    onChanged: _onBuscaChanged,
                    onSubmitted: _onBuscaSubmitted,
                    textInputAction: TextInputAction.search,
                    keyboardType: _tipoBusca == _TipoBusca.codigoBarras ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(
                      hintText: _tipoBusca.hint,
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                      suffixIcon: _buscaCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _buscaCtrl.clear(); setState(() { _produtos = []; _produtosFiltrados = []; }); })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                if (_tipoBusca == _TipoBusca.codigoBarras || _tipoBusca == _TipoBusca.codigo) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _abrirCamera,
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                    tooltip: 'Ler código de barras',
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ],
            ),
          ),

          // Contador (só aparece quando há resultados)
          if (!_carregando && _erro == null && _produtosFiltrados.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withValues(alpha: 0.07),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text('${_produtosFiltrados.length} produto${_produtosFiltrados.length != 1 ? "s" : ""}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
                  const Spacer(),
                  Text(_apenasAtivos ? 'Apenas ativos' : 'Todos', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),

          // Conteúdo
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(_erro!, style: const TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(onPressed: () => _onBuscaSubmitted(_buscaCtrl.text), icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    // ✅ Tela inicial vazia — orienta o usuário a buscar
                    : _produtos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('Busque um produto pelo nome,', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                                const Text('código ou código de barras.', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                              ],
                            ),
                          )
                        : _produtosFiltrados.isEmpty
                            ? const Center(child: Text('Nenhum produto encontrado.', style: TextStyle(color: AppTheme.textMuted)))
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _produtosFiltrados.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (_, i) => _CardProduto(produto: _produtosFiltrados[i], fmt: _fmt, onTap: () => _abrirDetalhe(_produtosFiltrados[i])),
                              ),
          ),
        ],
      ),
    );
  }
}

enum _TipoBusca {
  nome('Nome', 'Buscar por nome...'),
  codigo('Código', 'Buscar por código...'),
  codigoBarras('Cód. Barras', 'Digite ou escaneie...');

  final String label;
  final String hint;
  const _TipoBusca(this.label, this.hint);
}

class _CardProduto extends StatelessWidget {
  final ProdutoResumo produto;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _CardProduto({required this.produto, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final estoqueColor = produto.estoque <= 0 ? Colors.red : produto.estoque < 5 ? Colors.orange : Colors.green;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produto.nome ?? 'Produto #${produto.pkChave}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    // ✅ Código interno (pk_chave)
                    Text('Cód: ${produto.pkChave}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    if (produto.referenciaFabrica != null)
                      Text('Ref: ${produto.referenciaFabrica}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.warehouse_outlined, size: 12, color: estoqueColor),
                      const SizedBox(width: 4),
                      Text(
                        'Estoque: ${produto.estoque % 1 == 0 ? produto.estoque.toStringAsFixed(0) : produto.estoque.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: estoqueColor, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(produto.precoVenda), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheProdutoSheet extends StatelessWidget {
  final ProdutoResumo produto;
  final NumberFormat fmt;
  const _DetalheProdutoSheet({required this.produto, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final estoqueColor = produto.estoque <= 0 ? Colors.red : produto.estoque < 5 ? Colors.orange : Colors.green;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(produto.nome ?? 'Produto #${produto.pkChave}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(child: _CardDestaque(label: 'Preço de Venda', valor: fmt.format(produto.precoVenda), cor: AppTheme.primary, icone: Icons.attach_money)),
                    const SizedBox(width: 12),
                    Expanded(child: _CardDestaque(
                      label: 'Estoque',
                      valor: produto.estoque % 1 == 0 ? produto.estoque.toStringAsFixed(0) : produto.estoque.toStringAsFixed(2),
                      cor: estoqueColor,
                      icone: Icons.warehouse_outlined,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Informações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                _InfoRow('Código', '${produto.pkChave}'),
                if (produto.referenciaFabrica != null) _InfoRow('Referência', produto.referenciaFabrica!),
                if (produto.marca != null) _InfoRow('Marca', produto.marca!),
                if (produto.divisao != null) _InfoRow('Divisão', produto.divisao!),
                if (produto.categoria != null) _InfoRow('Categoria', produto.categoria!),
                if (produto.colecao != null) _InfoRow('Coleção', produto.colecao!),
                if (produto.cor != null) _InfoRow('Cor', produto.cor!),
                if (produto.tamanho != null) _InfoRow('Tamanho', produto.tamanho!),
                if (produto.genero != null) _InfoRow('Gênero', produto.genero!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDestaque extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final IconData icone;
  const _CardDestaque({required this.label, required this.valor, required this.cor, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: cor.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ centralizado
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cor), textAlign: TextAlign.center)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  const _InfoRow(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();
  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

// Deliberadamente SEM restrição de "formats": tentamos restringir a formatos
// 1D comuns antes, mas isso piorou a leitura das etiquetas próprias da loja —
// sinal de que o formato usado não estava na lista, então a restrição forçava
// decodificações erradas em vez de deixar o mobile_scanner reconhecer o
// formato certo (que ele identifica automaticamente quando não é restringido).

class _ScannerScreenState extends State<_ScannerScreen> {
  // No Android, sem especificar isso o mobile_scanner usa 640x480 por padrão
  // — resolução baixa demais pra ler um código de barras a uma distância
  // confortável, obrigando o usuário a chegar muito perto (e aí a câmera não
  // consegue focar direito, embaçando a imagem e gerando leituras erradas).
  // Pedimos 4K (o plugin cai pra maior resolução disponível se não suportar) —
  // mais pixels por barra ajuda a resolver os elementos mais finos do código
  // (o primeiro a "borrar" conforme a distância aumenta). Torch ligado por
  // padrão aumenta o contraste e permite obturador mais rápido (menos blur de
  // movimento). "unrestricted" analisa todo frame sem intervalo, aumentando a
  // chance de capturar um frame nítido em vez de esperar 250ms entre tentativas.
  final _controller = MobileScannerController(
    cameraResolution: const Size(3840, 2160),
    torchEnabled: true,
    detectionSpeed: DetectionSpeed.unrestricted,
  );
  bool _escaneado = false;

  // Exige a MESMA leitura duas vezes seguidas antes de aceitar. Uma leitura
  // corrompida por instabilidade da câmera (blur, ângulo, reflexo) raramente
  // se repete de forma idêntica no frame seguinte — já uma leitura correta,
  // com o código ainda em quadro, se repete naturalmente. Isso filtra a
  // grande maioria dos falsos positivos sem precisar saber a causa exata.
  String? _ultimoCodigoLido;
  int _leiturasConsecutivas = 0;
  static const _leiturasNecessarias = 2;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  static const _larguraJanela = 260.0;
  static const _alturaJanela = 120.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear código de barras'),
        actions: [IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch())],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // A área de leitura real é restrita ao retângulo desenhado na tela
          // (scanWindow) — sem isso, o mobile_scanner lê o frame inteiro da
          // câmera, incluindo etiquetas vizinhas fora da mira (comum em roupas
          // penduradas lado a lado), o que causava leitura do código errado.
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
                    border: Border.all(color: _leiturasConsecutivas > 0 ? Colors.amber : AppTheme.primary, width: 2),
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
              const Positioned(bottom: 40, left: 0, right: 0, child: Text('Aponte para o código de barras', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14))),
            ],
          );
        },
      ),
    );
  }
}