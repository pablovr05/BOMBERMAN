import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'canvas_painter.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  final FocusNode _focusNode = FocusNode();
  final Set<String> _pressedKeys = {};
  late Map<String, ui.Image> imagesCache = {};

  // Load the images from the assets
  Future<void> _loadImages() async {
    imagesCache['grass.png'] = await _loadImage('assets/grass.png');
    imagesCache['wall.png'] = await _loadImage('assets/wall.png');
    imagesCache['dynmamite_pack.png'] =
        await _loadImage('assets/dynmamite_pack.png');
    imagesCache['explosion.png'] = await _loadImage('assets/explosion.png');
  }

  // Helper function to load images from assets
  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return await decodeImageFromList(bytes);
  }

  void _onKeyEvent(KeyEvent event, AppData appData) {
    String key = event.logicalKey.keyLabel.toLowerCase();

    // Detectar teclas específicas manualmente
    if (event.logicalKey == LogicalKeyboardKey.space) {
      key = "space";
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      key = "up";
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      key = "down";
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      key = "left";
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      key = "right";
    }

    if (event is KeyDownEvent) {
      _pressedKeys.add(key);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }

    // Enviar la dirección y espacio al servidor
    String direction = _getDirectionFromKeys();
    bool isSpace = _getSpaceFromKeys();
    print("Dirección: $direction, Espacio: $isSpace");

    appData.sendMessage(jsonEncode(
        {"type": "direction", "value": direction, "isSpace": isSpace}));
  }

  bool _getSpaceFromKeys() {
    return _pressedKeys.contains("space");
  }

  String _getDirectionFromKeys() {
    bool up = _pressedKeys.contains("up");
    bool down = _pressedKeys.contains("down");
    bool left = _pressedKeys.contains("left");
    bool right = _pressedKeys.contains("right");

    List<String> directions = [];
    if (up) directions.add("up");
    if (down) directions.add("down");
    if (left) directions.add("left");
    if (right) directions.add("right");

    return directions.isNotEmpty ? directions.join("-") : "none";
  }

  @override
  void initState() {
    super.initState();
    _loadImages(); // Load the images asynchronously
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Container(
          color: CupertinoColors.systemGrey5,
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (KeyEvent event) {
              _onKeyEvent(event, appData);
            },
            child: imagesCache.isEmpty
                ? Center(
                    child:
                        CupertinoActivityIndicator()) // Show loading spinner while images are loading
                : CustomPaint(
                    painter: CanvasPainter(
                        appData, imagesCache), // Pass imagesCache here
                    child: Container(),
                  ),
          ),
        ),
      ),
    );
  }
}
