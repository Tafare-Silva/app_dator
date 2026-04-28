// ── Auth ─────────────────────────────────────────────────────────────────────

class TokenResponse {
  final String accessToken;
  final String nomeUsuario;
  final String? grupo;

  TokenResponse({
    required this.accessToken,
    required this.nomeUsuario,
    this.grupo,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'],
        nomeUsuario: json['nome_usuario'],
        grupo: json['grupo'],
      );
}

// ── Mesa ─────────────────────────────────────────────────────────────────────

class Mesa {
  final String nome;
  final String? observacoes;

  Mesa({required this.nome, this.observacoes});

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        nome: json['nome'],
        observacoes: json['observacoes'],
      );
}

// ── Produto ───────────────────────────────────────────────────────────────────

class Produto {
  final int pkChave;
  final String? nome;
  final double precoVenda;
  final bool inativo;

  Produto({
    required this.pkChave,
    this.nome,
    required this.precoVenda,
    required this.inativo,
  });

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        pkChave: json['pk_chave'],
        nome: json['nome'],
        precoVenda: double.parse(json['preco_venda'].toString()),
        inativo: json['inativo'],
      );
}

// ── Item Mesa ─────────────────────────────────────────────────────────────────

class ProdutoEmItem {
  final int pkChave;
  final String? nome;

  ProdutoEmItem({required this.pkChave, this.nome});

  factory ProdutoEmItem.fromJson(Map<String, dynamic> json) => ProdutoEmItem(
        pkChave: json['pk_chave'],
        nome: json['nome'],
      );
}

class ItemMesa {
  final int pkChave;
  final String? fkMesasMesa;
  final int fkProdutosProduto;
  final double quantidade;
  final double vrUnitarioBruto;
  final double vrTotal;
  final DateTime dataHoraInclusao;
  final String? observacoesItem;
  final bool desdobramento;
  final ProdutoEmItem? produto;

  ItemMesa({
    required this.pkChave,
    this.fkMesasMesa,
    required this.fkProdutosProduto,
    required this.quantidade,
    required this.vrUnitarioBruto,
    required this.vrTotal,
    required this.dataHoraInclusao,
    this.observacoesItem,
    required this.desdobramento,
    this.produto,
  });

  factory ItemMesa.fromJson(Map<String, dynamic> json) => ItemMesa(
        pkChave: json['pk_chave'],
        fkMesasMesa: json['fk_mesas_mesa'],
        fkProdutosProduto: json['fk_produtos_produto'],
        quantidade: double.parse(json['quantidade'].toString()),
        vrUnitarioBruto: double.parse(json['vr_unitario_bruto'].toString()),
        vrTotal: double.parse(json['vr_total'].toString()),
        dataHoraInclusao: DateTime.parse(json['data_hora_inclusao']),
        observacoesItem: json['observacoes_item'],
        desdobramento: json['desdobramento'],
        produto: json['produto'] != null
            ? ProdutoEmItem.fromJson(json['produto'])
            : null,
      );
}

// ── Resumo Conta ──────────────────────────────────────────────────────────────

class ResumoConta {
  final String mesa;
  final List<ItemMesa> itens;
  final double totalBruto;
  final int quantidadeItens;

  ResumoConta({
    required this.mesa,
    required this.itens,
    required this.totalBruto,
    required this.quantidadeItens,
  });

  factory ResumoConta.fromJson(Map<String, dynamic> json) => ResumoConta(
        mesa: json['mesa'],
        itens: (json['itens'] as List).map((i) => ItemMesa.fromJson(i)).toList(),
        totalBruto: double.parse(json['total_bruto'].toString()),
        quantidadeItens: json['quantidade_itens'],
      );
}
