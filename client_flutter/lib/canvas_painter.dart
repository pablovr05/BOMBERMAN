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
  late SpriteAnimation spriteAnimationUp;
  late SpriteAnimation spriteAnimationDown;
  late SpriteAnimation spriteAnimationLeft;
  late SpriteAnimation spriteAnimationRight;
  String _lastValidDirection = "left"; // Dirección predeterminada
  String playerId = ""; // Ahora está declarado antes de ser utilizado

  CanvasPainter(this.appData, this.imagesCache) {
    // Cargar diferentes hojas de sprites para cada dirección
    ui.Image walkFront = imagesCache["walk-front.png"]!;
    ui.Image walkBack = imagesCache["walk-back.png"]!;
    ui.Image walkLeft = imagesCache["walk-left.png"]!;
    ui.Image walkRight = imagesCache["walk-right.png"]!;

    // Crear animaciones para cada dirección
    spriteAnimationUp =
        SpriteAnimation(SpriteSheet(image: walkBack, rows: 1, columns: 4));
    spriteAnimationDown =
        SpriteAnimation(SpriteSheet(image: walkFront, rows: 1, columns: 4));
    spriteAnimationLeft =
        SpriteAnimation(SpriteSheet(image: walkLeft, rows: 1, columns: 4));
    spriteAnimationRight =
        SpriteAnimation(SpriteSheet(image: walkRight, rows: 1, columns: 4));
  }

  @override
  void paint(Canvas canvas, Size painterSize) {
    final paint = Paint()..color = Colors.white;

    // Si el jugador está muerto, pintar toda la pantalla en gris o negro
    if (appData.playerData["isDead"] == true) {
      // Dibujar una capa gris/negra sobre toda la pantalla
      paint.color = Colors.black.withOpacity(0.7); // Color negro con opacidad
      canvas.drawRect(
        Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
        paint,
      );
      return; // Si está muerto, no dibujamos nada más
    }

    // Si el jugador no está muerto, sigue con el dibujo normal
    canvas.drawRect(
      Rect.fromLTWH(0, 0, painterSize.width, painterSize.height),
      paint,
    );

    var gameState = appData.gameState;
    var mapData = appData.mapData;

    if (mapData != null) {
      for (var level in mapData.levels) {
        var sortedLayers = List<Layer>.from(level.layers);
        sortedLayers.sort((a, b) => a.depth.compareTo(b.depth));

        for (var layer in sortedLayers) {
          if (layer.visible) {
            _drawLayer(canvas, layer, painterSize);
          }
        }
      }
    }

    if (gameState.isNotEmpty) {
      var players = gameState["players"];
      if (players != null) {
        for (var player in players) {
          // Si el jugador está muerto, no lo dibujamos
          if (player["id"] == appData.playerData["id"] &&
              player["isDead"] == true) {
            continue; // Salimos del bucle y no dibujamos el jugador
          }

          paint.color = _getColorFromString(player["color"]);
          Offset pos = _serverToPainterCoords(
            Offset(
              (player["x"] as num).toDouble(),
              (player["y"] as num).toDouble(),
            ),
            painterSize,
          );

          // Obtener dirección actual desde playerDirections usando la playerId
          String direction =
              appData.playerDirections[player["id"]] ?? _lastValidDirection;

          // Si la dirección es válida, actualizamos la dirección
          if (direction.isNotEmpty && direction != "none") {
            _lastValidDirection = direction;
          }

          // Actualizamos la animación dependiendo de la dirección
          SpriteAnimation currentAnimation;

          switch (_lastValidDirection.toLowerCase()) {
            case "up":
              currentAnimation = spriteAnimationUp;
              break;
            case "down":
              currentAnimation = spriteAnimationDown;
              break;
            case "left":
              currentAnimation = spriteAnimationLeft;
              break;
            case "right":
              currentAnimation = spriteAnimationRight;
              break;
            default:
              currentAnimation =
                  spriteAnimationDown; // Dirección predeterminada
          }

          // Actualizamos el cuadro de la animación
          currentAnimation.update(0.1);
          ui.Rect frame = currentAnimation.currentFrame;

          double width = 32.0;
          double height = 32.0;

          canvas.drawImageRect(
            _getPlayerImageForDirection(_lastValidDirection)!,
            frame,
            Rect.fromLTWH(
              pos.dx - width / 2,
              pos.dy - height / 2,
              width,
              height,
            ),
            paint,
          );
        }
      }

      playerId = appData.playerData["id"] ?? "Unknown";
      Color playerColor =
          _getColorFromString(appData.playerData["color"] ?? "black");
      final paragraphStyle =
          ui.ParagraphStyle(textDirection: TextDirection.ltr);
      final textStyle = ui.TextStyle(color: playerColor, fontSize: 14);
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText("Press Up, Down, Left or Right keys to move (id: $playerId)");
      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: painterSize.width));
      canvas.drawParagraph(
        paragraph,
        Offset(10, painterSize.height - paragraph.height - 5),
      );

      paint.color = appData.isConnected ? Colors.green : Colors.red;
      canvas.drawCircle(Offset(painterSize.width - 10, 10), 5, paint);
    }
  }

  // Resto del código (como _getPlayerImageForDirection) sigue igual

  ui.Image? _getPlayerImageForDirection(String direction) {
    String imageName;
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
      default:
        return null;
    }

    return imagesCache[imageName];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Offset _serverToPainterCoords(Offset serverCoords, Size painterSize) {
    return Offset(
      serverCoords.dx * painterSize.width / 15,
      serverCoords.dy * painterSize.height / 15,
    );
  }

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

  void _drawLayer(Canvas canvas, Layer layer, Size painterSize) {
    final image = imagesCache[layer.tilesSheetFile];
    final scaleFactor = 1.5;
    final tileWidth = layer.tilesWidth.toDouble() * scaleFactor;
    final tileHeight = layer.tilesHeight.toDouble() * scaleFactor;

    if (image == null) return;

    for (int y = 0; y < layer.tileMap.length; y++) {
      for (int x = 0; x < layer.tileMap[y].length; x++) {
        int tileIndex = layer.tileMap[y][x];
        if (tileIndex != -1) {
          double posX = x * tileWidth;
          double posY = y * tileHeight;

          int tilesPerRow = (image.width ~/ layer.tilesWidth);
          int tileX = (tileIndex % tilesPerRow) * layer.tilesWidth;
          int tileY = (tileIndex ~/ tilesPerRow) * layer.tilesHeight;

          Rect srcRect = Rect.fromLTWH(tileX.toDouble(), tileY.toDouble(),
              layer.tilesWidth.toDouble(), layer.tilesHeight.toDouble());
          Rect dstRect = Rect.fromLTWH(posX, posY, tileWidth, tileHeight);

          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }
  }
}
