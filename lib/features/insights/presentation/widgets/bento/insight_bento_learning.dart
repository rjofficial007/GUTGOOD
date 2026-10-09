part of 'insight_bento_feed.dart';

/// Learning-state bento presentation components.

class InsightBentoLearning extends StatelessWidget {
  const InsightBentoLearning({super.key, required this.meals, required this.symptoms, required this.scans});

  final int meals;
  final int symptoms;
  final int scans;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    const maxFoodScans = 3;
    const maxSymptoms = 1;

    final totalFood = scans + meals;
    final currentFoodScans = totalFood.clamp(0, maxFoodScans);
    final currentSymptoms = symptoms.clamp(0, maxSymptoms);

    final foodDone = currentFoodScans >= maxFoodScans;
    final symptomsDone = currentSymptoms >= maxSymptoms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Centered Display Title (Matching Chat Empty State UI/UX)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Your food.\nYour symptoms.\nYour insights.',
            style: context.displayMd.copyWith(height: 1.2, letterSpacing: -0.5),
            textAlign: TextAlign.center,
            softWrap: false,
          ),
        ),
        Gap.h16,

        // Subtitle Paragraph
        Text(
          'Scan 3 food meals and log 1 symptom to build your baseline and unlock your insights.',
          style: context.bodyLg.copyWith(color: scheme.textSecondary, height: 1.35),
          textAlign: TextAlign.center,
        ),
        Gap.h24,

        // 3-Grid Action Cards (Matching Chat Empty State Grid Layout)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.p8,
          mainAxisSpacing: AppSizes.p8,
          childAspectRatio: 1.4,
          children: [
            _LearningCard(
              icon: AppIcons.scan,
              title: 'Scan food',
              current: currentFoodScans,
              total: maxFoodScans,
              isDone: foodDone,
              accentColor: scheme.textPrimary,
              onTap: () => openScannerAndProcessResult(context, 'meal'),
            ),
            _LearningCard(
              icon: AppIcons.heart,
              title: 'Track symptoms',
              current: currentSymptoms,
              total: maxSymptoms,
              isDone: symptomsDone,
              accentColor: scheme.textPrimary,
              onTap: () => context.push(AppRoutes.scannerPath('symptom')),
            ),
          ],
        ),
        Gap.h20,

        // Bottom Guidance Box (Matching Chat Component Container Style)
        Container(
          padding: EdgeInsets.all(AppSizes.p14),
          decoration: BoxDecoration(
            color: scheme.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.r20),
            border: Border.all(color: scheme.borderSubtle),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.lightbulb, size: 14.w, color: scheme.textPrimary),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Understanding Your Body', style: context.bodyBold.copyWith(fontSize: 12.sp)),
                    Gap.h2,
                    Text(
                      'Your food logs are analyzed alongside symptoms to calculate your Gut Score and uncover tailored health patterns.',
                      style: context.caption.copyWith(color: scheme.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
