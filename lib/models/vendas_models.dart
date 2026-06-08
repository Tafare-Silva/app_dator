// ── Vendedor ──────────────────────
class Vendedor {
  final int pkChave;
  final String? nome;
  final String? funcao;
  final bool ativo;

  Vendedor({required this.pkChave, this.nome, this.funcao, required this.ativo});

  factory Vendedor.fromJson(Map<String, dynamic> json) => Vendedor(
        pkChave: json['pk_chave'],
        nome: json['nome'],
        funcao: json['funcao'],
        ativo: json['ativo'] ?? true,
      );
}

// ── Ranking Vendedor ──────────────────────────────────────────────────────────

class RankingVendedor {
  final int vendedorId;
  final String vendedorNome;
  final double totalVendas;
  final int quantidadePedidos;
  final double ticketMedio;

  RankingVendedor({
    required this.vendedorId,
    required this.vendedorNome,
    required this.totalVendas,
    required this.quantidadePedidos,
    required this.ticketMedio,
  });

  factory RankingVendedor.fromJson(Map<String, dynamic> json) => RankingVendedor(
        vendedorId: json['vendedor_id'],
        vendedorNome: json['vendedor_nome'] ?? '—',
        totalVendas: double.parse(json['total_vendas'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        ticketMedio: double.parse(json['ticket_medio'].toString()),
      );
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class DashboardVendas {
  final double totalVendas;
  final int quantidadePedidos;
  final double ticketMedio;
  final double totalVendasHoje;
  final int quantidadePedidosHoje;
  final List<RankingVendedor> rankingVendedores;
  final DateTime dataInicio;
  final DateTime dataFim;

  DashboardVendas({
    required this.totalVendas,
    required this.quantidadePedidos,
    required this.ticketMedio,
    required this.totalVendasHoje,
    required this.quantidadePedidosHoje,
    required this.rankingVendedores,
    required this.dataInicio,
    required this.dataFim,
  });

  factory DashboardVendas.fromJson(Map<String, dynamic> json) => DashboardVendas(
        totalVendas: double.parse(json['total_vendas'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        ticketMedio: double.parse(json['ticket_medio'].toString()),
        totalVendasHoje: double.parse(json['total_vendas_hoje'].toString()),
        quantidadePedidosHoje: json['quantidade_pedidos_hoje'],
        rankingVendedores: (json['ranking_vendedores'] as List)
            .map((r) => RankingVendedor.fromJson(r))
            .toList(),
        dataInicio: DateTime.parse(json['data_inicio']),
        dataFim: DateTime.parse(json['data_fim']),
      );
}

// ── Pedido de Venda ───────────────────────────────────────────────────────────

class ItemVenda {
  final int pkChave;
  final int produtoId;
  final String? produtoNome;
  final double quantidade;
  final double vrUnitarioBruto;
  final double vrDescontoTotal;
  final double vrAcrescimoTotal;
  final double vrTotalLiquido;
  final bool itemDevolvido;
  final double quantidadeDevolvida;
  final int? vendedorId;
  final String? vendedorNome;

  ItemVenda({
    required this.pkChave,
    required this.produtoId,
    this.produtoNome,
    required this.quantidade,
    required this.vrUnitarioBruto,
    required this.vrDescontoTotal,
    required this.vrAcrescimoTotal,
    required this.vrTotalLiquido,
    required this.itemDevolvido,
    required this.quantidadeDevolvida,
    this.vendedorId,
    this.vendedorNome,
  });

  factory ItemVenda.fromJson(Map<String, dynamic> json) => ItemVenda(
        pkChave: json['pk_chave'],
        produtoId: json['produto_id'],
        produtoNome: json['produto_nome'],
        quantidade: double.parse(json['quantidade'].toString()),
        vrUnitarioBruto: double.parse(json['vr_unitario_bruto'].toString()),
        vrDescontoTotal: double.parse(json['vr_desconto_total'].toString()),
        vrAcrescimoTotal: double.parse(json['vr_acrescimo_total'].toString()),
        vrTotalLiquido: double.parse(json['vr_total_liquido'].toString()),
        itemDevolvido: json['item_devolvido'] ?? false,
        quantidadeDevolvida: double.parse(json['quantidade_devolvida'].toString()),
        vendedorId: json['vendedor_id'],
        vendedorNome: json['vendedor_nome'],
      );
}

class PedidoVenda {
  final int pkChave;
  final DateTime data;
  final int? clienteId;
  final String? clienteNome;
  final int vendedorId;
  final String? vendedorNome;
  final double vrTotal;
  final double vrFrete;
  final int quantidadeItens;
  final List<ItemVenda>? itens;

  PedidoVenda({
    required this.pkChave,
    required this.data,
    this.clienteId,
    this.clienteNome,
    required this.vendedorId,
    this.vendedorNome,
    required this.vrTotal,
    required this.vrFrete,
    required this.quantidadeItens,
    this.itens,
  });

  factory PedidoVenda.fromJson(Map<String, dynamic> json) => PedidoVenda(
        pkChave: json['pk_chave'],
        data: DateTime.parse(json['data']),
        clienteId: json['cliente_id'],
        clienteNome: json['cliente_nome'],
        vendedorId: json['vendedor_id'],
        vendedorNome: json['vendedor_nome'],
        vrTotal: double.parse(json['vr_total'].toString()),
        vrFrete: double.parse(json['vr_frete'].toString()),
        quantidadeItens: json['quantidade_itens'],
        itens: json['itens'] != null
            ? (json['itens'] as List).map((i) => ItemVenda.fromJson(i)).toList()
            : null,
      );
}

// ── Pré-Venda ─────────────────────────────────────────────────────────────────

class PreVenda {
  final int pkChave;
  final DateTime data;
  final int? clienteId;
  final String? clienteNome;
  final int? vendedorId;
  final String? vendedorNome;
  final bool efetivada;
  final String? condicaoPagamento;
  final DateTime? dataEntrega;
  final double vrTotal;
  final int quantidadeItens;

  PreVenda({
    required this.pkChave,
    required this.data,
    this.clienteId,
    this.clienteNome,
    this.vendedorId,
    this.vendedorNome,
    required this.efetivada,
    this.condicaoPagamento,
    this.dataEntrega,
    required this.vrTotal,
    required this.quantidadeItens,
  });

  factory PreVenda.fromJson(Map<String, dynamic> json) => PreVenda(
        pkChave: json['pk_chave'],
        data: DateTime.parse(json['data']),
        clienteId: json['cliente_id'],
        clienteNome: json['cliente_nome'],
        vendedorId: json['vendedor_id'],
        vendedorNome: json['vendedor_nome'],
        efetivada: json['efetivada'] ?? false,
        condicaoPagamento: json['condicao_pagamento'],
        dataEntrega: json['data_entrega'] != null
            ? DateTime.parse(json['data_entrega'])
            : null,
        vrTotal: double.parse(json['vr_total'].toString()),
        quantidadeItens: json['quantidade_itens'],
      );
}

// ── Input para criação de Pré-Venda ──────────────────────────────────────────

class ItemPreVendaInput {
  final int produtoId;
  final double quantidade;
  final double vrUnitarioBruto;
  final double vrDescontoTotal;
  final double vrAcrescimoTotal;
  final int? vendedorId;

  const ItemPreVendaInput({
    required this.produtoId,
    required this.quantidade,
    required this.vrUnitarioBruto,
    this.vrDescontoTotal = 0,
    this.vrAcrescimoTotal = 0,
    this.vendedorId,
  });

  Map<String, dynamic> toJson() => {
        'produto_id': produtoId,
        'quantidade': quantidade,
        'vr_unitario_bruto': vrUnitarioBruto,
        'vr_desconto_total': vrDescontoTotal,
        'vr_acrescimo_total': vrAcrescimoTotal,
        if (vendedorId != null) 'vendedor_id': vendedorId,
      };

  double get vrTotalLiquido =>
      quantidade * vrUnitarioBruto - vrDescontoTotal + vrAcrescimoTotal;
}

class PreVendaInput {
  final int? clienteId;
  final int? vendedorId;
  final DateTime? data;
  final String? condicaoPagamento;
  final DateTime? dataEntrega;
  final String? obs;
  final List<ItemPreVendaInput> itens;

  const PreVendaInput({
    this.clienteId,
    this.vendedorId,
    this.data,
    this.condicaoPagamento,
    this.dataEntrega,
    this.obs,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        if (clienteId != null) 'cliente_id': clienteId,
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (data != null) 'data': '${data!.year.toString().padLeft(4, '0')}-${data!.month.toString().padLeft(2, '0')}-${data!.day.toString().padLeft(2, '0')}',
        if (condicaoPagamento != null) 'condicao_pagamento': condicaoPagamento,
        if (dataEntrega != null) 'data_entrega': '${dataEntrega!.year.toString().padLeft(4, '0')}-${dataEntrega!.month.toString().padLeft(2, '0')}-${dataEntrega!.day.toString().padLeft(2, '0')}',
        if (obs != null) 'obs': obs,
        'itens': itens.map((i) => i.toJson()).toList(),
      };
}

// ── PreVendaDetalhe (Detalhe completo com itens) ───────────────────────────────
/// Representa os detalhes COMPLETOS de uma pré-venda, incluindo seus itens
class PreVendaDetalhe {
  final int pkChave;
  final DateTime data;
  final int? clienteId;
  final String? clienteNome;
  final int? vendedorId;
  final String? vendedorNome;
  final bool efetivada;
  final String? condicaoPagamento;
  final DateTime? dataEntrega;
  final double vrTotal;
  final int quantidadeItens;
  final List<ItemVenda> itens;

  PreVendaDetalhe({
    required this.pkChave,
    required this.data,
    this.clienteId,
    this.clienteNome,
    this.vendedorId,
    this.vendedorNome,
    required this.efetivada,
    this.condicaoPagamento,
    this.dataEntrega,
    required this.vrTotal,
    required this.quantidadeItens,
    required this.itens,
  });

  factory PreVendaDetalhe.fromJson(Map<String, dynamic> json) {
    var itensList = json['itens'] as List? ?? [];
    List<ItemVenda> itens = 
        itensList.map((i) => ItemVenda.fromJson(i)).toList();

    return PreVendaDetalhe(
      pkChave: json['pk_chave'] ?? 0,
      data: json['data'] != null 
          ? DateTime.parse(json['data'].toString())
          : DateTime.now(),
      clienteId: json['cliente_id'],
      clienteNome: json['cliente_nome'],
      vendedorId: json['vendedor_id'],
      vendedorNome: json['vendedor_nome'],
      efetivada: json['efetivada'] ?? false,
      condicaoPagamento: json['condicao_pagamento'],
      dataEntrega: json['data_entrega'] != null
          ? DateTime.parse(json['data_entrega'].toString())
          : null,
      vrTotal: double.parse(json['vr_total'].toString()),
      quantidadeItens: json['quantidade_itens'] ?? 0,
      itens: itens,
    );
  }
}