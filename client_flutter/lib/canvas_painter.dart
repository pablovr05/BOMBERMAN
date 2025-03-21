import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'game_data.dart';

class CanvasPainter extends CustomPainter {
  final AppData appData;
  final Map<String, ui.Image> imagesCache;

  CanvasPainter(this.appData, this.imagesCache);

  @override
  void paint(Canvas canvas, Size painterSize) async {
    final paint = Paint();
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
      paint,
    );

    var gameState = appData.gameState;
    var mapData = appData.mapData;

    // Drawing map and levels
    if (mapData != null) {
      // We will now loop through layers of the map data to draw tiles and other elements
      for (var level in appData.levels) {
        print('🎮 Level: ${level.name}');
        for (var layer in level.layers) {
          if (layer.visible) {
            print('🖌️ Drawing layer: ${layer.name}');
            _drawLayer(canvas, layer);
          }
        }
      }
    }

    // Draw players if any
    // Draw players if any
    if (gameState.isNotEmpty) {
      // Draw players (colored circles)
      var players = gameState["players"];
      if (players != null) {
        for (var player in players) {
          paint.color = _getColorFromString(player["color"]);
          Offset pos = _serverToPainterCoords(
            Offset(player["x"], player["y"]),
            painterSize,
          );

          double radius = _serverToPainterRadius(player["radius"], painterSize);
          canvas.drawCircle(pos, radius, paint);
        }
      } else {
        print('⚠️ No players found in gameState');
      }

      // Display player information text and ID
      String playerId = appData.playerData["id"];
      Color playerColor = _getColorFromString(appData.playerData["color"]);
      final paragraphStyle = ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
      );
      final textStyle = ui.TextStyle(color: playerColor, fontSize: 14);
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(
          "Press Up, Down, Left or Right keys to move (id: $playerId)",
        );
      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: painterSize.width));
      canvas.drawParagraph(
        paragraph,
        Offset(10, painterSize.height - paragraph.height - 5),
      );

      // Display the connection circle (top-right corner)
      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Convert server coordinates to painter coordinates
  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width,
      serverCoords.dy * painterSize.height,
    );
  }

  // Convert server radius to painter radius
  double _serverToPainterRadius(double serverRadius, Size painterSize) {
    return serverRadius * painterSize.width;
  }

  // Convert a string to a Color
  static Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case "green":
        return Colors.green;
      case "blue":
        return Colors.blue;
      case "orange":
        return Colors.orange;
      case "red":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  // Draw a layer's tiles on the canvas
  void _drawLayer(Canvas canvas, Layer layer) {
    final image = imagesCache[layer.tilesSheetFile];
    final tileWidth = layer.tilesWidth.toDouble();
    final tileHeight = layer.tilesHeight.toDouble();

    if (image == null) {
      print('⚠️ Image not found for ${layer.name}');
      return;
    }

    for (int y = 0; y < layer.tileMap.length; y++) {
      for (int x = 0; x < layer.tileMap[y].length; x++) {
        int tileIndex = layer.tileMap[y][x];

        if (tileIndex != -1) {
          double posX = x * tileWidth;
          double posY = y * tileHeight;

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
}
