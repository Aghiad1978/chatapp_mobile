import 'dart:convert';
import 'package:chatapp/main.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import "package:chatapp/config.dart";

class Register {
  static Future<bool> registerUser({
    required String userName,
    required String email,
    required String code,
    required String mobile,
  }) async {
    String userUuid = Uuid().v4();
    mobile = "+$code$mobile";
    Map<String, dynamic> userData = {
      "userName": userName,
      "email": email,
      "mobile": mobile,
      "uuid": userUuid,
      "token": getIt<String>(instanceName: "token")
    };
    Uri url = Uri.parse("${Config.listenningIP}/api/v1/register");
    http.Response resp = await http.post(
      url,
      headers: {"Content-type": "application/json"},
      body: json.encode(userData),
    );

    if (resp.statusCode == 201) {
      Map<String, dynamic> data = json.decode(resp.body);
      await SecureStorage.container.writeSecureStorage("jwta", data["jwta"]!);
      await SecureStorage.container.writeSecureStorage("jwtr", data["jwtr"]!);
      await SharedpreferencesStorage.saveUserToSharedPreferences(
        userName,
        email,
        userUuid,
        mobile,
        code,
      );
      return true;
    } else {
      var error = json.decode(resp.body);
      throw Exception(error);
    }
  }
}
