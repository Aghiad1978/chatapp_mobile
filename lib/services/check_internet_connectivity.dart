import 'package:chatapp/config.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class CheckInternetConnectivity {
  static Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    for (var element in connectivityResult) {
      if (element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi) {
        final String? jwta = await SecureStorage.container.readSecureStorage(
          "jwta",
        );
        if (jwta == null) {
          throw Exception("Null JWTA");
        }
        final url = Uri.parse("${Config.listenningIP}/api/v1/ping");
        try {
          final resp = await http.get(
            url,
            headers: {"authorization": "Bearer $jwta"},
          );
          if (resp.statusCode == 200) {
            return true;
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
    }
    return false;
  }
}
