import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _storage = const FlutterSecureStorage();

  static const _keyServidorIp = 'servidor_ip';
  static const _keyServidorPorta = 'servidor_porta';
  static const _keyImpressoraIp = 'impressora_ip';
  static const _keyImpressoraPorta = 'impressora_porta';

  Future<String> getServidorIp() async {
    return await _storage.read(key: _keyServidorIp) ?? '192.168.1.100';
  }

  Future<int> getServidorPorta() async {
    final v = await _storage.read(key: _keyServidorPorta);
    return int.tryParse(v ?? '') ?? 8000;
  }

  Future<String> getImpressoraIp() async {
    return await _storage.read(key: _keyImpressoraIp) ?? '';
  }

  Future<int> getImpressoraPorta() async {
    final v = await _storage.read(key: _keyImpressoraPorta);
    return int.tryParse(v ?? '') ?? 9100;
  }

  Future<void> salvar({
    String? servidorIp,
    int? servidorPorta,
    String? impressoraIp,
    int? impressoraPorta,
  }) async {
    if (servidorIp != null) await _storage.write(key: _keyServidorIp, value: servidorIp);
    if (servidorPorta != null) await _storage.write(key: _keyServidorPorta, value: servidorPorta.toString());
    if (impressoraIp != null) await _storage.write(key: _keyImpressoraIp, value: impressoraIp);
    if (impressoraPorta != null) await _storage.write(key: _keyImpressoraPorta, value: impressoraPorta.toString());
  }

  Future<String> getBaseUrl() async {
    final ip = await getServidorIp();
    final porta = await getServidorPorta();
    return 'http://$ip:$porta/api/v1';
  }
}