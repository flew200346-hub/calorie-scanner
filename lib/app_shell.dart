import 'package:flutter/material.dart';

import 'home_page.dart';
import 'scan_page.dart';
import 'profile_view_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    ScanPage(),
    ProfileViewPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _pages[_index],

      // ✅ ทำให้บาร์โทนเดียวกับแอป (สวยขึ้นและสม่ำเสมอ)
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -8),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 70,
            backgroundColor: Colors.white,
            indicatorColor: cs.primary.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
