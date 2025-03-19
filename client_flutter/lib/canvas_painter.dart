import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';

class CanvasPainter extends CustomPainter {
  final AppData appData;
  late ui.Image grassImage;
  late ui.Image wallImage;

  CanvasPainter(this.appData);

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

    if (gameState.isNotEmpty) {
      // Dibuixar els jugadors (cercles de colors)
      if (gameState["players"] != null) {
        for (var player in gameState["players"]) {
          paint.color = _getColorFromString(player["color"]);
          Offset pos = _serverToPainterCoords(
            Offset(player["x"], player["y"]),
            painterSize,
          );

          double radius = _serverToPainterRadius(player["radius"], painterSize);
          canvas.drawCircle(pos, radius, paint);
        }
      }

      // Dibujar el mapa si existe
      if (mapData != null) {
        _drawMap(canvas, mapData, painterSize);
      }

      // Mostrar el texto informativo y el identificador del jugador
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

      // Mostrar el círculo de conexión (arriba a la derecha)
      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Convertir coordenadas del servidor a coordenadas en el lienzo
  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width,
      serverCoords.dy * painterSize.height,
    );
  }

  // Convertir radio del servidor a radio en el lienzo
  double _serverToPainterRadius(double serverRadius, Size painterSize) {
    return serverRadius * painterSize.width;
  }

  // Convertir cadena de texto en un color
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

  void _drawMap(Canvas canvas, dynamic mapData, Size painterSize) async {}
}
