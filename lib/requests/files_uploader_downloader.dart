import 'dart:convert';
import 'dart:io';
import 'package:chatapp/config.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import "package:http/http.dart" as http;

class FilesUploaderDownloader {
  static Future<String?> uploadMediaIntoServer(
    String filePath,
    String type,
  ) async {
    File imageFile = File(filePath);
    Uri url = Uri.parse("${Config.listenningIP}/uploads");
    final String? jwta = await SecureStorage.container.readSecureStorage(
      "jwta",
    );
    if (jwta == null) {
      throw Exception("Null JWTA");
    }
    http.MultipartRequest request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $jwta";
    request.headers["type"] = type;
    request.headers["uuid"] = getIt<String>(instanceName: "uuid");
    http.ByteStream stream = http.ByteStream(imageFile.openRead());
    var length = imageFile.lengthSync();
    //Later i need to check if the image is existed on the server
    //if yes will return the filename directly
    //maybe using socket to send and get answer
    var multiPartFile = http.MultipartFile(
      type,
      stream,
      length,
      filename: basename(filePath),
    );
    request.files.add(multiPartFile);
    var resp = await request.send();
    if (resp.statusCode == 200) {
      var respString = await resp.stream.bytesToString();
      var jsonResp = jsonDecode(respString);
      String filename = jsonResp["filename"].toString().split("/").last;
      return filename;
    } else {
      return null;
    }
  }

  static Future<String?> downloadFileFromServer(
    String fileName,
    String type,
  ) async {
    try {
      final uri = Uri.parse("${Config.listenningIP}/uploads/$type/$fileName");
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(resp.bodyBytes);
        return file.path;
      } else {
        return type;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> getAssetFromInternal(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName");
    if (await file.exists()) {
      return file.path;
    } else {
      return null;
    }
  }
}
