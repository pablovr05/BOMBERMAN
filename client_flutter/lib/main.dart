import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const App(),
    ),
  );
}
