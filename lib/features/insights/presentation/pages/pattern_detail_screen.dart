import 'package:flutter/material.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';

/// Overhauled Pattern anatomy screen (matches patterns.html rich UI).
class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(pattern.type);
    final textAccent = _getTextAccent(pattern.type);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: const [0.0, 0.2, 0.4, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            GutSliverAppBar(
              title: '${pattern.type} pattern'.toUpperCase(),
              centerTitle: true,
              showBrandingIcon: false,
              backgroundColor: Colors.transparent,
              foregroundColor: textAccent,
            ),
            InsightBentoPattern(pattern: pattern),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String type) => switch (type) {
        BodyPattern.typeBloating => const [Color(0xFFBEA4FA), Color(0xFFD8C8FC), Color(0xFFF5F6F8), Colors.white],
        BodyPattern.typeEnergy => const [Color(0xFFA1D891), Color(0xFFC6E7BC), Color(0xFFF5F6F8), Colors.white],
        BodyPattern.typeHeadache => const [Color(0xFFF7B87E), Color(0xFFFAD4B1), Color(0xFFF5F6F8), Colors.white],
        BodyPattern.typeDigestion => const [Color(0xFF7BCBC0), Color(0xFFAFE0D9), Color(0xFFF5F6F8), Colors.white],
        BodyPattern.typeFullness => const [Color(0xFFF6D375), Color(0xFFFAE4AB), Color(0xFFF5F6F8), Colors.white],
        BodyPattern.typeSleep => const [Color(0xFFACB1F2), Color(0xFFCDD0F7), Color(0xFFF5F6F8), Colors.white],
        _ => const [Color(0xFFBEA4FA), Color(0xFFD8C8FC), Color(0xFFF5F6F8), Colors.white],
      };

  Color _getTextAccent(String type) => switch (type) {
        BodyPattern.typeBloating => const Color(0xFF563999),
        BodyPattern.typeEnergy => const Color(0xFF367325),
        BodyPattern.typeHeadache => const Color(0xFF954F10),
        BodyPattern.typeDigestion => const Color(0xFF0C6559),
        BodyPattern.typeFullness => const Color(0xFF946D05),
        BodyPattern.typeSleep => const Color(0xFF424890),
        _ => const Color(0xFF563999),
      };
}
