import 'api_client.dart';
import '../models/models.dart';
export 'config_service.dart';

// ── Auth Service ──────────────────────────────────────────────────────────────

class AuthService {
  final _client = ApiClient();

  Future<TokenResponse> login(String login, String senha) async {
    final response = await _client.dio.post('/auth/login', data: {
      'usuario_login': login,
      'senha': senha,
    });
    final token = TokenResponse.fromJson(response.data);
    await _client.salvarToken(token.accessToken);
    return token;
  }

  Future<void> logout() async {
    await _client.removerToken();
  }

  Future<bool> estaLogado() => _client.temToken();
}

// ── Mesa Service ──────────────────────────────────────────────────────────────

class MesaService {
  final _client = ApiClient();

  Future<List<Mesa>> listarMesas() async {
    final response = await _client.dio.get('/mesas/');
    return (response.data as List).map((m) => Mesa.fromJson(m)).toList();
  }
}

// ── Item Mesa Service ─────────────────────────────────────────────────────────

class ItemMesaService {
  final _client = ApiClient();

  Future<List<ItemMesa>> listarItens(String nomeMesa) async {
    final response = await _client.dio.get('/mesas/$nomeMesa/itens/');
    return (response.data as List).map((i) => ItemMesa.fromJson(i)).toList();
  }

  Future<ItemMesa> adicionarItem({
    required String nomeMesa,
    required int produtoId,
    required double quantidade,
    required double vrUnitario,
    String? observacao,
  }) async {
    final response = await _client.dio.post(
      '/mesas/$nomeMesa/itens/',
      data: {
        'fk_produtos_produto': produtoId,
        'quantidade': quantidade,
        'vr_unitario_bruto': vrUnitario,
        if (observacao != null && observacao.isNotEmpty)
          'observacoes_item': observacao,
      },
    );
    return ItemMesa.fromJson(response.data);
  }

  Future<void> removerItem(String nomeMesa, int itemId) async {
    await _client.dio.delete('/mesas/$nomeMesa/itens/$itemId');
  }

  Future<ResumoConta> getConta(String nomeMesa) async {
    final response = await _client.dio.get('/mesas/$nomeMesa/itens/conta');
    return ResumoConta.fromJson(response.data);
  }
}

// ── Produto Service ───────────────────────────────────────────────────────────

class ProdutoService {
  final _client = ApiClient();

  Future<List<Produto>> buscarProdutos({String? busca}) async {
    final response = await _client.dio.get(
      '/produtos/',
      queryParameters: {
        'apenas_ativos': true,
        'limit': 50,
        if (busca != null && busca.isNotEmpty) 'busca': busca,
      },
    );
    return (response.data as List).map((p) => Produto.fromJson(p)).toList();
  }
}

// ── Impressão Service ─────────────────────────────────────────────────────────

class ImpressaoService {
  final _client = ApiClient();

  Future<void> imprimirPedido({
    required String nomeMesa,
    required String impressoraIp,
    int impressoraPorta = 9100,
  }) async {
    await _client.dio.post('/impressao/pedido', data: {
      'nome_mesa': nomeMesa,
      'impressora_ip': impressoraIp,
      'impressora_porta': impressoraPorta,
    });
  }

  Future<bool> testarConexao({
    required String impressoraIp,
    int impressoraPorta = 9100,
  }) async {
    try {
      await _client.dio.post('/impressao/testar-conexao', data: {
        'ip': impressoraIp,
        'porta': impressoraPorta,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}