import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'add_post_screen.dart';
import 'user_list_screen.dart';
import 'notifications_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../models/notification_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  void _onItemTapped(int index) {
    if (index == 3) {
      _notificationService.markAllAsRead(_authService.currentUser?.uid ?? '');
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const FeedScreen(),
      UserListScreen(),
      const AddPostScreen(),
      NotificationsScreen(isActive: _selectedIndex == 3),
      ProfileScreen(uid: _authService.currentUser?.uid ?? ''),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCount(
                _authService.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                bool hasUnread = (snapshot.data ?? 0) > 0;
                return Stack(
                  children: [
                    const Icon(Icons.send_rounded),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getNotifications(
                _authService.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                bool hasUnread = false;
                if (snapshot.hasData) {
                  hasUnread = snapshot.data!.any((n) => !n.isRead);
                }
                return Stack(
                  children: [
                    const Icon(Icons.favorite_border),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
