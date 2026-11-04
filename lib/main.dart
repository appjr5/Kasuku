import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio.dart';
import 'brain.dart';
import 'screens/home.dart';
import 'store.dart';
import 'tips.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final st = AppState();
  await st.load();
  final voice = Voice();
  await voice.init();
  final tips = TipService(await TipBank.load(), NullBrain()); // Phase 2 swaps NullBrain for the on-device Gemma brain
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: st),
      Provider.value(value: voice),
      Provider.value(value: tips),
      Provider<Ear>(create: (_) => Ear(), dispose: (_, e) => e.dispose()),
    ],
    child: const LughaApp(),
  ));
}

class LughaApp extends StatelessWidget {
  const LughaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kasuku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C4DFF), scaffoldBackgroundColor: const Color(0xFFF8F6FF)),
        home: const HomeScreen(),
      );
}
