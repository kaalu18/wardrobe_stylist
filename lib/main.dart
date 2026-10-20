import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'services/update_worker.dart';
import 'screens/home_screen.dart';
import 'screens/suggest_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('wardrobe');
  await Hive.openBox('settings');

  // Daily background refresh - deliberately network-free (offline-first).
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    'daily-outfit',
    'daily-outfit',
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.not_required),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(const WardrobeApp());
}

class WardrobeApp extends StatelessWidget {
  const WardrobeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Wardrobe Stylist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        home: const MainShell(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: const [HomeScreen(), SuggestScreen()][_tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checkroom), label: 'Wardrobe'),
            NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Style me'),
          ],
        ),
      );
}