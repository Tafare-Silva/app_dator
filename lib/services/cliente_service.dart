import '../models/cliente_model.dart';
import 'api_client.dart';

class ClienteService {
  final _client = ApiClient();

  Future<List<Cliente>> buscarClientes(String busca, {int limit = 30}) async {
    if (busca.trim().length < 2) return [];
    final response = await _client.dio.get(
      '/clientes/',
      queryParameters: {'busca': busca.trim(), 'limit': limit},
    );
    return (response.data as List).map((c) => Cliente.fromJson(c)).toList();
  }
}
