import 'package:flutter/material.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/pattern_occurrence.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_states.dart';
import 'package:gutgood/features/insights/presentation/widgets/occurrence_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AllPatternOccurrencesScreen extends StatefulWidget {
  const AllPatternOccurrencesScreen({super.key, required this.pattern});

  final BodyPattern pattern;

  @override
  State<AllPatternOccurrencesScreen> createState() => _AllPatternOccurrencesScreenState();
}

class _AllPatternOccurrencesScreenState extends State<AllPatternOccurrencesScreen> {
  String _selectedFilter = '30 Days';

  List<PatternOccurrence> get _filteredOccurrences {
    final now = DateTime.now();
    final sorted = [...widget.pattern.occurrences]..sort((a, b) => b.date.compareTo(a.date));
    final cutoff = switch (_selectedFilter) {
      '7 Days' => now.subtract(const Duration(days: 7)),
      '30 Days' => now.subtract(const Duration(days: 30)),
      _ => null,
    };
    if (cutoff == null) return sorted;
    return sorted.where((occurrence) {
      final parsed = DateTime.tryParse(occurrence.date);
      return parsed != null && !parsed.isBefore(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrences = _filteredOccurrences;
    final bg = context.v2Theme.scaffold;
    final textPrimary = context.insightColor(const Color(0xFF0F172A));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Pattern Occurrences',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pattern summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.insightColor(Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: context.insightColor(const Color(0xFFFEF2F2)), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          widget.pattern.domain.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFFDC2626))),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.pattern.frequency}× total',
                        style: TextStyle(fontSize: 12, color: context.insightColor(const Color(0xFF64748B)), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.pattern.trigger} → ${widget.pattern.reaction}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
            ),

            // Timeframe filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['7 Days', '30 Days', 'All Time'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: context.insightColor(const Color(0xFF0F172A)),
                      backgroundColor: context.insightColor(Colors.white),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : context.insightColor(const Color(0xFF64748B)), fontWeight: FontWeight.w600, fontSize: 12),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Occurrences list
            Expanded(
              child: occurrences.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: InsightEmptyStateCard(title: 'No occurrences in this period', message: 'Try a wider date range, or keep logging meals and symptoms to see whether a pattern repeats.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: occurrences.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final occ = occurrences[index];
                        return OccurrenceTile(occurrence: occ, pattern: widget.pattern);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
