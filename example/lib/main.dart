import 'package:flutter/material.dart';
import 'package:linphone_plugin_example/storage.dart';

import 'lin_phone_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter linphone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LinPhonePage(title: 'Flutter linphone'),
    );
  }
}
