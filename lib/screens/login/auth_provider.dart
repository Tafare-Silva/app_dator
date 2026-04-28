import 'package:flutter/material.dart';
import '../../services/services.dart';  // ← ADICIONE ISTO (import do ConfigService)

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool _carregando = false;
  String? _erro;
  String? _nomeUsuario;
  String? _grupo;

  bool get carregando => _carregando;
  String? get erro => _erro;
  String? get nomeUsuario => _nomeUsuario;
  String? get grupo => _grupo;
  bool get estaLogado => _nomeUsuario != null;

  Future<bool> login(String login, String senha) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      // ← DIAGNÓSTICO: Ver URL em debug
      final baseUrl = await ConfigService().getBaseUrl();
      print('🔗 URL do servidor: $baseUrl');
      print('🔐 Tentando login com usuário: $login');

      final token = await _authService.login(login, senha);
      _nomeUsuario = token.nomeUsuario;
      _grupo = token.grupo;
      
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