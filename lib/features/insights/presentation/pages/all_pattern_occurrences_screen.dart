import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/pages/meal_symptom_detail_screen.dart';
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
    if (_selectedFilter == '7 Days') {
      return widget.pattern.occurrences.take(3).toList();
    }
    return widget.pattern.occurrences;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrences = _filteredOccurrences;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        title: Text(
          'Pattern Occurrences',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          widget.pattern.domain.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.pattern.frequency}× total',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.pattern.trigger} → ${widget.pattern.reaction}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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
                      selectedColor: const Color(0xFF0F172A),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
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
                  ? Center(
                      child: Text('No occurrences logged for this period.', style: TextStyle(color: Colors.grey[600])),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: occurrences.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final occ = occurrences[index];
                        return _OccurrenceTile(occurrence: occ, pattern: widget.pattern);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occurrence, required this.pattern});

  final PatternOccurrence occurrence;
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MealSymptomDetailScreen(occurrence: occurrence, pattern: pattern),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                image: occurrence.imageUrl != null && occurrence.imageUrl!.isNotEmpty ? DecorationImage(image: NetworkImage(occurrence.imageUrl!), fit: BoxFit.cover) : null,
              ),
              child: occurrence.imageUrl == null || occurrence.imageUrl!.isEmpty ? const Icon(LucideIcons.utensils, color: Color(0xFF64748B), size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Text(
                        occurrence.dateLabel ?? occurrence.date,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      if (occurrence.mealTime != null) ...[
                        const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                        Text(occurrence.mealTime!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    occurrence.mealName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text('Reaction: ${occurrence.reaction} (${occurrence.timeAfter})', style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}
