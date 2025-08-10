import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/movies_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const JiePlayerApp());
}

class JiePlayerApp extends StatelessWidget {
  const JiePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JiePlayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'PingFang SC',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),   // 首页（已提取到 pages 目录）
    MoviesPage(), // 影片页
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: '影片',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}