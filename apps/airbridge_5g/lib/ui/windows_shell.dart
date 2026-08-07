import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import '../providers/role_provider.dart';

class WindowsShell extends StatelessWidget {
  final Widget child;

  const WindowsShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/master')) currentIndex = 1;
    else if (location.startsWith('/client')) currentIndex = 2;
    else if (location.startsWith('/settings')) currentIndex = 3;

    final theme = FluentTheme.of(context);

    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('AirBridge 5G'),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        selected: currentIndex,
        onChanged: (index) {
          switch (index) {
            case 0: context.go('/'); break;
            case 1: context.go('/master'); break;
            case 2: context.go('/client'); break;
            case 3: context.go('/settings'); break;
          }
        },
        displayMode: PaneDisplayMode.auto,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Home'),
            body: currentIndex == 0 ? _acrylicWrapper(context, child, theme) : const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.server),
            title: const Text('Master Dashboard'),
            body: currentIndex == 1 ? _acrylicWrapper(context, child, theme) : const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.cell_phone),
            title: const Text('Client Dashboard'),
            body: currentIndex == 2 ? _acrylicWrapper(context, child, theme) : const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: currentIndex == 3 ? _acrylicWrapper(context, child, theme) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _acrylicWrapper(BuildContext context, Widget child, FluentThemeData theme) {
    return Container(
      color: theme.acrylicBackgroundColor,
      child: child,
    );
  }
}
