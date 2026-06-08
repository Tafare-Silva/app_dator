import '../models/produto_model.dart';
import 'api_client.dart';

class ProdutoService {
  final _client = ApiClient();

  Future<List<ProdutoResumo>> listarProdutos({
    bool apenasAtivos = true,
    String? busca,
    String? codigoBarras,
    int? pkChaveExato,
    int limit = 500,
    int offset = 0,
  }) async {
    final response = await _client.dio.get(
      '/produtos/',
      queryParameters: {
        'apenas_ativos': apenasAtivos,
        if (busca != null && busca.isNotEmpty) 'busca': busca,
        // ✅ código de barras busca na tabela E no pk_chave (etiqueta própria)
        if (codigoBarras != null && codigoBarras.isNotEmpty)
          'codigo_barras': codigoBarras,
        // ✅ busca exata por pk_chave
        if (pkChaveExato != null) 'pk_chave_exato': pkChaveExato,
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List)
        .map((p) => ProdutoResumo.fromJson(p))
        .toList();
  }
}