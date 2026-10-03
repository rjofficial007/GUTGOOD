part of 'bento_widgets.dart';

/// The 6px score track with its orange→gold→mint fill (`.score-track-bar`).
class ScoreTrack extends StatelessWidget {
  const ScoreTrack({super.key, required this.progress, this.colors});

  final double progress;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final ramp = colors ?? [t.scoreTrackStart, t.scoreTrackMid, t.scoreTrackEnd];
    final stops = ramp.length == 3 ? const [0.0, 0.5, 1.0] : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: BentoMetrics.trackHeight.w,
        decoration: BoxDecoration(color: t.textPrimary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(99)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: ramp, stops: stops),
            ),
          ),
        ),
      ),
    );
  }
}
