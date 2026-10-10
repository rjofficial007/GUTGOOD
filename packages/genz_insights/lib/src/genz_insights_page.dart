import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/insight_genz_screen.dart';
import 'package:genz_insights/src/states/genz_state_views.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Full-screen integration with a standard four-item bottom navigation bar.
///
/// Use [InsightGenzScreen] instead when the host app already supplies its own
/// navigation shell. When no theme callback is provided, this wrapper handles
/// the light-mode setting locally for standalone use.
class GenzInsightsPage extends StatefulWidget {
  const GenzInsightsPage({super.key, required this.onNavigationSelected, this.initialState = GenzDataState.full, this.onOpenRoute, this.onLightModeChanged});

  /// Called with 0 = chat, 1 = insights, 2 = history, and 3 = profile.
  final ValueChanged<int> onNavigationSelected;
  final GenzDataState initialState;
  final ValueChanged<String>? onOpenRoute;

  /// Optional host-owned theme handler. Without it, light mode is applied locally.
  final ValueChanged<bool>? onLightModeChanged;

  @override
  State<GenzInsightsPage> createState() => _GenzInsightsPageState();
}

class _GenzInsightsPageState extends State<GenzInsightsPage> {
  bool? _localLightMode;

  void _handleLightModeChanged(bool isLightMode) {
    final callback = widget.onLightModeChanged;
    if (callback != null) {
      callback(isLightMode);
      return;
    }
    setState(() => _localLightMode = isLightMode);
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final brightness = _localLightMode == null ? parentTheme.brightness : (_localLightMode! ? Brightness.light : Brightness.dark);
    final theme = parentTheme.copyWith(
      brightness: brightness,
      colorScheme: parentTheme.colorScheme.copyWith(brightness: brightness),
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0B0B12) : const Color(0xFFF3F1EC),
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (themeContext) => Scaffold(
          backgroundColor: GenzColors.scaffoldBg(themeContext),
          body: InsightGenzScreen(initialState: widget.initialState, onOpenRoute: widget.onOpenRoute, onLightModeChanged: _handleLightModeChanged),
          bottomNavigationBar: _StandardBottomNavigation(onSelect: widget.onNavigationSelected),
        ),
      ),
    );
  }
}

class _StandardBottomNavigation extends StatelessWidget {
  const _StandardBottomNavigation({required this.onSelect});

  final ValueChanged<int> onSelect;

  static const _items = <({IconData icon, String label})>[
    (icon: LucideIcons.messageCircle, label: 'chat'),
    (icon: LucideIcons.barChart, label: 'insights'),
    (icon: LucideIcons.history, label: 'history'),
    (icon: LucideIcons.user, label: 'profile'),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GenzColors.sf(context),
      border: Border(top: BorderSide(color: GenzColors.ln(context), width: 0.5)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [for (var index = 0; index < _items.length; index++) _buildItem(context, index, _items[index])]),
      ),
    ),
  );

  Widget _buildItem(BuildContext context, int index, ({IconData icon, String label}) item) {
    const selectedIndex = 1;
    final active = index == selectedIndex;
    final color = active ? (GenzColors.isDark(context) ? Colors.white : GenzColors.ink) : GenzColors.mu(context);

    return Expanded(
      child: Semantics(
        button: true,
        label: item.label,
        selected: active,
        child: InkWell(
          onTap: () => onSelect(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(color: color, fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
