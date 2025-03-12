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
    print(
      'Empieza el proceso de pintura',
    ); // Este print confirma que `paint` se llama.

    // Recorrer los niveles y capas para dibujar los tiles
    for (var level in gameData.levels) {
      print('Nivel: ${level.name}'); // Depuración del nivel
      for (var layer in level.layers) {
        print(
          'Capa: ${layer.name}, Visible: ${layer.visible}',
        ); // Depuración de capa
        if (layer.visible) {
          _drawLayer(canvas, layer); // Dibujar la capa
        }
      }
    }
  }

  // Función para dibujar cada capa
  void _drawLayer(Canvas canvas, Layer layer) {
    final image = imagesCache[layer.tilesSheetFile];
    final tileWidth = layer.tilesWidth.toDouble();
    final tileHeight = layer.tilesHeight.toDouble();

    print(
      'Dibujando capa: ${layer.name}',
    ); // Confirmar que estamos dibujando la capa

    // Recorrer el mapa de tiles y dibujar las imágenes en las posiciones correspondientes
    for (int y = 0; y < layer.tileMap.length; y++) {
      for (int x = 0; x < layer.tileMap[y].length; x++) {
        int tileIndex = layer.tileMap[y][x];

        // Si el valor es diferente de -1, significa que hay algo que dibujar
        if (tileIndex != -1) {
          double posX = x * tileWidth;
          double posY = y * tileHeight;

          print(
            'Dibujando tile en: ($posX, $posY)',
          ); // Confirmar la posición del tile

          // Dibuja la imagen en la posición calculada
          canvas.drawImage(image!, Offset(posX, posY), Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // No es necesario volver a pintar a menos que los datos cambien
  }
}
