import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../core/app_theme.dart';

class ContaScreen extends StatefulWidget {
  final String nomeMesa;
  const ContaScreen({super.key, required this.nomeMesa});

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  final _service = ItemMesaService();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtHora = DateFormat('dd/MM/yyyy HH:mm');

  late Future<ResumoConta> _futuroConta;

  @override
  void initState() {
    super.initState();
    _futuroConta = _service.getConta(widget.nomeMesa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Conta — ${widget.nomeMesa}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir',
            onPressed: () {
              // TODO: integrar impressão térmica via flutter_thermal_printer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Impressão em breve!'),
                    backgroundColor: AppTheme.primary),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ResumoConta>(
        future: _futuroConta,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(
                child: Text('Erro ao carregar conta.',
                    style: TextStyle(color: AppTheme.textMuted)));
          }

          final conta = snap.data!;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cabeçalho
                    _Cabecalho(nomeMesa: widget.nomeMesa, fmt: _fmtHora),
                    const SizedBox(height: 16),

                    // Itens
                    ...conta.itens.map((item) => _LinhaItem(item: item, fmt: _fmt)),

                    const Divider(height: 32, thickness: 1),

                    // Totais
                    _LinhaTotal(
                        label: 'Subtotal',
                        valor: _fmt.format(conta.totalBruto),
                        destaque: false),
                    const SizedBox(height: 8),
                    _LinhaTotal(
                        label: 'TOTAL',
                        valor: _fmt.format(conta.totalBruto),
                        destaque: true),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Rodapé com botão fechar conta
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: implementar fechamento de conta / geração de pedido de venda
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Fechar conta'),
                        content: Text(
                            'Confirmar fechamento de ${widget.nomeMesa}?\nTotal: ${_fmt.format(conta.totalBruto)}'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: chamar endpoint de fechamento
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Fechar conta • ${_fmt.format(conta.totalBruto)}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final String nomeMesa;
  final DateFormat fmt;

  const _Cabecalho({required this.nomeMesa, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_restaurant, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nomeMesa,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
              Text(fmt.format(DateTime.now()),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinhaItem extends StatelessWidget {
  final ItemMesa item;
  final NumberFormat fmt;

  const _LinhaItem({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final qtdStr = item.quantidade == item.quantidade.truncate()
        ? item.quantidade.toStringAsFixed(0)
        : item.quantidade.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text('$qtdStr x',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produto?.nome ?? 'Produto #${item.fkProdutosProduto}',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textDark)),
                if (item.observacoesItem != null &&
                    item.observacoesItem!.isNotEmpty)
                  Text('${item.observacoesItem}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Text(fmt.format(item.vrTotal),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}

class _LinhaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;

  const _LinhaTotal(
      {required this.label, required this.valor, required this.destaque});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: destaque ? 18 : 14,
                fontWeight:
                    destaque ? FontWeight.bold : FontWeight.normal,
                color: destaque ? AppTheme.textDark : AppTheme.textMuted)),
        Text(valor,
            style: TextStyle(
                fontSize: destaque ? 20 : 14,
                fontWeight: FontWeight.bold,
                color: destaque ? AppTheme.primary : AppTheme.textDark)),
      ],
    );
  }
}