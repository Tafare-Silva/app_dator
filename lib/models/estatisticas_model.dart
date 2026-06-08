class ItemCurvaABC {
  final int produtoId;
  final String? produtoNome;
  final double totalVendido;
  final double quantidadeVendida;
  final int quantidadePedidos;
  final double pctIndividual;
  final double pctAcumulado;
  final String curva; // A, B ou C

  ItemCurvaABC({
    required this.produtoId,
    this.produtoNome,
    required this.totalVendido,
    required this.quantidadeVendida,
    required this.quantidadePedidos,
    required this.pctIndividual,
    required this.pctAcumulado,
    required this.curva,
  });

  factory ItemCurvaABC.fromJson(Map<String, dynamic> json) => ItemCurvaABC(
        produtoId: json['produto_id'],
        produtoNome: json['produto_nome'],
        totalVendido: double.parse(json['total_vendido'].toString()),
        quantidadeVendida: double.parse(json['quantidade_vendida'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        pctIndividual: double.parse(json['pct_individual'].toString()),
        pctAcumulado: double.parse(json['pct_acumulado'].toString()),
        curva: json['curva'] ?? 'C',
      );
}

class ItemVendasGrupo {
  final String nome;
  final double totalVendido;
  final double quantidadeVendida;
  final int quantidadePedidos;
  final double pct;

  ItemVendasGrupo({
    required this.nome,
    required this.totalVendido,
    required this.quantidadeVendida,
    required this.quantidadePedidos,
    required this.pct,
  });

  factory ItemVendasGrupo.fromJsonMarca(Map<String, dynamic> json) =>
      ItemVendasGrupo(
        nome: json['marca_nome'] ?? '—',
        totalVendido: double.parse(json['total_vendido'].toString()),
        quantidadeVendida: double.parse(json['quantidade_vendida'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        pct: double.parse(json['pct'].toString()),
      );

  factory ItemVendasGrupo.fromJsonDivisao(Map<String, dynamic> json) =>
      ItemVendasGrupo(
        nome: json['divisao_nome'] ?? '—',
        totalVendido: double.parse(json['total_vendido'].toString()),
        quantidadeVendida: double.parse(json['quantidade_vendida'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        pct: double.parse(json['pct'].toString()),
      );

  factory ItemVendasGrupo.fromJsonColecao(Map<String, dynamic> json) =>
      ItemVendasGrupo(
        nome: json['colecao'] ?? '—',
        totalVendido: double.parse(json['total_vendido'].toString()),
        quantidadeVendida: double.parse(json['quantidade_vendida'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        pct: double.parse(json['pct'].toString()),
      );

  factory ItemVendasGrupo.fromJsonGenero(Map<String, dynamic> json) =>
      ItemVendasGrupo(
        nome: json['genero'] ?? '—',
        totalVendido: double.parse(json['total_vendido'].toString()),
        quantidadeVendida: double.parse(json['quantidade_vendida'].toString()),
        quantidadePedidos: json['quantidade_pedidos'],
        pct: double.parse(json['pct'].toString()),
      );
}

class FiltrosEstatistica {
  final List<String> marcas;
  final List<Map<String, dynamic>> divisoes;
  final List<String> colecoes;

  FiltrosEstatistica({
    required this.marcas,
    required this.divisoes,
    required this.colecoes,
  });

  factory FiltrosEstatistica.fromJson(Map<String, dynamic> json) =>
      FiltrosEstatistica(
        marcas: List<String>.from(json['marcas'] ?? []),
        divisoes: List<Map<String, dynamic>>.from(json['divisoes'] ?? []),
        colecoes: List<String>.from(json['colecoes'] ?? []),
      );
}