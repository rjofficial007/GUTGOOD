import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/constants/strings/chat_strings.dart';
import 'package:gutgood/core/constants/strings/common_strings.dart';
import 'package:gutgood/core/models/ai_report.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/widgets/gut_button.dart';

/// Shows the in-app AI response report sheet and returns the report the user
/// filed, or null if they dismissed it.
///
/// Google Play requires this to be reachable **without leaving the app** — it
/// must not hand the user off to email or a web form.
Future<AiReport?> showReportAiResponseSheet(
  BuildContext context, {
  required String messageText,
  String? messageId,
}) =>
    BottomSheetHelper.showGutSheet<AiReport>(
      context: context,
      child: _ReportAiResponseSheet(messageText: messageText, messageId: messageId),
    );

/// Maps an internal reason key to the label shown to the user.
const Map<String, String> _reasonLabels = {
  'inaccurate': ChatStrings.reasonInaccurate,
  'unsafe': ChatStrings.reasonUnsafe,
  'offensive': ChatStrings.reasonOffensive,
  'off_topic': ChatStrings.reasonOffTopic,
  'other': ChatStrings.reasonOther,
};

class _ReportAiResponseSheet extends StatefulWidget {
  const _ReportAiResponseSheet({required this.messageText, this.messageId});

  final String messageText;
  final String? messageId;

  @override
  State<_ReportAiResponseSheet> createState() => _ReportAiResponseSheetState();
}

class _ReportAiResponseSheetState extends State<_ReportAiResponseSheet> {
  String? _selectedReason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _selectedReason;
    if (reason == null) return;

    Navigator.of(context).pop(
      AiReport(
        reason: reason,
        messageExcerpt: AiReport.excerptOf(widget.messageText),
        details: _detailsController.text.trim(),
        messageId: widget.messageId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // Keep the sheet clear of the on-screen keyboard.
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.alertTriangle, size: 18, color: AppPalette.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  ChatStrings.reportResponseTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            ChatStrings.reportResponseSubtitle,
            style: TextStyle(fontSize: 13, height: 1.45, color: AppPalette.gray600),
          ),
          const SizedBox(height: 18),

          // Reason options — single select, so the report is always actionable.
          ...AiReport.allowedReasons.map((reason) => _ReasonOption(
                label: _reasonLabels[reason] ?? reason,
                isSelected: _selectedReason == reason,
                onTap: () => setState(() => _selectedReason = reason),
              )),

          const SizedBox(height: 14),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: ChatStrings.reportDetailsHint,
              hintStyle: const TextStyle(fontSize: 13, color: AppPalette.gray500),
              filled: true,
              fillColor: AppPalette.gray100,
              counterStyle: const TextStyle(fontSize: 10, color: AppPalette.gray500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: AppPalette.black),
          ),

          const SizedBox(height: 16),
          GutButton(
            label: ChatStrings.submitReport,
            onTap: _selectedReason == null ? null : _submit,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                CommonStrings.cancel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.gray600),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppPalette.orange.withValues(alpha: 0.10) : AppPalette.gray100,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  isSelected ? AppIcons.checkCircle : Icons.circle_outlined,
                  size: 19,
                  color: isSelected ? AppPalette.orange : AppPalette.gray500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppPalette.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
