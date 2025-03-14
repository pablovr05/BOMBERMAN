import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, disconnecting, connecting, connected }

class WebSocketsHandler {
  late Function _callback;
  String ip = "localhost";
  String port = "8888";
  String? socketId;

  WebSocketChannel? _socketClient;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;

  void connectToServer(
    String serverIp,
    int serverPort,
    void Function(String message) callback, {
    void Function(dynamic error)? onError,
    void Function()? onDone,
  }) async {
    _callback = callback;
    ip = serverIp;
    port = serverPort.toString();

    connectionStatus = ConnectionStatus.connecting;

    try {
      _socketClient = WebSocketChannel.connect(Uri.parse("ws://$ip:$port"));
      connectionStatus = ConnectionStatus.connected;

      _socketClient!.stream.listen(
        (message) {
          _handleMessage(message);
          _callback(message);
        },
        onError: (error) {
          connectionStatus = ConnectionStatus.disconnected;
          onError?.call(error);
        },
        onDone: () {
          connectionStatus = ConnectionStatus.disconnected;
          onDone?.call();
        },
      );
    } catch (e) {
      connectionStatus = ConnectionStatus.disconnected;
      onError?.call(e);
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> &&
          data.containsKey("type") &&
          data["type"] == "welcome" &&
          data.containsKey("id")) {
        socketId = data["id"];
        if (kDebugMode) {
          print("Client ID assignat pel servidor: $socketId");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processant missatge WebSocket: $e");
      }
    }
  }

  void sendMessage(String message) {
    if (connectionStatus == ConnectionStatus.connected) {
      _socketClient!.sink.add(message);
    }
  }

  void disconnectFromServer() {
    connectionStatus = ConnectionStatus.disconnecting;
    _socketClient?.sink.close();
    connectionStatus = ConnectionStatus.disconnected;
  }
}
