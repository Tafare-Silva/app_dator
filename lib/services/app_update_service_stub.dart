/// Implementação vazia usada em Android/iOS nativos e desktop — o conceito de
/// "service worker" e cache do navegador só existe no build web.
class AppUpdateService {
  static bool get disponivel => false;

  static Future<void> forcarAtualizacao() async {}
}
