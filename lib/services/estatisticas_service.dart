import 'package:intl/intl.dart';
import '../models/estatisticas_model.dart';
import 'api_client.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class EstatisticasService {
  final _client = ApiClient();

  Future<FiltrosEstatistica> getFiltros() async {
    final response = await _client.dio.get('/estatisticas/filtros');
    return FiltrosEstatistica.fromJson(response.data);
  }

  Future<List<ItemCurvaABC>> getCurvaABC({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? vendedorId,
    String? marca,
    String? divisao,
    String? colecao,
    int limit = 200,
  }) async {
    final response = await _client.dio.get(
      '/estatisticas/curva-abc',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
        if (vendedorId != null) 'vendedor_id': vendedorId,
        if (marca != null) 'marca': marca,
        if (divisao != null) 'divisao': divisao,
        if (colecao != null) 'colecao': colecao,
        'limit': limit,
      },
    );
    return (response.data as List).map((e) => ItemCurvaABC.fromJson(e)).toList();
  }

  Future<List<ItemVendasGrupo>> getPorMarca({
    DateTime? dataInicio, DateTime? dataFim,
    int? vendedorId, String? divisao, String? colecao,
  }) async {
    final response = await _client.dio.get('/estatisticas/por-marca', queryParameters: {
      if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
      if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
      if (vendedorId != null) 'vendedor_id': vendedorId,
      if (divisao != null) 'divisao': divisao,
      if (colecao != null) 'colecao': colecao,
    });
    return (response.data as List).map((e) => ItemVendasGrupo.fromJsonMarca(e)).toList();
  }

  Future<List<ItemVendasGrupo>> getPorDivisao({
    DateTime? dataInicio, DateTime? dataFim,
    int? vendedorId, String? marca, String? colecao,
  }) async {
    final response = await _client.dio.get('/estatisticas/por-divisao', queryParameters: {
      if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
      if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
      if (vendedorId != null) 'vendedor_id': vendedorId,
      if (marca != null) 'marca': marca,
      if (colecao != null) 'colecao': colecao,
    });
    return (response.data as List).map((e) => ItemVendasGrupo.fromJsonDivisao(e)).toList();
  }

  Future<List<ItemVendasGrupo>> getPorColecao({
    DateTime? dataInicio, DateTime? dataFim,
    int? vendedorId, String? marca, String? divisao,
  }) async {
    final response = await _client.dio.get('/estatisticas/por-colecao', queryParameters: {
      if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
      if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
      if (vendedorId != null) 'vendedor_id': vendedorId,
      if (marca != null) 'marca': marca,
      if (divisao != null) 'divisao': divisao,
    });
    return (response.data as List).map((e) => ItemVendasGrupo.fromJsonColecao(e)).toList();
  }

  Future<List<ItemVendasGrupo>> getPorGenero({
    DateTime? dataInicio, DateTime? dataFim,
    int? vendedorId, String? marca, String? divisao, String? colecao,
  }) async {
    final response = await _client.dio.get('/estatisticas/por-genero', queryParameters: {
      if (dataInicio != null) 'data_inicio': _dateFormat.format(dataInicio),
      if (dataFim != null) 'data_fim': _dateFormat.format(dataFim),
      if (vendedorId != null) 'vendedor_id': vendedorId,
      if (marca != null) 'marca': marca,
      if (divisao != null) 'divisao': divisao,
      if (colecao != null) 'colecao': colecao,
    });
    return (response.data as List).map((e) => ItemVendasGrupo.fromJsonGenero(e)).toList();
  }
}