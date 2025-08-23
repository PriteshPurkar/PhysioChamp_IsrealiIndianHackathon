import 'package:flutter/material.dart';
import 'package:physiochamp/pages/splash.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/insights.dart';
import 'pages/routine.dart';
import 'pages/progress.dart';
import 'pages/profile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhysioChamp',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    InsightsPage(
      sessionData: {
        "insight_1": "Great progress! Keep your balance steady.",
        "insight_2": "Focus on smoother heel-to-toe transitions.",
        "insight_3": "Try some balance drills daily."
      },
      sessionId: null,
      userId: "1",
      apiBase: "http://10.227.8.60:5000",
      aggregation: "p95",
    ),
    const RoutinePage(),
    const ProgressPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.teal,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
