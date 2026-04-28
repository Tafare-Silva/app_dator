import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  final _config = ConfigService();

  ApiClient._internal() {
    // Inicializa com uma URL padrão provisória (será atualizada no interceptor)
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ));

    // Adiciona interceptor que SEMPRE atualiza a baseUrl ANTES de cada requisição
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ← MUDANÇA CRUCIAL: Sempre busca a URL mais recente (respeita mudanças em Configurações)
          final baseUrl = await _config.getBaseUrl();
          options.baseUrl = baseUrl;

          print('🔗 Conectando em: $baseUrl');
          print('📤 Requisição: ${options.method} ${options.path}');

          // Adiciona token se existir
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          print('❌ Erro: ${error.message}');
          print('   URI tentada: ${error.requestOptions.uri}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> salvarToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> removerToken() async {
    await _storage.delete(key: 'access_token');
  }

  Future<bool> temToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}