import 'package:intl/intl.dart';
import '../models/vendas_models.dart';

// Importe o ApiClient do seu projeto existente:
// import '../services/api_client.dart';
// Por ora use o import relativo correto para seu projeto.

// ignore: uri_does_not_exist
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

  Future<List<PedidoVenda>> listarPedidos({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
    int limit = 50,
    int offset = 0,
  }) async {
    final hoje = DateTime.now();
    final inicio = dataInicio ?? DateTime(hoje.year, hoje.month, 1);
    final fim = dataFim ?? hoje;

    final response = await _client.dio.get(
      '/vendas/pedidos',
      queryParameters: {
        'data_inicio': _dateFormat.format(inicio),
        'data_fim': _dateFormat.format(fim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List).map((p) => PedidoVenda.fromJson(p)).toList();
  }

  Future<PedidoVenda> getPedidoDetalhe(int pedidoId) async {
    final response = await _client.dio.get('/vendas/pedidos/$pedidoId');
    return PedidoVenda.fromJson(response.data);
  }

  Future<PreVendaDetalhe> getPreVendaDetalhe(int preVendaId) async {
  final response = await _client.dio.get('/vendas/pre-vendas/$preVendaId');
  return PreVendaDetalhe.fromJson(response.data);  
}

  // ── Pré-Vendas ──────────────────────────────────────────────────────────────

  Future<List<PreVenda>> listarPreVendas({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    int? clienteId,
    bool? efetivada,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.dio.get(
      '/vendas/pre-vendas',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (clienteId != null) 'cliente_id': clienteId,
        if (efetivada != null) 'efetivada': efetivada,
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List).map((p) => PreVenda.fromJson(p)).toList();
  }
}