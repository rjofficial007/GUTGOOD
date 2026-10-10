import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// Clearly separates optional AI synthesis from rule-calculated findings.
class InsightAiContextCard extends StatelessWidget {
  const InsightAiContextCard({super.key, required this.interpretation, required this.isLoading, required this.errorMessage, required this.onGenerate});

  final InsightAiInterpretation? interpretation;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final result = interpretation;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: theme.purple.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: theme.purple.withValues(alpha: 0.06), blurRadius: 14.w, offset: Offset(0, 5.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(color: theme.purplePastel.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(11.w)),
                alignment: Alignment.center,
                child: Icon(AppIcons.salad, size: 18.w, color: theme.purple),
              ),
              Gap.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GUTGOOD INTELLIGENCE',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: theme.purple, letterSpacing: 0.7),
                    ),

                    Text(
                      'How your logged patterns may connect',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          if (result != null) ...[
            Text(
              result.summary,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w500, color: theme.textPrimary, height: 1.42),
            ),
            Gap.h10,
            _disclosure(theme, 'A cautious summary of rule-detected observations. Associations are not proof of cause or a medical diagnosis.'),
          ] else ...[
            Text(
              'GutGood brings repeated associations from different areas together in a cautious, plain-language summary.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: theme.textSecondary, height: 1.4),
            ),
            Gap.h8,
            _disclosure(theme, 'This uses detected pattern summaries such as areas, food/context labels, timing, and counts—not raw chat, journal notes, or photos.'),
            if (errorMessage != null) ...[
              Gap.h8,
              Text(
                errorMessage!,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: theme.error, height: 1.35),
              ),
            ],
            Gap.h12,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onGenerate,
                icon: isLoading
                    ? SizedBox(
                        width: 15.w,
                        height: 15.w,
                        child: CircularProgressIndicator(strokeWidth: 2.w, color: theme.purple),
                      )
                    : Icon(Icons.auto_awesome_rounded, size: 16.w),
                label: Text(isLoading ? 'Preparing your summary…' : 'Show pattern connections'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.purple,
                  side: BorderSide(color: theme.purple.withValues(alpha: 0.42)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                  padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 14.w),
                  textStyle: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Gap.h6,
            Center(
              child: Text(
                'Optional · nothing is generated until you tap',
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w500, color: theme.textTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _disclosure(InsightTheme theme, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.shield_outlined, size: 13.w, color: theme.textTertiary),
      Gap.w6,
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w500, color: theme.textTertiary, height: 1.35),
        ),
      ),
    ],
  );
}
