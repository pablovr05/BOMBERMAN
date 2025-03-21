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
    imagesCache['walls.png'] = await _loadImage('assets/walls.png');
  }

  // Helper function to load images from assets
  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return await decodeImageFromList(bytes);
  }

  // Tractar què passa quan el jugador apreta una tecla
  void _onKeyEvent(KeyEvent event, AppData appData) {
    String key = event.logicalKey.keyLabel.toLowerCase();

    if (key.contains(" ")) {
      key = key.split(" ")[1];
    } else {
      return;
    }

    if (event is KeyDownEvent) {
      _pressedKeys.add(key);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(key);
    }

    // Enviar la direcció escollida pel jugador al servidor
    var direction = _getDirectionFromKeys();
    appData.sendMessage(jsonEncode({"type": "direction", "value": direction}));
  }

  String _getDirectionFromKeys() {
    bool up = _pressedKeys.contains("up");
    bool down = _pressedKeys.contains("down");
    bool left = _pressedKeys.contains("left");
    bool right = _pressedKeys.contains("right");

    if (up) return "up";
    if (down) return "down";
    if (left) return "left";
    if (right) return "right";

    return "none";
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
