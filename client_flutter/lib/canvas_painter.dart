import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'game_data.dart';
import 'package:flutter/services.dart'; // Para rootBundle
import 'SpriteSheet.dart';

class SpriteAnimation {
  final SpriteSheet spriteSheet;
  final double frameDuration;
  int _currentFrame = 0;
  double _elapsedTime = 0.0;

  SpriteAnimation(this.spriteSheet, {this.frameDuration = 0.1});

  void update(double deltaTime) {
    _elapsedTime += deltaTime;
    if (_elapsedTime >= frameDuration) {
      _elapsedTime = 0.0;
      _currentFrame =
          (_currentFrame + 1) % (spriteSheet.rows * spriteSheet.columns);
    }
  }

  ui.Rect get currentFrame {
    int row = _currentFrame ~/ spriteSheet.columns;
    int column = _currentFrame % spriteSheet.columns;
    return spriteSheet.getFrame(row, column);
  }
}

class CanvasPainter extends CustomPainter {
  final AppData appData;
  final Map<String, ui.Image> imagesCache;
  late SpriteAnimation spriteAnimation;

  CanvasPainter(this.appData, this.imagesCache) {
    // Inicializar la animación con la imagen y las filas/columnas adecuadas
    ui.Image spriteSheetImage =
        imagesCache["walk-front.png"]!; // Ejemplo con un sprite sheet
    SpriteSheet spriteSheet = SpriteSheet(
      image: spriteSheetImage,
      rows: 1, // Número de filas en el sprite sheet (ejemplo)
      columns: 4, // Número de columnas en el sprite sheet (ejemplo)
    );
    spriteAnimation = SpriteAnimation(spriteSheet);
  }

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
            _drawLayer(canvas, layer, painterSize);
          }
        }
      }
    }

    if (gameState.isNotEmpty) {
      // Dibuja los jugadores
      var players = gameState["players"];
      if (players != null) {
        for (var player in players) {
          paint.color = _getColorFromString(player["color"]);
          Offset pos = _serverToPainterCoords(
            Offset(
              (player["x"] as num).toDouble(),
              (player["y"] as num).toDouble(),
            ),
            painterSize,
          );

          // Obtener las direcciones del jugador, si no hay direcciones, usar "idle"
          String direction = "idle"; // Dirección por defecto

          // Verificar si las direcciones son una lista y tomar el primer valor
          if (appData.playerData["directions"] != null) {
            if (appData.playerData["directions"] is List) {
              var directionsList = appData.playerData["directions"];
              if (directionsList.isNotEmpty) {
                direction =
                    directionsList[0]; // Tomar la primera dirección de la lista
              }
            } else if (appData.playerData["directions"] is String) {
              direction =
                  appData.playerData["directions"]; // Usar el valor directo
            }
          }

          // Usamos la imagen correspondiente según la dirección
          ui.Image? playerImage = _getPlayerImageForDirection(direction);

          if (playerImage != null) {
            double width = 32.0; // Ancho de la imagen
            double height = 32.0; // Alto de la imagen

            // Dibujamos la imagen del jugador (ajusta el tamaño si es necesario)
            spriteAnimation.update(0.1); // Actualizamos la animación de sprites

            // Obtener el rectángulo correspondiente al frame actual de la animación
            ui.Rect frame = spriteAnimation.currentFrame;

            canvas.drawImageRect(
              playerImage,
              frame,
              Rect.fromLTWH(
                  pos.dx - width / 2, pos.dy - height / 2, width, height),
              paint,
            );
          } else {
            print('🚨 Imagen no disponible para la dirección: $direction');
          }
        }
      }

      // Mostrar información del jugador y su ID
      String playerId = appData.playerData["id"] ?? "Unknown";

      // Imprimir las direcciones de `playerData` para verlas en consola
      if (appData.playerData["directions"] != null) {
        print(
            '🚨 Direcciones del jugador: ${appData.playerData["directions"]}');
      }

      Color playerColor =
          _getColorFromString(appData.playerData["color"] ?? "black");
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
    }
  }

  // Método para obtener la imagen del jugador según la dirección
  ui.Image? _getPlayerImageForDirection(String direction) {
    String imageName;
    print(direction);
    // Dependiendo de la dirección, seleccionamos la imagen correspondiente
    switch (direction.toLowerCase()) {
      case "up":
        imageName = "walk-back.png";
        break;
      case "down":
        imageName = "walk-front.png";
        break;
      case "left":
        imageName = "walk-left.png";
        break;
      case "right":
        imageName = "walk-right.png";
        break;
      case "idle":
      default:
        imageName =
            "idle-front.png"; // Dirección por defecto cuando está en idle
        break;
    }

    // Verificar si la imagen está en el caché
    ui.Image? playerImage = imagesCache[imageName];
    if (playerImage == null) {
      print('🚨 No se encuentra la imagen: $imageName');
    } else {
      print('✔️ Imagen cargada: $imageName');
      print('Tamaño de la imagen: ${playerImage.width}x${playerImage.height}');
    }
    return playerImage;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Convertir coordenadas del servidor a coordenadas de pintado
  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width / 15, // Ajuste basado en el mapa
      serverCoords.dy * painterSize.height / 15,
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

  // Dibujar las capas del mapa
  void _drawLayer(Canvas canvas, Layer layer, Size painterSize) {
    final image = imagesCache[layer.tilesSheetFile];

    // Añadir un factor de escala
    final scaleFactor =
        1.5; // Escala por defecto, ajusta este valor según lo necesites.

    // Escalar el tamaño de las tiles
    final tileWidth = layer.tilesWidth.toDouble() * scaleFactor;
    final tileHeight = layer.tilesHeight.toDouble() * scaleFactor;

    // Verificamos si la imagen está en el caché
    if (image == null) {
      print(
          '🚨 No se encuentra la imagen para la capa: ${layer.tilesSheetFile}');
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
