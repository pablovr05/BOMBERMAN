import 'dart:io'; // Para verificar la plataforma
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart'; // Asegúrate de importar esto
import 'app_data.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verifica si la plataforma es de escritorio
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Configura el tamaño de la ventana
    setWindowTitle('Mi Aplicación Flutter');
    setWindowMinSize(const Size(600, 400)); // Tamaño mínimo de la ventana
    setWindowMaxSize(const Size(800, 600)); // Tamaño máximo de la ventana
    setWindowSize(const Size(800, 600)); // Tamaño inicial de la ventana
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const App(),
    ),
  );
}
