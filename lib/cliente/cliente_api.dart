import 'package:dio/dio.dart';
import '../services/config_service.dart';

/// Erro com mensagem pronta para mostrar ao cliente.
/// [codigo] vem do backend em casos especiais ('sem_cadastro', 'sem_celular').
class ClienteApiErro implements Exception {
  final String mensagem;
  final String? codigo;
  final int? status;
  ClienteApiErro(this.mensagem, {this.codigo, this.status});
  @override
  String toString() => mensagem;
}

class ProdutoCatalogo {
  final int id;
  final String nome;
  final String? referencia, cor, tamanho, colecao, genero, divisao;
  final double preco;
  ProdutoCatalogo.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        nome = j['nome'] ?? '',
        referencia = j['referencia'],
        cor = j['cor'],
        tamanho = j['tamanho'],
        colecao = j['colecao'],
        genero = j['genero'],
        divisao = j['divisao'],
        preco = (j['preco'] as num).toDouble();
}

class Filtros {
  final List<String> divisoes, generos, colecoes;
  final bool temNovidades;
  Filtros(this.divisoes, this.generos, this.colecoes, this.temNovidades);
  factory Filtros.fromJson(Map<String, dynamic> j) {
    List<String> nomes(String k) =>
        ((j[k] ?? []) as List).map((e) => e['nome'] as String).toList();
    return Filtros(nomes('divisoes'), nomes('generos'), nomes('colecoes'),
        j['tem_novidades'] == true);
  }
  static final vazio = Filtros([], [], [], false);
}

class TituloCliente {
  final DateTime vencimento;
  final double valor;
  final String? documento, parcela;
  final bool vencido;
  TituloCliente.fromJson(Map<String, dynamic> j)
      : vencimento = DateTime.parse(j['vencimento']),
        valor = (j['valor'] as num).toDouble(),
        documento = j['documento']?.toString(),
        parcela = j['parcela']?.toString(),
        vencido = j['vencido'] == true;
}

class ClienteApi {
  String? token;
  String loja = '';
  Future<String>? _base;

  Future<String> baseUrl() => _base ??= ConfigService().getBaseUrl();

  Future<Dio> _dio() async => Dio(BaseOptions(
        baseUrl: await baseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ));

  /// URL da foto (pública, sem token) para usar em Image.network.
  Future<String> fotoUrl(int id) async =>
      '${await baseUrl()}/cliente/catalogo/$id/foto?loja=$loja';

  ClienteApiErro _erro(DioException e) {
    final d = e.response?.data;
    var det = d is Map ? d['detail'] : null;
    if (det is Map) {
      return ClienteApiErro(det['mensagem']?.toString() ?? 'Erro.',
          codigo: det['codigo']?.toString(), status: e.response?.statusCode);
    }
    if (det is List) det = 'Dados inválidos.';
    final s = e.response?.statusCode;
    if (s == null) {
      return ClienteApiErro('Sem conexão. Verifique sua internet e tente de novo.');
    }
    return ClienteApiErro(det?.toString() ?? 'Algo deu errado. Tente de novo.', status: s);
  }

  Future<T> _try<T>(Future<T> Function(Dio) f) async {
    try {
      return await f(await _dio());
    } on DioException catch (e) {
      throw _erro(e);
    }
  }

  Future<List<ProdutoCatalogo>> catalogo({
    String? busca, String? divisao, String? genero, String? colecao,
    bool novidades = false, int offset = 0, int limit = 30,
  }) =>
      _try((d) async {
        final r = await d.get('/cliente/catalogo/', queryParameters: {
          'loja': loja,
          if (busca != null && busca.isNotEmpty) 'busca': busca,
          if (divisao != null) 'divisao': divisao,
          if (genero != null) 'genero': genero,
          if (colecao != null) 'colecao': colecao,
          if (novidades) 'novidades': true,
          'offset': offset,
          'limit': limit,
        });
        return (r.data as List).map((e) => ProdutoCatalogo.fromJson(e)).toList();
      });

  Future<Filtros> filtros() => _try((d) async =>
      Filtros.fromJson((await d.get('/cliente/catalogo/filtros', queryParameters: {'loja': loja})).data));

  /// Devolve o celular mascarado para mostrar ("(**) *****-1234").
  Future<String> solicitarCodigo(String cpf) => _try((d) async {
        final r = await d.post('/cliente/auth/solicitar-codigo', data: {'cpf': cpf, 'loja': loja});
        return r.data['enviado_para'] as String;
      });

  Future<String> verificarCodigo(String cpf, String codigo) => _try((d) async {
        final r = await d.post('/cliente/auth/verificar-codigo',
            data: {'cpf': cpf, 'loja': loja, 'codigo': codigo});
        token = r.data['access_token'];
        return (r.data['nome'] ?? '') as String;
      });

  Future<Map<String, dynamic>> gerarCondicional(Map<int, int> itens) => _try((d) async {
        final r = await d.post('/cliente/condicionais', data: {
          'itens': itens.entries.map((e) => {'produto_id': e.key, 'quantidade': e.value}).toList(),
        });
        return Map<String, dynamic>.from(r.data);
      });

  Future<({double total, double totalVencido, List<TituloCliente> titulos})> titulos() =>
      _try((d) async {
        final r = await d.get('/cliente/titulos');
        return (
          total: (r.data['total'] as num).toDouble(),
          totalVencido: (r.data['total_vencido'] as num).toDouble(),
          titulos: (r.data['titulos'] as List).map((e) => TituloCliente.fromJson(e)).toList(),
        );
      });
}
