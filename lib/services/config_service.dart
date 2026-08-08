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
    final ip = await AppStorage.read(_keyServidorIp) ?? '159.65.167.110';
    // ✅ migra automaticamente quem ainda tiver o IP direto salvo -- agora
    // o acesso é pelo domínio com HTTPS (ver getBaseUrl)
    if (ip == '159.65.167.110') {
      await AppStorage.write(_keyServidorIp, 'datorapp.blanjos.com.br');
      return 'datorapp.blanjos.com.br';
    }
    return ip;
  }

  Future<int> getServidorPorta() async {
    final v = await AppStorage.read(_keyServidorPorta);
    final porta = int.tryParse(v ?? '') ?? 443; // ✅ padrão agora é HTTPS (443)
    // ✅ migra automaticamente quem ainda tiver a porta antiga (HTTP) salva
    if (porta == 8000 || porta == 8001) {
      await AppStorage.write(_keyServidorPorta, '443');
      return 443;
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
    // Porta 443 = HTTPS (produção, via domínio) -- qualquer outra porta
    // continua HTTP (útil pra testar contra um servidor local/LAN sem TLS).
    if (porta == 443) {
      return 'https://$ip/api/v1';
    }
    return 'http://$ip:$porta/api/v1';
  }
}
