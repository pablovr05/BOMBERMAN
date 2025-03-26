import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'app_data.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el tamaño de la ventana en escritorios (Windows, macOS, Linux)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: 'BOMBERMAN!',
      size: Size(735, 758), // Tamaño inicial de la ventana
      minimumSize: Size(735, 758), // Tamaño mínimo permitido
      maximumSize: Size(735, 758),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const App(),
    ),
  );
}
