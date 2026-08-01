class ContaPagar {
  final int pkChave;
  final DateTime dataVencimento;
  final DateTime dataOperacao;
  final double valorOriginal;
  final double valorPago;
  final String? documento;
  final String parcela;
  final String? observacoes;
  final String? tipoPagamento;
  final bool pago;
  final DateTime? dataBaixa;
  final double juros;
  final double multa;
  final double adicional;
  final double desconto;
  final bool vencido;
  final int pessoaId;
  final String? pessoaNome;
  final String? pessoaCelular;
  final int planoContasId;
  final String? planoContasNome;
  final int centroCustosId;
  final String? centroCustosNome;

  bool get isPendente => !pago;
  bool get temAjustes => juros != 0 || multa != 0 || adicional != 0 || desconto != 0;

  const ContaPagar({
    required this.pkChave,
    required this.dataVencimento,
    required this.dataOperacao,
    required this.valorOriginal,
    required this.valorPago,
    this.documento,
    required this.parcela,
    this.observacoes,
    this.tipoPagamento,
    required this.pago,
    this.dataBaixa,
    required this.juros,
    required this.multa,
    required this.adicional,
    required this.desconto,
    required this.vencido,
    required this.pessoaId,
    this.pessoaNome,
    this.pessoaCelular,
    required this.planoContasId,
    this.planoContasNome,
    required this.centroCustosId,
    this.centroCustosNome,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> j) => ContaPagar(
        pkChave: j['pk_chave'] as int,
        dataVencimento: DateTime.parse(j['data_vencimento']),
        dataOperacao: DateTime.parse(j['data_operacao']),
        valorOriginal: double.parse(j['valor_original'].toString()),
        valorPago: double.parse(j['valor_pago'].toString()),
        documento: j['documento'] as String?,
        parcela: (j['parcela'] as String?) ?? '1',
        observacoes: j['observacoes'] as String?,
        tipoPagamento: j['tipo_pagamento'] as String?,
        pago: j['pago'] as bool? ?? false,
        dataBaixa: j['data_baixa'] != null ? DateTime.parse(j['data_baixa']) : null,
        juros: double.parse((j['juros'] ?? '0').toString()),
        multa: double.parse((j['multa'] ?? '0').toString()),
        adicional: double.parse((j['adicional'] ?? '0').toString()),
        desconto: double.parse((j['desconto'] ?? '0').toString()),
        vencido: j['vencido'] as bool? ?? false,
        pessoaId: j['pessoa_id'] as int,
        pessoaNome: j['pessoa_nome'] as String?,
        pessoaCelular: j['pessoa_celular'] as String?,
        planoContasId: j['plano_contas_id'] as int,
        planoContasNome: j['plano_contas_nome'] as String?,
        centroCustosId: j['centro_custos_id'] as int,
        centroCustosNome: j['centro_custos_nome'] as String?,
      );
}

class ResumoContasPagar {
  final int titulosPendentes;
  final int titulosPagos;
  // Totais pendentes
  final double totalVencido;
  final double totalAVencer;
  final double total;
  // Totais pagas
  final double totalPago;
  final double totalJurosMulta;
  final double totalDesconto;

  const ResumoContasPagar({
    required this.titulosPendentes,
    required this.titulosPagos,
    required this.totalVencido,
    required this.totalAVencer,
    required this.total,
    required this.totalPago,
    required this.totalJurosMulta,
    required this.totalDesconto,
  });

  factory ResumoContasPagar.fromJson(Map<String, dynamic> j) => ResumoContasPagar(
        titulosPendentes: j['titulos_pendentes'] as int,
        titulosPagos: j['titulos_pagos'] as int,
        totalVencido: double.parse(j['total_vencido'].toString()),
        totalAVencer: double.parse(j['total_a_vencer'].toString()),
        total: double.parse(j['total'].toString()),
        totalPago: double.parse(j['total_pago'].toString()),
        totalJurosMulta: double.parse(j['total_juros_multa'].toString()),
        totalDesconto: double.parse(j['total_desconto'].toString()),
      );
}

class FiltroItem {
  final int pkChave;
  final String nome;
  const FiltroItem({required this.pkChave, required this.nome});
  factory FiltroItem.fromJson(Map<String, dynamic> j) =>
      FiltroItem(pkChave: j['pk_chave'] as int, nome: (j['nome'] as String?) ?? '—');
}

// ── Grupo agregado (despesas/receitas por plano de contas ou centro de custo) ──

class GrupoFinanceiro {
  final int id;
  final String nome;
  final String? codigo;
  final int quantidadeTitulos;
  final double total;

  const GrupoFinanceiro({
    required this.id,
    required this.nome,
    this.codigo,
    required this.quantidadeTitulos,
    required this.total,
  });

  factory GrupoFinanceiro.fromJson(Map<String, dynamic> j) => GrupoFinanceiro(
        id: j['id'] as int,
        nome: (j['nome'] as String?) ?? '—',
        codigo: j['codigo'] as String?,
        quantidadeTitulos: j['quantidade_titulos'] as int? ?? 0,
        total: double.parse((j['total'] ?? '0').toString()),
      );
}

// ── Apuração de Resultados (DRE simplificado) ──────────────────────────────────

class ApuracaoResultado {
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double totalDespesas;
  final int quantidadeDespesas;
  final double totalReceitas;
  final int quantidadeReceitas;
  final double saldo;

  const ApuracaoResultado({
    this.dataInicio,
    this.dataFim,
    required this.totalDespesas,
    required this.quantidadeDespesas,
    required this.totalReceitas,
    required this.quantidadeReceitas,
    required this.saldo,
  });

  factory ApuracaoResultado.fromJson(Map<String, dynamic> j) => ApuracaoResultado(
        dataInicio: j['data_inicio'] != null ? DateTime.parse(j['data_inicio']) : null,
        dataFim: j['data_fim'] != null ? DateTime.parse(j['data_fim']) : null,
        totalDespesas: double.parse((j['total_despesas'] ?? '0').toString()),
        quantidadeDespesas: j['quantidade_despesas'] as int? ?? 0,
        totalReceitas: double.parse((j['total_receitas'] ?? '0').toString()),
        quantidadeReceitas: j['quantidade_receitas'] as int? ?? 0,
        saldo: double.parse((j['saldo'] ?? '0').toString()),
      );
}

// ── Total Vendido x Total Recebido ─────────────────────────────────────────────

class VendidoRecebido {
  final DateTime dataInicio;
  final DateTime dataFim;
  final double totalVendido;
  final double totalRecebido;
  final double diferenca;
  final int quantidadeVendas;
  final int quantidadeRecebimentos;

  const VendidoRecebido({
    required this.dataInicio,
    required this.dataFim,
    required this.totalVendido,
    required this.totalRecebido,
    required this.diferenca,
    required this.quantidadeVendas,
    required this.quantidadeRecebimentos,
  });

  factory VendidoRecebido.fromJson(Map<String, dynamic> j) => VendidoRecebido(
        dataInicio: DateTime.parse(j['data_inicio']),
        dataFim: DateTime.parse(j['data_fim']),
        totalVendido: double.parse((j['total_vendido'] ?? '0').toString()),
        totalRecebido: double.parse((j['total_recebido'] ?? '0').toString()),
        diferenca: double.parse((j['diferenca'] ?? '0').toString()),
        quantidadeVendas: j['quantidade_vendas'] as int? ?? 0,
        quantidadeRecebimentos: j['quantidade_recebimentos'] as int? ?? 0,
      );
}
