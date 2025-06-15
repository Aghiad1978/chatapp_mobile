import 'package:shared_preferences/shared_preferences.dart';

class SharedpreferencesStorage {
  static Future<void> saveUserToSharedPreferences(String userName, String email,
      String uuid, String mobile, String code) async {
    final instance = await SharedPreferences.getInstance();
    await instance.setString("userName", userName);
    await instance.setString("email", email);
    await instance.setString("uuid", uuid);
    await instance.setString("mobile", mobile);
    await instance.setString("code", code);
    await instance.setString("image", "assets/images/avatar.png");
    await instance.setBool("getUsers", false);
  }

  static Future<String> getJustOne(String dataPiece) async {
    final instance = await SharedPreferences.getInstance();
    String? data = instance.getString(dataPiece);
    return data!;
  }

  static Future<bool> getUsersAdded(String dataPiece) async {
    final instance = await SharedPreferences.getInstance();
    bool? data = instance.getBool(dataPiece);
    return data!;
  }

  static Future<Map<String, String>> getUsersData() async {
    final instance = await SharedPreferences.getInstance();
    Map<String, String> data = {};
    data["userName"] = instance.getString("userName")!;
    data["email"] = instance.getString("email")!;
    data["uuid"] = instance.getString("uuid")!;
    data["mobile"] = instance.getString("mobile")!;
    data["code"] = instance.getString("code")!;
    return data;
  }

  static Future<void> deleteSharedPreferences() async {
    final instance = await SharedPreferences.getInstance();
    await instance.clear();
  }

  static Future<void> modifyGetUsersKey() async {
    final instance = await SharedPreferences.getInstance();
    await instance.setBool("getUsers", true);
  }
}
