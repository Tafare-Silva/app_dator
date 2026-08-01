import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/financeiro_model.dart';

const paletaGruposFinanceiros = [
  AppTheme.primary,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.brown,
  Colors.cyan,
];

/// Donut chart + legenda (top 5) para a distribuição de um conjunto de grupos
/// (plano de contas ou centro de custo) sobre o total.
class GrupoPieChart extends StatelessWidget {
  final List<GrupoFinanceiro> grupos;
  final double totalGeral;

  const GrupoPieChart({super.key, required this.grupos, required this.totalGeral});

  @override
  Widget build(BuildContext context) {
    if (totalGeral <= 0 || grupos.isEmpty) return const SizedBox.shrink();
    final top = [...grupos]..sort((a, b) => b.total.compareTo(a.total));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    for (final g in top)
                      PieChartSectionData(
                        value: g.total,
                        color: paletaGruposFinanceiros[grupos.indexOf(g) % paletaGruposFinanceiros.length],
                        title: '',
                        radius: 24,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < top.length && i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: paletaGruposFinanceiros[grupos.indexOf(top[i]) % paletaGruposFinanceiros.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(top[i].nome,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${(top[i].total / totalGeral * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card do nível 1 do drill-down: total geral, expansível.
class GrandTotalCard extends StatelessWidget {
  final String titulo;
  final double total;
  final int quantidadeGrupos;
  final NumberFormat fmt;
  final Color cor;
  final IconData icone;
  final bool expandido;
  final VoidCallback onToggle;

  const GrandTotalCard({
    super.key,
    required this.titulo,
    required this.total,
    required this.quantidadeGrupos,
    required this.fmt,
    required this.cor,
    required this.onToggle,
    this.icone = Icons.account_balance_wallet_outlined,
    this.expandido = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cor.withValues(alpha: 0.07),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: cor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(fmt.format(total),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor)),
                    ),
                    const SizedBox(height: 2),
                    Text('$quantidadeGrupos categorias',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expandido ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_circle_down_outlined, color: cor, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card do nível 2 do drill-down: um grupo (plano de contas ou centro de custo),
/// que ao ser expandido carrega e mostra os títulos individuais (nível 3).
class GrupoExpansivelCard extends StatefulWidget {
  final GrupoFinanceiro grupo;
  final double totalGeral;
  final Color cor;
  final NumberFormat fmt;
  final Future<List<ContaPagar>> Function() carregarTitulos;

  const GrupoExpansivelCard({
    super.key,
    required this.grupo,
    required this.totalGeral,
    required this.cor,
    required this.fmt,
    required this.carregarTitulos,
  });

  @override
  State<GrupoExpansivelCard> createState() => _GrupoExpansivelCardState();
}

class _GrupoExpansivelCardState extends State<GrupoExpansivelCard> {
  bool _expandido = false;
  Future<List<ContaPagar>>? _futuro;

  void _toggle() {
    setState(() {
      _expandido = !_expandido;
      _futuro ??= widget.carregarTitulos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.totalGeral > 0 ? (widget.grupo.total / widget.totalGeral) : 0.0;
    final fmtData = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.grupo.codigo != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.cor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(widget.grupo.codigo!,
                              style: TextStyle(fontSize: 10, color: widget.cor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(widget.grupo.nome,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(widget.fmt.format(widget.grupo.total),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.cor)),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.add_circle_outline, size: 20, color: widget.cor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: widget.cor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.grupo.quantidadeTitulos} títulos',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('${(pct * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.cor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expandido ? _buildDetalhe(fmtData) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhe(DateFormat fmtData) {
    return FutureBuilder<List<ContaPagar>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Erro ao carregar títulos.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          );
        }
        final titulos = snap.data ?? [];
        if (titulos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nenhum título encontrado.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          );
        }
        return Container(
          color: const Color(0xFFFAFAFA),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (int i = 0; i < titulos.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
                TituloRow(conta: titulos[i], fmt: widget.fmt, fmtData: fmtData),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Linha compacta representando um único título (pagamento/recebimento) — nível 3.
class TituloRow extends StatelessWidget {
  final ContaPagar conta;
  final NumberFormat fmt;
  final DateFormat fmtData;

  const TituloRow({super.key, required this.conta, required this.fmt, required this.fmtData});

  @override
  Widget build(BuildContext context) {
    final cor = conta.pago ? Colors.green : (conta.vencido ? Colors.red : AppTheme.primary);
    final dataRef = conta.pago ? (conta.dataBaixa ?? conta.dataVencimento) : conta.dataVencimento;
    final rotulo = conta.pago ? 'Pago em' : (conta.vencido ? 'Venceu em' : 'Vence em');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(width: 4, height: 34, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conta.pessoaNome ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('$rotulo ${fmtData.format(dataRef)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(fmt.format(conta.pago ? conta.valorPago : conta.valorOriginal),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }
}
