import 'package:flutter/material.dart';

import '../notes_controller.dart';
import 'calendar_tab.dart';
import 'notes_tab.dart';
import 'upcoming_tab.dart';

/// The app's main screen: three tabs behind a bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final NotesController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          NotesTab(controller: controller, onShowUpcoming: () => setState(() => _tab = 2)),
          CalendarTab(controller: controller),
          UpcomingTab(controller: controller),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final attention = controller.attentionCount(now: DateTime.now());
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.sticky_note_2_outlined),
                selectedIcon: Icon(Icons.sticky_note_2),
                label: 'Notlar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Takvim',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: attention > 0,
                  label: Text('$attention'),
                  child: const Icon(Icons.notifications_none),
                ),
                selectedIcon: Badge(
                  isLabelVisible: attention > 0,
                  label: Text('$attention'),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Yaklaşanlar',
              ),
            ],
          );
        },
      ),
    );
  }
}
