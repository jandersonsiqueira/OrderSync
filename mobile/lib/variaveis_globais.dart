import 'package:shared_preferences/shared_preferences.dart';

const bool DEBUG_LINKS = false;
const String LINK_BASE = DEBUG_LINKS ? 'http://10.0.2.2:5000': 'https://order-sync-three.vercel.app';

class VariaveisGlobais {
  // Método para salvar o UID no cache
  static Future<void> saveUidToCache(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  // Método para obter o UID do cache
  static Future<String?> getUidFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid');
  }

  // Método opcional para remover o UID do cache (Logout ou reset de sessão)
  static Future<void> removeUidFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
  }
}
