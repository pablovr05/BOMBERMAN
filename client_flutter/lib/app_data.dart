import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:exemple_ws/game_data.dart';
import 'package:flutter/foundation.dart';
import 'utils_websockets.dart';

class AppData extends ChangeNotifier {
  // Atributs per gestionar la connexió
  final WebSocketsHandler _wsHandler = WebSocketsHandler();
  final String _wsServer = "bandera3.ieti.site";
  final int _wsPort = 8888;
  bool isConnected = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = Duration(seconds: 3);

  // Atributs per gestionar el joc
  Map<String, ui.Image> imagesCache = {};
  Map<String, dynamic> gameState = {};
  dynamic playerData;
  dynamic mapData;

  // Diccionario para almacenar la última dirección de cada jugador
  Map<String, String> playerDirections = {};

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

  void _onWebSocketMessage(String message) {
    try {
      var data = jsonDecode(message);

      if (data["type"] == "update") {
        // Guardar las datos de estado del juego
        gameState = {}..addAll(data["gameState"]);
        String? playerId = _wsHandler.socketId;
        if (playerId != null && gameState["players"] is List) {
          // Guardar las datos del propio jugador
          playerData = _getPlayerData(playerId);
          mapData = _getMapData();
        }
        notifyListeners();
      } else if (data["type"] == "playerDirection") {
        // Actualizar las direcciones del jugador solo si cambia
        String playerId = data["playerId"];
        String direction = data["direction"];

        if (playerData != null && playerData["id"] == playerId) {
          // No actualizamos si la dirección es 'none'
          if (direction != "none") {
            // Actualizamos la dirección en el diccionario de direcciones
            playerDirections[playerId] = direction;

            // Si la dirección es null o vacía, inicializarla como una lista
            if (playerData["directions"] == null) {
              playerData["directions"] = [];
            }

            // Agregar la nueva dirección siempre que no sea "none"
            playerData["directions"].add(direction);
          }
          notifyListeners();
        }
      } else if (data["type"] == "explosionHit") {
        String playerId = data["playerId"];
        // Actualiza el estado del jugador si es este quien ha sido alcanzado
        if (playerData != null && playerData["id"] == playerId) {
          playerData["isDead"] = true; // Marca al jugador como perdido
          notifyListeners(); // Notifica a la UI que el jugador ha perdido
        }

        print("¡Jugador $playerId ha sido alcanzado por una explosión!");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error procesando mensaje WebSocket: $e");
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
    var player = (gameState["players"] as List).firstWhere(
      (player) => player["id"] == playerId,
      orElse: () => {},
    );

    if (player.isNotEmpty) {
      // Si ya tenemos playerData anterior, las conservamos
      if (playerData != null &&
          playerData["id"] == playerId &&
          playerData["directions"] != null) {
        player["directions"] = List.from(playerData["directions"]);
      } else {
        player["directions"] = [];
      }
    }

    return player;
  }

  // Asumiendo que tienes un archivo JSON o alguna fuente de datos para GameData
  dynamic _getMapData() {
    if (gameState["map"] == null) {
      if (kDebugMode) {
        print("gameState['map'] es nulo.");
      }
      return {}; // Retorna un mapa vacío si es nulo
    } else if (gameState["map"] is Map) {
      return GameData.fromJson(gameState["map"]);
    } else {
      if (kDebugMode) {
        print("gameState['map'] no es un mapa válido.");
      }
      return {}; // Retorna un mapa vacío si no es válido
    }
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
}
