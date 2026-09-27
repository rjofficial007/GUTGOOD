import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ActionDetailScreen extends StatefulWidget {
  const ActionDetailScreen({super.key, required this.action});

  final InsightAction action;

  @override
  State<ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.action.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = widget.action;
    final bg = context.v2Theme.scaffold;
    final textPrimary = context.insightColor(const Color(0xFF0F172A));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Recommended Step',
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
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: context.insightColor(const Color(0xFFF0FDF4)), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  action.category.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFF16A34A)), letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                action.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),

              Text(action.description, style: TextStyle(fontSize: 14, color: context.insightColor(const Color(0xFF475569)), height: 1.4)),

              const SizedBox(height: 24),

              // Details Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.insightColor(Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    if (action.whenToDo != null) _DetailRow(icon: LucideIcons.clock, label: 'When to do', value: action.whenToDo!),
                    if (action.expectedBenefit != null) ...[
                      Divider(height: 24, color: context.insightColor(const Color(0xFFE2E8F0))),
                      _DetailRow(icon: LucideIcons.sparkles, label: 'Expected benefit', value: action.expectedBenefit!),
                    ],
                    Divider(height: 24, color: context.insightColor(const Color(0xFFE2E8F0))),
                    _DetailRow(icon: LucideIcons.zap, label: 'Impact & Difficulty', value: '${action.impactLevel.toUpperCase()} Impact • ${action.difficulty}'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action status buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _status == 'in_progress' || _status == 'completed' ? const Color(0xFF16A34A) : context.insightColor(const Color(0xFF0F172A)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(_status == 'completed' ? LucideIcons.check : LucideIcons.play, size: 18),
                  label: Text(
                    _status == 'completed'
                        ? 'Completed'
                        : _status == 'in_progress'
                        ? 'Test in Progress'
                        : 'Start 7-Day Gut Test',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (_status != 'in_progress' && _status != 'completed') {
                      context.read<InsightsNotifier>().startExperiment(widget.action, targetDays: 7);
                      setState(() {
                        _status = 'in_progress';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 7-Day Gut Test started! Track your daily progress on the Insights tab.'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    } else if (_status == 'in_progress') {
                      context.read<InsightsNotifier>().completeActiveExperiment();
                      setState(() {
                        _status = 'completed';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test marked as completed!'), behavior: SnackBarBehavior.floating));
                    }
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: context.insightColor(const Color(0xFF64748B))),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.insightColor(const Color(0xFF64748B)), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.insightColor(const Color(0xFF0F172A))),
            ),
          ],
        ),
      ),
    ],
  );
}
