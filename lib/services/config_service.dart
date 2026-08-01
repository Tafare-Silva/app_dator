import 'app_storage.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const _keyServidorIp = 'servidor_ip';
  static const _keyServidorPorta = 'servidor_porta';
  static const _keyImpressoraIp = 'impressora_ip';
  static const _keyImpressoraPorta = 'impressora_porta';
  static const _keyNomeEmpresa = 'nome_empresa';

  Future<String> getServidorIp() async {
    return await AppStorage.read(_keyServidorIp) ?? '159.65.167.110';
  }

  Future<int> getServidorPorta() async {
    final v = await AppStorage.read(_keyServidorPorta);
    final porta = int.tryParse(v ?? '') ?? 8001; // ✅ padrão corrigido para 8001
    // ✅ migra automaticamente quem ainda tiver 8000 salvo
    if (porta == 8000) {
      await AppStorage.write(_keyServidorPorta, '8001');
      return 8001;
    }
    return porta;
  }

  Future<String> getImpressoraIp() async {
    return await AppStorage.read(_keyImpressoraIp) ?? '';
  }

  Future<int> getImpressoraPorta() async {
    final v = await AppStorage.read(_keyImpressoraPorta);
    return int.tryParse(v ?? '') ?? 9100;
  }

  Future<void> salvar({
    String? servidorIp,
    int? servidorPorta,
    String? impressoraIp,
    int? impressoraPorta,
    String? nomeEmpresa,
  }) async {
    if (servidorIp != null) await AppStorage.write(_keyServidorIp, servidorIp);
    if (servidorPorta != null) await AppStorage.write(_keyServidorPorta, servidorPorta.toString());
    if (impressoraIp != null) await AppStorage.write(_keyImpressoraIp, impressoraIp);
    if (impressoraPorta != null) await AppStorage.write(_keyImpressoraPorta, impressoraPorta.toString());
    if (nomeEmpresa != null) await AppStorage.write(_keyNomeEmpresa, nomeEmpresa);
  }

  Future<String> getNomeEmpresa() async {
    return await AppStorage.read(_keyNomeEmpresa) ?? '';
  }

  Future<String> getBaseUrl() async {
    final ip = await getServidorIp();
    final porta = await getServidorPorta();
    return 'http://$ip:$porta/api/v1';
  }
}
