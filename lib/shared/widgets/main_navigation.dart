import 'package:flutter/material.dart';
import '../../features/feed/presentation/screens/swipe_feed_screen.dart';
import '../../features/collections/presentation/screens/collections_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  
  final List<Widget> _screens = const [
    SwipeFeedScreen(),
    CollectionsScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    // If not on feed tab (index 0), navigate to feed tab
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Don't exit app
    }
    
    // If on feed tab, check for double back press
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      
      // Show toast message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      
      return false; // Don't exit app
    }
    
    return true; // Exit app on second back press within 2 seconds
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Ask AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }
}

