import 'package:attendx/features/attendance/screens/attendance_screen.dart';
import 'package:attendx/features/history/screens/history_screen.dart';
import 'package:attendx/features/home/screens/home_screen.dart';
import 'package:attendx/features/profile/screens/profile_screen.dart';
import 'package:attendx/features/timetable/screens/timetable_screen.dart';
import 'package:flutter/material.dart';

/// Hosts the five main tabs behind a single persistent bottom navigation
/// bar. [initialIndex] lets top-level routes (`/home`, `/attendance`, ...)
/// deep-link straight into a specific tab.
class RootShell extends StatefulWidget {
  final int initialIndex;
  const RootShell({super.key, this.initialIndex = 0});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;

  static const _screens = [
    HomeScreen(),
    AttendanceScreen(),
    TimetableScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.fact_check_rounded, label: 'Attendance'),
    (icon: Icons.calendar_month_rounded, label: 'Timetable'),
    (icon: Icons.history_rounded, label: 'History'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final item in _items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
