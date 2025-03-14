import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'game_data.dart';

class CanvasPainter extends CustomPainter {
  final GameData gameData;
  final Map<String, ui.Image> imagesCache;

  CanvasPainter({required this.gameData, required this.imagesCache});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    print('🔹 Empieza el proceso de pintura');

    for (var level in gameData.levels) {
      print('🎮 Nivel: ${level.name}');
      for (var layer in level.layers) {
        if (layer.visible) {
          print('🖌️ Dibujando capa: ${layer.name}');
          _drawLayer(canvas, layer);
        }

        _drawPlayer(canvas, layer, 1, 1);
      }
    }
  }

  void _drawLayer(Canvas canvas, Layer layer) {
    final image = imagesCache[layer.tilesSheetFile];
    final tileWidth = layer.tilesWidth.toDouble();
    final tileHeight = layer.tilesHeight.toDouble();

    if (image == null) {
      print('⚠️ No se encontró la imagen para ${layer.name}');
      return;
    }

    for (int y = 0; y < layer.tileMap.length; y++) {
      for (int x = 0; x < layer.tileMap[y].length; x++) {
        int tileIndex = layer.tileMap[y][x];

        if (tileIndex.toInt() != -1) {
          double posX = x * tileWidth;
          double posY = y * tileHeight;

          print('🧩 Tile $tileIndex en ($posX, $posY)');

          int tilesPerRow = (image.width ~/ tileWidth);
          int tileX = (tileIndex % tilesPerRow) * tileWidth.toInt();
          int tileY = (tileIndex ~/ tilesPerRow) * tileHeight.toInt();

          Rect srcRect = Rect.fromLTWH(
              tileX.toDouble(), tileY.toDouble(), tileWidth, tileHeight);
          Rect dstRect = Rect.fromLTWH(posX, posY, tileWidth, tileHeight);

          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }
  }

  void _drawPlayer(Canvas canvas, Layer layer, double posX, double posY) {
    posX = posX * 32;
    posY = posY * 32;

    print('🧩 Personaje dibujado en ($posX, $posY)');

    // Coordenadas para dibujar un círculo de 16x16
    double centerX = posX + 32 / 2;
    double centerY = posY + 32 / 2;
    double radius = 12.0; // Radio de 8, ya que el diámetro es 16

    // Dibujar el círculo en el canvas
    Paint paint = Paint()
      ..color = Color.fromARGB(255, 9, 255, 0)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
