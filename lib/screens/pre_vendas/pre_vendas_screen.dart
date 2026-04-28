import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendas_models.dart';
import '../../services/1vendas_service.dart';
import '../../core/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PreVendasScreen extends StatefulWidget {
  const PreVendasScreen({super.key});

  @override
  State<PreVendasScreen> createState() => _PreVendasScreenState();
}

class _PreVendasScreenState extends State<PreVendasScreen> {
  final _service = VendasService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  late Future<List<PreVenda>> _futuroPreVendas;
  late Future<List<Vendedor>> _futuroVendedores;

  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _vendedorSelecionado;
  bool? _efetivada;
  List<Vendedor> _vendedores = [];

  @override
  void initState() {
    super.initState();
    _futuroVendedores = _service.listarVendedores();
    _futuroVendedores.then((v) => setState(() => _vendedores = v));
    _carregar();
  }

  void _carregar() {
    _futuroPreVendas = _service.listarPreVendas(
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      vendedorId: _vendedorSelecionado,
      efetivada: _efetivada,
    );
    setState(() {});
  }

  Future<void> _selecionarPeriodo() async {
      // ✅ SOLUÇÃO 3: Diálogo customizado com campos de data com máscara
      final inicioController = TextEditingController(
        text: _dataInicio != null ? _fmtData.format(_dataInicio!) : '',
      );
      final fimController = TextEditingController(
        text: _dataFim != null ? _fmtData.format(_dataFim!) : '',
      );

      final maskFormatter = MaskTextInputFormatter(
        mask: '##/##/####',  // dd/mm/yyyy
        filter: {"#": RegExp(r'[0-9]')},
      );

      final result = await showDialog<DateTimeRange?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selecionar Período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo início COM MÁSCARA
              TextFormField(
                controller: inicioController,
                decoration: const InputDecoration(
                  labelText: 'Data Início (dd/mm/yyyy)',
                  hintText: '01/01/2025',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [maskFormatter],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Campo fim COM MÁSCARA
              TextFormField(
                controller: fimController,
                decoration: const InputDecoration(
                  labelText: 'Data Fim (dd/mm/yyyy)',
                  hintText: '31/12/2025',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [maskFormatter],
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  // Parse das datas (dd/mm/yyyy)
                  final inicio = _parseDataBR(inicioController.text);
                  final fim = _parseDataBR(fimController.text);

                  if (inicio != null && fim != null) {
                    Navigator.pop(
                      context,
                      DateTimeRange(start: inicio, end: fim),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data inválida')),
                    );
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao processar datas')),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (result != null) {
        _dataInicio = result.start;
        _dataFim = result.end;
        _carregar();
      }
    }

    // ✅ FUNÇÃO AUXILIAR para converter dd/mm/yyyy em DateTime
    DateTime? _parseDataBR(String data) {
      try {
        final parts = data.split('/');
        if (parts.length != 3) return null;
        final dia = int.tryParse(parts[0]);
        final mes = int.tryParse(parts[1]);
        final ano = int.tryParse(parts[2]);
        if (dia == null || mes == null || ano == null) return null;
        return DateTime(ano, mes, dia);
      } catch (_) {
        return null;
      }
    }
  void _limparFiltros() {
    _dataInicio = null;
    _dataFim = null;
    _vendedorSelecionado = null;
    _efetivada = null;
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,  // ← AJUSTE 1: Adicionado para evitar overflow no teclado (consistente com login/dashboard, elimina faixas de aviso)
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pré-Vendas / Condicionais'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _limparFiltros,
              tooltip: 'Limpar filtros'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(
        children: [
          // Filtros (preservado, mas com ellipsis no período para não quebrar)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                // Período (ajustado para textos longos)
                GestureDetector(
                  onTap: _selecionarPeriodo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Flexible(  // ← AJUSTE 2: Adicionado Flexible para texto do período escalar sem quebrar o container
                          child: Text(
                            _dataInicio != null && _dataFim != null
                                ? '${_fmtData.format(_dataInicio!)} — ${_fmtData.format(_dataFim!)}'
                                : 'Selecionar período',
                            style: TextStyle(
                              fontSize: 12,  // ← AJUSTE 3: Mantido 12px, mas com FittedBox abaixo para caber
                              color: _dataInicio != null
                                  ? AppTheme.textDark
                                  : AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,  // Trunca períodos longos (ex: "01/03/2025 — 31/12/2025" vira "01/03/2025 — 31/12...")
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_vendedores.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _vendedorSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Vendedor',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ..._vendedores.map((v) => DropdownMenuItem(
                                  value: v.pkChave,
                                  child: Text(v.nome ?? '—',
                                      overflow: TextOverflow.ellipsis),  // Preservado
                                )),
                          ],
                          onChanged: (v) {
                            _vendedorSelecionado = v;
                            _carregar();
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _efetivada,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: false, child: Text('Pendentes')),
                          DropdownMenuItem(value: true, child: Text('Efetivadas')),
                        ],
                        onChanged: (v) {
                          _efetivada = v;
                          _carregar();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista com totalizador (ajustado para overflow direito)
          Expanded(
            child: FutureBuilder<List<PreVenda>>(
              future: _futuroPreVendas,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: ElevatedButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente')),
                  );
                }

                final preVendas = snap.data ?? [];

                if (preVendas.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma pré-venda encontrada.',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }

                // Totalizadores (ajustado para valor não transbordar)
               
                final pendentes = preVendas.where((p) => !p.efetivada).length;
                final efetivadas = preVendas.where((p) => p.efetivada).length;

                return Column(
                  children: [
                    // Barra de totais (sem valor monetário total)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${preVendas.length} total',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          if (pendentes > 0)
                            _ChipTotal(
                                label: '$pendentes pendente${pendentes > 1 ? "s" : ""}',
                                cor: Colors.orange),
                          if (efetivadas > 0) ...[
                            const SizedBox(width: 6),
                            _ChipTotal(
                                label: '$efetivadas efetivada${efetivadas > 1 ? "s" : ""}',
                                cor: Colors.green),
                          ],
                          // ← MUDANÇA: Removido Spacer() e Text do valor total – agora os chips ficam alinhados à direita, clean e focado em quantidades
                        ],
                      ),
                    ),

                    // Lista (preservada, com todos os ajustes anteriores)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: preVendas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CardPreVenda(
                          preVenda: preVendas[i],
                          fmt: _fmt,
                          fmtData: _fmtData,
                          onTap: () => _abrirDetalhe(preVendas[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(PreVenda preVenda) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalhePreVendaSheet(
        preVenda: preVenda,
        fmt: _fmt,
        fmtData: _fmtData,
        service: _service,
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ChipTotal extends StatelessWidget {
  final String label;
  final Color cor;
  const _ChipTotal({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
    );
  }
}

class _CardPreVenda extends StatelessWidget {
  final PreVenda preVenda;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VoidCallback onTap;

  const _CardPreVenda({
    required this.preVenda,
    required this.fmt,
    required this.fmtData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusCor = preVenda.efetivada ? Colors.green : Colors.orange;
    final statusTexto = preVenda.efetivada ? 'Efetivada' : 'Pendente';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(  // ← AJUSTE 6: Row ajustado com spaceBetween para alinhar nome/status
                mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Alinha nome à esquerda, status à direita
                children: [
                  Flexible(  // ← AJUSTE 7: Flexible + FittedBox para nome escalar (ex: "TAFAREL ROCHA DA SILVA" cabe em 1 linha sem transbordar)
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        preVenda.clienteNome ?? 'Sem cliente',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,  // ← AJUSTE 8: Reduzido de 15px para 14px (cabe nomes longos sem quebrar linha)
                            color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,  // Trunca se necessário (ex: "TAFAREL ROCHA DA SILVA" vira "TAFAREL ROCHA...")
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusCor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusTexto,
                        style: TextStyle(
                            color: statusCor,
                            fontSize: 12,  // Mantido 12px para status compacto
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(  // ← AJUSTE 9: Row com spaceEvenly para vendedor/data caberem sem desalinhar
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // Distribui espaço uniformemente
                children: [
                  Flexible(  // ← AJUSTE 10: Flexible para vendedor escalar
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Flexible(  // Nested Flexible para texto
                          child: Text(preVenda.vendedorNome ?? '—',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(  // ← AJUSTE 11: Flexible para data escalar
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(fmtData.format(preVenda.data),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (preVenda.dataEntrega != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('Entrega: ${fmtData.format(preVenda.dataEntrega!)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(  // ← AJUSTE 12: Row com spaceBetween para itens/valor alinhar perfeitamente (evita transbordar "R$ 302,56 >")
                mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Alinha itens à esquerda, valor à direita
                children: [
                  Text(
                    '${preVenda.quantidadeItens} ${preVenda.quantidadeItens == 1 ? "item" : "itens"}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                  Flexible(  // ← AJUSTE 13: Flexible + FittedBox para valor escalar (cabe "R$ 302,56 >" sem faixa amarela)
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,  // Mantém compacto
                        children: [
                          Text(fmt.format(preVenda.vrTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,  // ← AJUSTE 14: Reduzido de 15px para 14px (cabe valores longos)
                                  color: AppTheme.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Sheet de detalhe da pré-venda ──────────────────────────────────────

class _DetalhePreVendaSheet extends StatelessWidget {
  final PreVenda preVenda;
  final NumberFormat fmt;
  final DateFormat fmtData;
  final VendasService service;

  const _DetalhePreVendaSheet({
    required this.preVenda,
    required this.fmt,
    required this.fmtData,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final statusCor = preVenda.efetivada ? Colors.green : Colors.orange;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Handle (preservado)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Título (ajustado para nome longo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: AppTheme.primary),
                const SizedBox(width: 8),
                Flexible(  // ← AJUSTE 15: Flexible + FittedBox para nome do cliente escalar no título do sheet
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      preVenda.clienteNome ?? 'Sem cliente',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusCor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    preVenda.efetivada ? 'Efetivada' : 'Pendente',
                    style: TextStyle(
                        color: statusCor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Conteúdo — busca os itens do backend (ajustado para nomes longos)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _buscarItens(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final itens = snap.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _InfoRow('Vendedor', preVenda.vendedorNome ?? '—'),
                    _InfoRow('Data', fmtData.format(preVenda.data)),
                    if (preVenda.dataEntrega != null)
                      _InfoRow('Entrega', fmtData.format(preVenda.dataEntrega!)),
                    if (preVenda.condicaoPagamento != null)
                      _InfoRow('Cond. Pgto', preVenda.condicaoPagamento!),
                    const SizedBox(height: 12),
                    const Text('Itens',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    if (itens.isEmpty)
                      const Text('Nenhum item encontrado.',
                          style: TextStyle(color: AppTheme.textMuted))
                    else
                      ...itens.map((item) => _ItemPreVendaRow(
                          item: item, fmt: fmt)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark)),
                        FittedBox(  // ← AJUSTE 16: Adicionado FittedBox para total escalar no sheet (cabe valores longos)
                          fit: BoxFit.scaleDown,
                          child: Text(
                            fmt.format(preVenda.vrTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buscarItens() async {
    try {
      final preVendaDetalhe = await service.getPreVendaDetalhe(preVenda.pkChave);
      return preVendaDetalhe.itens  // ← Agora é sempre List<ItemVenda>, nunca null
          .map((i) => {
                'produto_nome': i.produtoNome ?? 'Produto #${i.produtoId}',
                'quantidade': i.quantidade,
                'vr_unitario_bruto': i.vrUnitarioBruto,
                'vr_total_liquido': i.vrTotalLiquido,
                'vr_desconto_total': i.vrDescontoTotal,
                'item_devolvido': i.itemDevolvido,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  const _InfoRow(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(  // ← CORREÇÃO: maxLines e overflow agora explicitamente no Text, com indentação limpa
                valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPreVendaRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat fmt;
  const _ItemPreVendaRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final qtd = (item['quantidade'] as double);
    final qtdStr = qtd == qtd.truncateToDouble()
        ? qtd.toStringAsFixed(0)
        : qtd.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SOLUÇÃO 2: REMOVIDO FittedBox, usando Expanded + softWrap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['produto_nome'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                  softWrap: true,  // ← DEIXA QUEBRAR LINHA
                  maxLines: 3,     // MÁXIMO 3 LINHAS (se for muito longo)
                ),
                const SizedBox(height: 2),
                Text(
                  '$qtdStr x ${fmt.format(item['vr_unitario_bruto'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                if ((item['vr_desconto_total'] as double) > 0)
                  Text(
                    'Desconto: ${fmt.format(item['vr_desconto_total'])}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                if ((item['item_devolvido'] as bool? ?? false))
                  const Text(
                    '⚠️ Devolvido',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            fmt.format(item['vr_total_liquido']),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}