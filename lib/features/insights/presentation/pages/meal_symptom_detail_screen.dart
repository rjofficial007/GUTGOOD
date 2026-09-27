import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MealSymptomDetailScreen extends StatelessWidget {
  const MealSymptomDetailScreen({super.key, required this.occurrence, this.pattern, this.swap});

  final PatternOccurrence occurrence;
  final BodyPattern? pattern;
  final FoodSwap? swap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = context.v2Theme.scaffold;
    final textPrimary = context.insightColor(const Color(0xFF0F172A));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Meal & Symptom Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.insightColor(Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.insightColor(const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(16),
                            image: occurrence.imageUrl != null && occurrence.imageUrl!.isNotEmpty ? DecorationImage(image: NetworkImage(occurrence.imageUrl!), fit: BoxFit.cover) : null,
                          ),
                          child: occurrence.imageUrl == null || occurrence.imageUrl!.isEmpty ? Icon(LucideIcons.utensils, color: context.insightColor(const Color(0xFF64748B)), size: 24) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${occurrence.dateLabel ?? occurrence.date} • ${occurrence.mealTime ?? "Logged meal"}',
                                style: TextStyle(fontSize: 12, color: context.insightColor(const Color(0xFF64748B)), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                occurrence.mealName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Matched Symptom Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.insightColor(const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.insightColor(const Color(0xFFFECACA))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.triangleAlert, color: context.insightColor(const Color(0xFFDC2626)), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'MATCHED SYMPTOM',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFFDC2626)), letterSpacing: 0.5),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: context.insightColor(Colors.white), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            occurrence.symptomSeverity ?? 'Observed',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFFDC2626))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      occurrence.reaction,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFF991B1B))),
                    ),
                    const SizedBox(height: 4),
                    Text('Observed ${occurrence.timeAfterLabel ?? occurrence.timeAfter} after eating', style: TextStyle(fontSize: 13, color: context.insightColor(const Color(0xFFB91C1C)))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Explanation / Pattern context
              if (pattern != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.insightColor(Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this happens',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pattern!.description.isNotEmpty ? pattern!.description : 'Fried and high-fat items can slow stomach emptying and trigger bloating.',
                        style: TextStyle(fontSize: 13, color: context.insightColor(const Color(0xFF475569)), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes if present
              if (occurrence.notes != null && occurrence.notes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.insightColor(Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your note',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFF64748B))),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${occurrence.notes}"',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: context.insightColor(const Color(0xFF1E293B))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Better Choice CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.insightColor(const Color(0xFF0F172A)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.repeat, size: 18),
                  label: const Text('Plan a Better Swap', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final defaultSwap =
                        swap ??
                        FoodSwap(
                          id: 'swap_default',
                          source: SwapSource(foodId: 'food_trigger', name: occurrence.mealName),
                          alternatives: const [SwapAlternative(foodId: 'food_alt_01', name: 'Grilled or Roasted Alternative', reason: 'Lower in added oils and easier to digest.')],
                        );
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: defaultSwap)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
