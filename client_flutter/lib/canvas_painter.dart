import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'game_data.dart';

class CanvasPainter extends CustomPainter {
  final AppData appData;
  final Map<String, ui.Image> imagesCache;

  CanvasPainter(this.appData, this.imagesCache);

  @override
  void paint(Canvas canvas, Size painterSize) {
    final paint = Paint();
    paint.color = Colors.white;

    // Dibuja el fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
      paint,
    );

    var gameState = appData.gameState;
    var mapData = appData.mapData;

    // Dibuja el mapa y niveles
    if (mapData != null) {
      for (var level in mapData.levels) {
        var sortedLayers = List<Layer>.from(level.layers);
        sortedLayers.sort(
            (a, b) => a.depth.compareTo(b.depth)); // Ordenar por profundidad

        for (var layer in sortedLayers) {
          if (layer.visible) {
            _drawLayer(canvas, layer);
          }
        }
      }
    } else {
      print('⚠️ No se encontró mapa en appData'); // Mensaje si no hay mapa
    }
    print("1");
    if (gameState.isNotEmpty) {
      print("2");
      print(
          '🧑‍🤝‍🧑 Jugadores encontrados. Procesando...'); // Mensaje en consola
      var players = gameState["players"];
      if (players != null) {
        print("3");
        for (var player in players) {
          print('👤 Procesando jugador: ${player["id"]}');

          // Mostrar en consola cada vez que se dibuja un jugador
          paint.color = _getColorFromString(player["color"]);
          print("4");
          Offset pos = _serverToPainterCoords(
            Offset(
              (player["x"] as num).toDouble() * 36,
              (player["y"] as num).toDouble() * 36,
            ),
            painterSize,
          );

          print("5");
          double radius = _serverToPainterRadius(player["radius"], painterSize);

          // Mensaje indicando que se está dibujando el jugador
          print(
              '🎯 Dibujando jugador con ID: ${player["id"]} en posición: (${player["x"]}, ${player["y"]})');
          print('🎨 Color del jugador: ${player["color"]}, radio: $radius');
          print('📍 Posición en canvas: $pos');

          // Dibuja el jugador como un círculo
          canvas.drawCircle(pos, radius, paint);
        }
      } else {
        print('⚠️ No se encontraron jugadores en el estado del juego');
      }

      // Mostrar información del jugador y su ID
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

      // Mostrar el círculo de conexión (esquina superior derecha)
      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    } else {
      print('⚠️ No hay jugadores en el estado del juego');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Convertir coordenadas del servidor a coordenadas de pintado
  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx.toDouble(),
      serverCoords.dy.toDouble(),
    );
  }

  // Convertir el radio del servidor a radio de pintado
  double _serverToPainterRadius(double serverRadius, Size painterSize) {
    return serverRadius * painterSize.width;
  }

  // Convertir un string a un color
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

  void _drawLayer(Canvas canvas, Layer layer) {
    final image = imagesCache[layer.tilesSheetFile];

    // Añadir un factor de escala
    final scaleFactor =
        1.5; // Escala por defecto, ajusta este valor según lo necesites.

    // Escalar el tamaño de las tiles
    final tileWidth = layer.tilesWidth.toDouble() * scaleFactor;
    final tileHeight = layer.tilesHeight.toDouble() * scaleFactor;

    // Verificamos si la imagen está en el caché
    if (image == null) {
      print('⚠️ No se encontró imagen en caché para la capa: ${layer.name}');
      return;
    }

    // Iteramos por el tileMap de la capa y dibujamos las tiles
    for (int y = 0; y < layer.tileMap.length; y++) {
      for (int x = 0; x < layer.tileMap[y].length; x++) {
        int tileIndex = layer.tileMap[y][x];

        if (tileIndex != -1) {
          // Asegurarte de que posX y posY son valores double
          double posX =
              x * tileWidth; // Ajustamos la posición X por el factor de escala
          double posY =
              y * tileHeight; // Ajustamos la posición Y por el factor de escala

          // Cálculos para obtener la posición dentro de la imagen
          int tilesPerRow = (image.width ~/
              layer.tilesWidth); // Tiles por fila en la imagen original
          int tileX = (tileIndex % tilesPerRow) * layer.tilesWidth;
          int tileY = (tileIndex ~/ tilesPerRow) * layer.tilesHeight;

          // Ajustamos las coordenadas dentro de la imagen al escalarlas
          Rect srcRect = Rect.fromLTWH(tileX.toDouble(), tileY.toDouble(),
              layer.tilesWidth.toDouble(), layer.tilesHeight.toDouble());

          // Ajustamos el tamaño de destino para escalar la imagen
          Rect dstRect = Rect.fromLTWH(posX, posY, tileWidth, tileHeight);

          // Dibujar la tile en el canvas con el tamaño escalado
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }
  }
}
