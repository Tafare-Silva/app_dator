import 'package:flutter/material.dart';
import '../../services/services.dart';  // ← ADICIONE ISTO (import do ConfigService)

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool _carregando = false;
  String? _erro;
  String? _nomeUsuario;
  String? _grupo;
  String? _empresa;
  String? _empresaNome;

  bool get carregando => _carregando;
  String? get erro => _erro;
  String? get nomeUsuario => _nomeUsuario;
  String? get grupo => _grupo;
  String? get empresa => _empresa;
  String? get empresaNome => _empresaNome;
  bool get estaLogado => _nomeUsuario != null;

  /// Última loja escolhida neste aparelho, pra pré-selecionar na tela de login.
  Future<String?> empresaSalva() => _authService.empresaSalva();

  Future<bool> login(String login, String senha, String empresa) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      // ← DIAGNÓSTICO: Ver URL em debug
      final baseUrl = await ConfigService().getBaseUrl();
      print('🔗 URL do servidor: $baseUrl');
      print('🔐 Tentando login com usuário: $login');

      final token = await _authService.login(login, senha, empresa);
      _nomeUsuario = token.nomeUsuario;
      _grupo = token.grupo;
      _empresa = token.empresa;
      _empresaNome = token.empresaNome;

      print('✅ Login bem-sucedido!');
      return true;
    } catch (e) {
      print('❌ Erro no login: $e');
      _erro = _mensagemErro(e);
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _nomeUsuario = null;
    _grupo = null;
    _empresa = null;
    _empresaNome = null;
    notifyListeners();
  }

  String _mensagemErro(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('401')) return 'Login ou senha inválidos.';
      if (msg.contains('SocketException') || msg.contains('connection')) {
        return 'Sem conexão com o servidor. Verifique a rede.';
      }
    }
    return 'Erro inesperado. Tente novamente.';
  }
}