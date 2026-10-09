import 'package:flutter/material.dart';
import 'package:genz_insights/genz_insights.dart';

void main() => runApp(const GenzInsightsExampleApp());

class GenzInsightsExampleApp extends StatelessWidget {
  const GenzInsightsExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (context) => GenzInsightsPage(
            onNavigationSelected: (index) {
              const sections = ['chat', 'insights', 'history', 'profile'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connect your ${sections[index]} screen here.')),
              );
            },
            onOpenRoute: (path) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Host app route: $path')),
              );
            },
          ),
        ),
      );
}
