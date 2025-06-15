import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:chatapp/screens/photo_shot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final getIt = GetIt.instance;
  CameraController? _cameraController;
  bool _isInitialized = false;
  String? _imagePath;
  late List<CameraDescription> cameras;
  int cameraSide = 0;
  final AudioPlayer _player = AudioPlayer();
  @override
  void initState() {
    cameras = getIt<List<CameraDescription>>();
    _initializeCamera(cameraSide);
    super.initState();
  }

  @override
  void dispose() {
    _cameraController?.dispose();

    _player.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File imagePath) async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    String location = getIt<String>(instanceName: "location");
    String imageName = "";
    if (location == "chat") {
      imageName = "${Uuid().v4()}.jpg";
    } else {
      String uuid = getIt<String>(instanceName: "uuid");
      imageName = "$uuid.jpg";
      final targetFile = File(path.join(extDir.path, imageName));
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
    }
    final String targetPath = path.join(extDir.path, imageName);
    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath.path,
        targetPath,
        quality: 50,
      );
      if (compressedFile != null) {
        await imagePath.delete();
        return File(compressedFile.path);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;
    final Directory extDir = await getApplicationDocumentsDirectory();

    _player.play(AssetSource("sound/camera.mp3"), volume: 0.1);
    String imageName = "";
    imageName = "${Uuid().v4()}.jpg";
    final String filePath = path.join(extDir.path, imageName);
    XFile file = await _cameraController!.takePicture();
    await file.saveTo(filePath);
    File imageFile = File(filePath);
    final compressedImage = await _compressImage(imageFile);
    if (compressedImage != null) {
      _imagePath = compressedImage.path;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoShot(
            photoPath: _imagePath!,
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }
  }

  Future<void> _initializeCamera(int cameraSide) async {
    if (cameras.isEmpty) return;
    CameraDescription camera;
    try {
      camera = cameras[cameraSide];
    } catch (e) {
      camera = cameras[0];
    }
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 8),
            Expanded(
              child: _isInitialized
                  ? CameraPreview(_cameraController!)
                  : Center(child: CircularProgressIndicator()),
            ),
            SizedBox(height: 5),
            SizedBox(
              height: MediaQuery.of(context).size.height / 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    color: Colors.green,
                    iconSize: 35,
                    onPressed: () {
                      setState(() {
                        print("CameraSide=$cameraSide");
                        cameraSide = cameraSide == 0 ? 1 : 0;
                        _initializeCamera(cameraSide);
                      });
                    },
                    icon: Icon(Icons.cameraswitch_outlined),
                  ),
                  FilledButton(
                    onPressed: () {
                      _takePicture();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Icon(color: Colors.red, Icons.circle, size: 45),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: Icon(Icons.cancel, size: 45, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
