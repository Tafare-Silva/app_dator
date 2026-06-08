class ProdutoResumo {
  final int pkChave;
  final String? nome;
  final String? referenciaFabrica;
  final double precoVenda;
  final double estoque;
  final bool inativo;
  final String? categoria;
  final String? cor;
  final String? tamanho;
  final String? colecao;
  final String? marca;
  final String? divisao;
  final String? genero;

  ProdutoResumo({
    required this.pkChave,
    this.nome,
    this.referenciaFabrica,
    required this.precoVenda,
    required this.estoque,
    required this.inativo,
    this.categoria,
    this.cor,
    this.tamanho,
    this.colecao,
    this.marca,
    this.divisao,
    this.genero,
  });

  factory ProdutoResumo.fromJson(Map<String, dynamic> json) => ProdutoResumo(
        pkChave: json['pk_chave'],
        nome: json['nome'],
        referenciaFabrica: json['referencia_fabrica'],
        precoVenda: double.parse(json['preco_venda'].toString()),
        estoque: double.parse((json['estoque'] ?? '0').toString()),
        inativo: json['inativo'] ?? false,
        categoria: json['categoria'],
        cor: json['cor'],
        tamanho: json['tamanho'],
        colecao: json['colecao'],
        marca: json['marca'],
        divisao: json['divisao'],
        genero: json['genero'],
      );
}