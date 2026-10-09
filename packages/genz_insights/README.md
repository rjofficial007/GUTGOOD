# GenZ Insights — portable Flutter package

This folder is a self-contained copy of the GenZ Insights UI, its demo/detail screens, reusable widgets, and the image assets those screens need. It has no GutGood app imports and does not require `go_router`.

## Add it to another Flutter app

Copy this entire `genz_insights` folder into the other project, for example under `packages/genz_insights`, then add the local path dependency to that project's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  genz_insights:
    path: packages/genz_insights
```

Then run `flutter pub get`. To get the complete screen with the standard four-item bottom navigation, use `GenzInsightsPage`:

```dart
import 'package:flutter/material.dart';
import 'package:genz_insights/genz_insights.dart';

MaterialApp(
  theme: ThemeData(brightness: Brightness.dark),
  home: GenzInsightsPage(
    onNavigationSelected: (index) {
      // Connect index 0=chat, 1=insights, 2=history, 3=profile.
    },
  ),
);
```

If your app already provides the bottom navigation shell, use `InsightGenzScreen` instead. Both widgets read the host app's theme brightness. `GenzInsightsPage` applies light mode locally unless you provide `onLightModeChanged`; when using `InsightGenzScreen` directly, pass that callback to connect its settings-sheet light-mode switch to the host theme. Long-press the screen title to switch between the bundled `full`, `early`, and `learn` demo states, or use the settings button to select `with data`, `just started`, or `not enough data`; pass `initialState` to choose the initial state.

## Host-app navigation

The package handles its sample detail pages internally. For story actions that belong to the host app, pass `onOpenRoute`; the callback receives the route string and can be adapted to any router (GoRouter, Navigator, or a custom solution):

```dart
Builder(
  builder: (context) => InsightGenzScreen(
    onOpenRoute: (path) => context.go(path), // if the host app uses GoRouter
  ),
)
```

The package itself has no GoRouter dependency. Bundled route strings include `/smart-insight-detail`, `/food-intelligence`, `/insight-history`, `/pattern-detail`, and `/swap-detail`. Map them to your app's routes as needed. Demo-only actions such as meal scanning show an in-screen toast until connected to a real feature.

## Included

- `lib/` — screen, tabs, detail views, story viewer, styles, and widgets.
- `assets/images/` — the 15 WebP illustrations used by the screen.
- `example/` — a small host-app sample.

Images are declared and loaded as package assets, so you do not need to copy them into the host app's `assets/` folder or add a second asset declaration.

## Requirements

- Flutter `>=3.27.0`
- Dart `>=3.11.0`
- `lucide_icons_flutter` is installed automatically as a package dependency.
