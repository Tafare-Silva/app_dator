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
  static const _keyNomeEmpresa = 'nome_empresa';

  Future<String> getServidorIp() async {
    return await _storage.read(key: _keyServidorIp) ?? '159.65.167.110';
  }

  Future<int> getServidorPorta() async {
    final v = await _storage.read(key: _keyServidorPorta);
    final porta = int.tryParse(v ?? '') ?? 8001; // ✅ padrão corrigido para 8001
    // ✅ migra automaticamente quem ainda tiver 8000 salvo
    if (porta == 8000) {
      await _storage.write(key: _keyServidorPorta, value: '8001');
      return 8001;
    }
    return porta;
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
    String? nomeEmpresa,
  }) async {
    if (servidorIp != null) await _storage.write(key: _keyServidorIp, value: servidorIp);
    if (servidorPorta != null) await _storage.write(key: _keyServidorPorta, value: servidorPorta.toString());
    if (impressoraIp != null) await _storage.write(key: _keyImpressoraIp, value: impressoraIp);
    if (impressoraPorta != null) await _storage.write(key: _keyImpressoraPorta, value: impressoraPorta.toString());
    if (nomeEmpresa != null) await _storage.write(key: _keyNomeEmpresa, value: nomeEmpresa);
  }

  Future<String> getNomeEmpresa() async {
    return await _storage.read(key: _keyNomeEmpresa) ?? '';
  }

  Future<String> getBaseUrl() async {
    final ip = await getServidorIp();
    final porta = await getServidorPorta();
    return 'http://$ip:$porta/api/v1';
  }
}