class AppConfig {
  // Troque pelo IP da máquina onde o FastAPI está rodando
  // Em desenvolvimento: IP local da sua rede (ex: 192.168.1.100:8000)
  // Em produção: domínio ou IP público
  //static const String baseUrl = 'http://192.168.0.106:8000/api/v1';

  static const String tokenKey = 'access_token';

  static const Duration timeoutConexao = Duration(seconds: 10);
}
