import 'package:client/canvasPainter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'game_data.dart'; // Asegúrate de que este archivo esté importado

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<GameData> gameData;
  late Map<String, ui.Image> imagesCache;

  @override
  void initState() {
    super.initState();
    gameData = loadGameData();
    imagesCache = {}; // Lo inicializamos vacío
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bomberman',
      home: Scaffold(
        appBar: AppBar(title: Text('Bomberman')),
        body: FutureBuilder<GameData>(
          future: gameData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var gameData = snapshot.data!;
              return FutureBuilder<Map<String, ui.Image>>(
                future: loadImages(['grass.png', 'wall.png']),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (imageSnapshot.hasError) {
                    return Center(child: Text('Error loading images.'));
                  } else {
                    imagesCache = imageSnapshot.data!;
                    return CustomPaint(
                      size: Size(800, 600),
                      painter: CanvasPainter(
                        gameData: gameData,
                        imagesCache: imagesCache,
                      ),
                    );
                  }
                },
              );
            } else {
              return Center(child: Text('No data'));
            }
          },
        ),
      ),
    );
  }
}

Future<GameData> loadGameData() async {
  final String response = await rootBundle.loadString('assets/game_data.json');
  final data = jsonDecode(response);
  return GameData.fromJson(data);
}

Future<ui.Image> loadImage(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final List<int> bytes = data.buffer.asUint8List();
  return await decodeImageFromList(Uint8List.fromList(bytes));
}

Future<Map<String, ui.Image>> loadImages(List<String> paths) async {
  Map<String, ui.Image> images = {};
  for (var path in paths) {
    images[path] = await loadImage('assets/$path');
  }
  return images;
}
