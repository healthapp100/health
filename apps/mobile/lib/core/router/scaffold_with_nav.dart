import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/offline_banner.dart';
import '../widgets/responsive.dart';

/// The 5-destination nav shell (ARCHITECTURE.md §Navigation shell) — Home / Care / Learn / Track
/// / Profile. Lab Test Support is nested under Track's flow rather than a 6th destination,
/// keeping the nav at 5 items (BLUEPRINT.md §4.4: a flat nav doesn't scale past this).
///
/// Adaptive per Material 3's window-size-class guidance: a bottom `NavigationBar` on
/// compact/phone windows (thumb-reachable), a side `NavigationRail` on medium/expanded windows
/// (tablet/desktop) — a bottom bar stretched across a 1280px-wide desktop window is both an
/// unreachable-by-thumb pattern (irrelevant on desktop) and wastes the vertical space a side rail
/// uses instead.
class ScaffoldWithNav extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({super.key, required this.shell});

  static const _icons = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.medical_services_outlined, Icons.medical_services, 'Care'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
    (Icons.monitor_heart_outlined, Icons.monitor_heart, 'Track'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  void _onSelect(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact(context)) {
      return Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: shell),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          destinations: [
            for (final (icon, selectedIcon, label) in _icons)
              NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selectedIcon), label: label),
          ],
          onDestinationSelected: _onSelect,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _onSelect,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (icon, selectedIcon, label) in _icons)
                NavigationRailDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: Text(label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: shell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
