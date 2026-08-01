import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/vendas_models.dart';
import 'api_client.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class VendasService {
  final _client = ApiClient();

  // ── Vendedores ──────────────────────────────────────────────────────────────

  Future<List<Vendedor>> listarVendedores({bool apenasAtivos = true}) async {
    final response = await _client.dio.get(
      '/vendas/vendedores',
      queryParameters: {'apenas_ativos': apenasAtivos},
    );
    return (response.data as List).map((v) => Vendedor.fromJson(v)).toList();
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────

  Future<DashboardVendas> getDashboard({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final hoje = DateTime.now();
    final inicio = dataInicio ?? DateTime(hoje.year, hoje.month, 1);
    final fim = dataFim ?? hoje;

    final response = await _client.dio.get(
      '/vendas/dashboard',
      queryParameters: {
        'data_inicio': _dateFormat.format(inicio),
        'data_fim': _dateFormat.format(fim),
      },
    );
    return DashboardVendas.fromJson(response.data);
  }

  // ── Pedidos ─────────────────────────────────────────────────────────────────

  /// [OTIMIZAÇÃO 1]
  /// Carrega APENAS pedidos de HOJE por padrão (rápido ⚡).
  /// Se o usuário filtrar por data/vendedor, traz TODOS os resultados desse filtro.
  Future<List<PedidoVenda>> listarPedidos({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
  }) async {
    final hoje = DateTime.now();
    // Se nenhuma data for fornecida, filtra apenas os pedidos de hoje
    final inicio = dataInicio ?? DateTime(hoje.year, hoje.month, hoje.day);
    final fim = dataFim ?? DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    final response = await _client.dio.get(
      '/vendas/pedidos',
      queryParameters: {
        'data_inicio': _dateFormat.format(inicio),
        'data_fim': _dateFormat.format(fim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        // Sem limit/offset aqui - traz TODOS os resultados do período
      },
    );
    return (response.data as List).map((p) => PedidoVenda.fromJson(p)).toList();
  }

  /// [NOVO MÉTODO - Paginação]
  /// Carrega pedidos com infinite scrolling para filtros com muitos resultados.
  Future<List<PedidoVenda>> listarPedidosProximos({
    required int page,
    required int pageSize,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
  }) async {
    final offset = page * pageSize;
    final response = await _client.dio.get(
      '/vendas/pedidos',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        'limit': pageSize,
        'offset': offset,
      },
    );
    return (response.data as List).map((p) => PedidoVenda.fromJson(p)).toList();
  }

  Future<PedidoVenda> getPedidoDetalhe(int pedidoId) async {
    final response = await _client.dio.get('/vendas/pedidos/$pedidoId');
    return PedidoVenda.fromJson(response.data);
  }

  // ── Pré-Vendas ──────────────────────────────────────────────────────────────

  /// [OTIMIZAÇÃO 2]
  /// Carrega APENAS pré-vendas de HOJE por padrão (rápido ⚡).
  /// Se o usuário filtrar por data/vendedor, traz TODOS os resultados desse filtro.
  Future<List<PreVenda>> listarPreVendas({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
    bool? efetivada,
  }) async {
    final hoje = DateTime.now();
    // Se nenhuma data for fornecida, filtra apenas as pré-vendas de hoje
    final inicio = dataInicio ?? DateTime(hoje.year, hoje.month, hoje.day);
    final fim = dataFim ?? DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    final response = await _client.dio.get(
      '/vendas/pre-vendas',
      queryParameters: {
        'data_inicio': _dateFormat.format(inicio),
        'data_fim': _dateFormat.format(fim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        if (efetivada != null) 'efetivada': efetivada,
        // Sem limit/offset aqui - traz TODOS os resultados do período
      },
    );
    return (response.data as List).map((p) => PreVenda.fromJson(p)).toList();
  }

  /// [NOVO MÉTODO - Paginação]
  /// Carrega pré-vendas com infinite scrolling para filtros com muitos resultados.
  Future<List<PreVenda>> listarPreVendasProximas({
    required int page,
    required int pageSize,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
    bool? efetivada,
  }) async {
    final offset = page * pageSize;
    final response = await _client.dio.get(
      '/vendas/pre-vendas',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        if (efetivada != null) 'efetivada': efetivada,
        'limit': pageSize,
        'offset': offset,
      },
    );
    return (response.data as List).map((p) => PreVenda.fromJson(p)).toList();
  }

  Future<PreVendaDetalhe> getPreVendaDetalhe(int preVendaId) async {
    final response = await _client.dio.get('/vendas/pre-vendas/$preVendaId');
    return PreVendaDetalhe.fromJson(response.data);
  }

  Future<PreVenda> criarPreVenda(PreVendaInput dados) async {
    final response = await _client.dio.post(
      '/vendas/pre-vendas',
      data: dados.toJson(),
    );
    if (response.statusCode != 201) {
      final msg = response.data is Map ? (response.data['detail'] ?? 'Erro ao criar pré-venda') : 'Erro ao criar pré-venda';
      throw Exception(msg.toString());
    }
    return PreVenda.fromJson(response.data);
  }

  /// Devolve um item do condicional — remove o item da pré-venda de verdade
  /// (o ERP, ao efetivar, considera tudo que ainda existe na pré-venda, não
  /// um campo de "devolvido"; por isso o item precisa sair de fato).
  Future<void> devolverItemPreVenda(int preVendaId, int itemId) async {
    try {
      await _client.dio.delete('/vendas/pre-vendas/$preVendaId/itens/$itemId');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? 'Erro ao registrar devolução')
          : 'Erro ao registrar devolução';
      throw Exception(msg.toString());
    }
  }

  /// Desfaz uma devolução, recriando o item na pré-venda (gera um novo
  /// pk_chave — o item devolvido foi de fato apagado).
  Future<ItemVenda> restaurarItemPreVenda(int preVendaId, ItemVenda item) async {
    try {
      final response = await _client.dio.post(
        '/vendas/pre-vendas/$preVendaId/itens/restaurar',
        data: {
          'produto_id': item.produtoId,
          'quantidade': item.quantidade,
          'vr_unitario_bruto': item.vrUnitarioBruto,
          'vr_desconto_total': item.vrDescontoTotal,
          'vr_acrescimo_total': item.vrAcrescimoTotal,
          if (item.vendedorId != null) 'vendedor_id': item.vendedorId,
        },
      );
      return ItemVenda(
        pkChave: response.data['pk_chave'],
        produtoId: item.produtoId,
        produtoNome: item.produtoNome,
        quantidade: item.quantidade,
        vrUnitarioBruto: item.vrUnitarioBruto,
        vrDescontoTotal: item.vrDescontoTotal,
        vrAcrescimoTotal: item.vrAcrescimoTotal,
        vrTotalLiquido: item.vrTotalLiquido,
        itemDevolvido: false,
        quantidadeDevolvida: 0,
        vendedorId: item.vendedorId,
        vendedorNome: item.vendedorNome,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? 'Erro ao desfazer devolução')
          : 'Erro ao desfazer devolução';
      throw Exception(msg.toString());
    }
  }
}