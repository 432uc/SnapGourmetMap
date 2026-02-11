import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'screens/map_screen.dart';
import 'screens/camera_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final QuickActions quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_take_photo',
        localizedTitle: '写真を撮る',
        icon: 'ic_camera', // ネイティブ側でアイコンアセットがない場合はデフォルトアイコンになります
      ),
    ]);

    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_take_photo') {
        // カメラ画面へ直接遷移
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap GourmetLog',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
