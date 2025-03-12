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

          // **Calcular la posición dentro del tileset**
          int tilesPerRow = (image.width ~/ tileWidth);
          int tileX = (tileIndex % tilesPerRow) * tileWidth.toInt();
          int tileY = (tileIndex ~/ tilesPerRow) * tileHeight.toInt();

          // **Recortar el tile correcto del tileset**
          Rect srcRect = Rect.fromLTWH(tileX.toDouble(), tileY.toDouble(), tileWidth, tileHeight);
          Rect dstRect = Rect.fromLTWH(posX, posY, tileWidth, tileHeight);

          // **Dibujar solo el tile correcto**
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Permite actualizar el canvas en cada repaint si los datos cambian
  }
}
