import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// No iOS (Safari em modo "Adicionar à Tela de Início"), o navegador guarda
/// uma cópia bem mais teimosa dos arquivos do app do que o Chrome/Android —
/// mesmo depois de um deploy novo, o usuário pode continuar vendo a versão
/// antiga por dias. Isso desregistra o service worker do Flutter e apaga
/// tudo que ele guardou no Cache Storage, forçando o navegador a buscar cada
/// arquivo de novo no servidor no próximo carregamento.
class AppUpdateService {
  static bool get disponivel => true;

  static Future<void> forcarAtualizacao() async {
    await _desregistrarServiceWorkers();
    await _limparCaches();
    web.window.location.reload();
  }

  static Future<void> _desregistrarServiceWorkers() async {
    try {
      final registrations =
          (await web.window.navigator.serviceWorker.getRegistrations().toDart).toDart;
      for (final registration in registrations) {
        await registration.unregister().toDart;
      }
    } catch (_) {
      // Sem service worker registrado (ex: já desregistrado) — segue o fluxo.
    }
  }

  static Future<void> _limparCaches() async {
    try {
      final chaves = (await web.window.caches.keys().toDart).toDart;
      for (final chave in chaves) {
        await web.window.caches.delete(chave.toDart).toDart;
      }
    } catch (_) {
      // Cache Storage indisponível (ex: navegador muito antigo) — segue o fluxo.
    }
  }
}
