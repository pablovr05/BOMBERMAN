import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'utils_websockets.dart';

class AppData extends ChangeNotifier {
  // Atributs per gestionar la connexió
  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  final String _wsServer = "localhost";
  final int _wsPort = 8888;
  bool isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 3);

  // Atributs per gestionar el joc
  Map<String, ui.Image> imagesCache = {};
  Map<String, dynamic> gameState = {};
  dynamic playerData;

  AppData() {
    _connectToWebSocket();
  }

  // Connectar amb el servidor (amb reintents si falla)
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

  // Tractar un missatge rebut des del servidor
  void _onWebSocketMessage(String message) {
    try {
      var data = jsonDecode(message);
      if (data["type"] == "update") {
        // Guardar les dades de l'estat de la partida
        gameState = {}..addAll(data["gameState"]);
        String? playerId = _wsHandler.socketId;
        if (playerId != null && gameState["players"] is List) {
          // Guardar les dades del propi jugador
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

  // Tractar els errors de connexió
  void _onWebSocketError(dynamic error) {
    if (kDebugMode) {
      print("Error de WebSocket: $error");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Tractar les desconnexions
  void _onWebSocketClosed() {
    if (kDebugMode) {
      print("WebSocket tancat. Intentant reconnectar...");
    }
    isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  // Programar una reconnexió (en cas que hagi fallat)
  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      if (kDebugMode) {
        print(
          "Intent de reconnexió #$_reconnectAttempts en ${_reconnectDelay.inSeconds} segons...",
        );
      }
      Future.delayed(_reconnectDelay, () {
        _connectToWebSocket();
      });
    } else {
      if (kDebugMode) {
        print(
          "No es pot reconnectar al servidor després de $_maxReconnectAttempts intents.",
        );
      }
    }
  }

  // Filtrar les dades del propi jugador (fent servir l'id de player)
  dynamic _getPlayerData(String playerId) {
    return (gameState["players"] as List).firstWhere(
      (player) => player["id"] == playerId,
      orElse: () => {},
    );
  }

  // Desconnectar-se del servidor
  void disconnect() {
    _wsHandler.disconnectFromServer();
    isConnected = false;
    notifyListeners();
  }

  // Enviar un missatge al servidor
  void sendMessage(String message) {
    if (isConnected) {
      _wsHandler.sendMessage(message);
    }
  }

  // Obté una imatge de 'assets' (si no la té ja en caché)
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
