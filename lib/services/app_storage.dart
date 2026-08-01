import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento chave-valor persistente, com implementação por plataforma.
///
/// No web, `flutter_secure_storage` usa a API `crypto.subtle` do navegador,
/// que só existe em contexto seguro (HTTPS/localhost) — em HTTP puro toda
/// leitura/escrita falha (o app quebra logo após o login, ao tentar salvar
/// o token). Por isso usamos `SharedPreferencesAsync` (sem criptografia, mas
/// funcional em qualquer origem) no web, e mantemos o storage seguro nativo
/// no Android/iOS/desktop.
///
/// Usamos `SharedPreferencesAsync` (não o `SharedPreferences.getInstance()`
/// legado) porque a implementação web do plugin, a partir da versão atual,
/// só registra a API nova — o legado responde com MissingPluginException.
class AppStorage {
  static const _secure = FlutterSecureStorage();
  static final _prefs = SharedPreferencesAsync();

  static Future<String?> read(String key) async {
    if (kIsWeb) {
      return _prefs.getString(key);
    }
    return _secure.read(key: key);
  }

  static Future<void> write(String key, String value) async {
    if (kIsWeb) {
      await _prefs.setString(key, value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  static Future<void> delete(String key) async {
    if (kIsWeb) {
      await _prefs.remove(key);
      return;
    }
    await _secure.delete(key: key);
  }
}
