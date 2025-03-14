import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'utilsWebsockets.dart';

class AppData extends ChangeNotifier {
  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  final String _wsServer = "localhost";
  final int _wsPort = 8888;
  bool isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 3);

  Map<String, ui.Image> imagesCache = {};
  GameData? gameData;
  dynamic playerData;
  Map<String, dynamic> gameState = {};

  AppData() {
    _connectToWebSocket();
    loadGameDataFromAssets();
  }

  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      print("Error de WebSocket: $error");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Tratar desconexiones
  void _onWebSocketClosed() {
    if (kDebugMode) {
      print("WebSocket tancat. Intentant reconnectar...");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Programar una reconexión
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      if (kDebugMode) {
        print(
            "Intent de reconnexió #$_reconnectAttempts en ${_reconnectDelay.inSeconds} segons...");
      }
      Future.delayed(_reconnectDelay, () {
        _connectToWebSocket();
      });
    } else {
      if (kDebugMode) {
        print(
            "No es pot reconnectar al servidor després de $_maxReconnectAttempts intents.");
      }
    }
  }

  void _connectToWebSocket() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print("S'ha assolit el màxim d'intents de reconnexió.");
      }
      return;
    }

    isConnected = false;
    notifyListeners();

    _wsHandler.connectToServer(
      _wsServer,
      _wsPort,
      _onWebSocketMessage,
      onError: _onWebSocketError,
      onDone: _onWebSocketClosed,
    );

    isConnected = true;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  void _onWebSocketMessage(String message) {
    try {
      var data = jsonDecode(message);
      if (data["type"] == "update") {
        gameState = {}..addAll(data["gameState"]);
        String? playerId = _wsHandler.socketId;
        if (playerId != null && gameState["players"] is List) {
          playerData = _getPlayerData(playerId);
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processant missatge WebSocket: $e");
      }
    }
  }

  dynamic _getPlayerData(String playerId) {
    return (gameState["players"] as List).firstWhere(
      (player) => player["id"] == playerId,
      orElse: () => {},
    );
  }

  Future<void> loadGameDataFromAssets() async {
    final String response =
        await rootBundle.loadString('assets/game_data.json');
    final data = jsonDecode(response);
    gameData = GameData.fromJson(data);
    notifyListeners();
  }

  Future<ui.Image> getImage(String assetName) async {
    if (!imagesCache.containsKey(assetName)) {
      final ByteData data = await rootBundle.load('assets/$assetName');
      final Uint8List bytes = data.buffer.asUint8List();
      imagesCache[assetName] = await decodeImage(bytes);
    }
    return imagesCache[assetName]!;
  }

  Future<ui.Image> decodeImage(Uint8List bytes) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }
}

class GameData {
  final String name;
  final List<Level> levels;

  GameData({required this.name, required this.levels});

  factory GameData.fromJson(Map<String, dynamic> json) {
    var levelsList = (json['levels'] as List)
        .map((levelJson) => Level.fromJson(levelJson))
        .toList();

    return GameData(name: json['name'], levels: levelsList);
  }
}

class Level {
  final String name;
  final String description;
  final List<Layer> layers;

  Level({required this.name, required this.description, required this.layers});

  factory Level.fromJson(Map<String, dynamic> json) {
    var layersList = (json['layers'] as List)
        .map((layerJson) => Layer.fromJson(layerJson))
        .toList();

    return Level(
      name: json['name'],
      description: json['description'],
      layers: layersList,
    );
  }
}

class Layer {
  final String name;
  final int x;
  final int y;
  final int depth;
  final String tilesSheetFile;
  final int tilesWidth;
  final int tilesHeight;
  final List<List<int>> tileMap;
  final bool visible;

  Layer({
    required this.name,
    required this.x,
    required this.y,
    required this.depth,
    required this.tilesSheetFile,
    required this.tilesWidth,
    required this.tilesHeight,
    required this.tileMap,
    required this.visible,
  });

  factory Layer.fromJson(Map<String, dynamic> json) {
    var tileMapList =
        (json['tileMap'] as List).map((row) => List<int>.from(row)).toList();

    return Layer(
      name: json['name'],
      x: json['x'],
      y: json['y'],
      depth: json['depth'],
      tilesSheetFile: json['tilesSheetFile'],
      tilesWidth: json['tilesWidth'],
      tilesHeight: json['tilesHeight'],
      tileMap: tileMapList,
      visible: json['visible'],
    );
  }
}
