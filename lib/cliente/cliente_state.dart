import 'package:flutter/foundation.dart';
import '../services/app_storage.dart';
import 'cliente_api.dart';

class ItemCarrinho {
  final ProdutoCatalogo produto;
  int quantidade;
  ItemCarrinho(this.produto, this.quantidade);
}

class ClienteState extends ChangeNotifier {
  static const maxPecas = 10; // o servidor também confere
  static const _keyLoja = 'cliente_loja';

  final api = ClienteApi();
  String? nome; // preenchido após o login
  final Map<int, ItemCarrinho> carrinho = {};
  bool carregado = false;

  String get loja => api.loja;
  bool get temLoja => api.loja.isNotEmpty;
  bool get logado => api.token != null;
  int get totalPecas => carrinho.values.fold(0, (s, i) => s + i.quantidade);
  double get totalValor => carrinho.values.fold(0.0, (s, i) => s + i.quantidade * i.produto.preco);

  Future<void> iniciar() async {
    api.loja = await AppStorage.read(_keyLoja) ?? '';
    await api.baseUrl();
    carregado = true;
    notifyListeners();
  }

  Future<void> escolherLoja(String id) async {
    if (id != api.loja) {
      carrinho.clear();
      sair(notificar: false);
    }
    api.loja = id;
    await AppStorage.write(_keyLoja, id);
    notifyListeners();
  }

  Future<void> entrar(String cpf, String codigo) async {
    nome = await api.verificarCodigo(cpf, codigo);
    notifyListeners();
  }

  void sair({bool notificar = true}) {
    api.token = null;
    nome = null;
    if (notificar) notifyListeners();
  }

  /// Sessão do servidor venceu (401): volta a pedir login na próxima ação.
  void sessaoExpirou() => sair();

  /// false se bateu no limite de peças.
  bool adicionar(ProdutoCatalogo p) {
    if (totalPecas >= maxPecas) return false;
    final i = carrinho[p.id];
    if (i == null) {
      carrinho[p.id] = ItemCarrinho(p, 1);
    } else {
      i.quantidade++;
    }
    notifyListeners();
    return true;
  }

  void remover(int id) {
    final i = carrinho[id];
    if (i == null) return;
    if (i.quantidade > 1) {
      i.quantidade--;
    } else {
      carrinho.remove(id);
    }
    notifyListeners();
  }

  void removerTudo(int id) {
    carrinho.remove(id);
    notifyListeners();
  }

  void limparCarrinho() {
    carrinho.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>> gerarCondicional() async {
    try {
      final r = await api.gerarCondicional({for (final e in carrinho.entries) e.key: e.value.quantidade});
      carrinho.clear();
      notifyListeners();
      return r;
    } on ClienteApiErro catch (e) {
      if (e.status == 401) sessaoExpirou();
      rethrow;
    }
  }
}
