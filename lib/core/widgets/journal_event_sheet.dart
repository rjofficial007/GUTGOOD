import 'package:flutter/material.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';

/// Explicit user confirmation; the suggested time is never stored on dismissal.
Future<({DateTime occurredAt, String? mealId})?> showJournalEventSheet(BuildContext context, {required String title, DateTime? initialTime, List<MealLog> meals = const [], String? initialMealId}) {
  final now = DateTime.now();
  var selectedTime = (initialTime ?? now).toLocal();
  if (selectedTime.isAfter(now) || selectedTime.isBefore(DateTime(now.year - 1, now.month, now.day))) selectedTime = now;
  final choices = {
    for (final meal in meals)
      if ((meal.journalEntryId ?? meal.firestoreId) != null) (meal.journalEntryId ?? meal.firestoreId)!: meal,
  };
  var mealId = choices.containsKey(initialMealId) ? initialMealId : null;
  String? error;
  return showModalBottomSheet<({DateTime occurredAt, String? mealId})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(selectedTime)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedTime, firstDate: DateTime(now.year - 1, now.month, now.day), lastDate: now);
                if (date != null && context.mounted) setState(() => selectedTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute));
              },
            ),
            ListTile(
              title: const Text('Time'),
              subtitle: Text(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(selectedTime))),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedTime));
                if (time != null && context.mounted) setState(() => selectedTime = DateTime(selectedTime.year, selectedTime.month, selectedTime.day, time.hour, time.minute));
              },
            ),
            if (choices.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: mealId ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Related meal (optional)'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Match by confirmed time')),
                  for (final choice in choices.entries)
                    DropdownMenuItem(
                      value: choice.key,
                      child: Text(
                        '${choice.value.items.firstOrNull ?? "Meal"} · ${MaterialLocalizations.of(context).formatMediumDate(choice.value.eventTime.toLocal())} ${TimeOfDay.fromDateTime(choice.value.eventTime.toLocal()).format(context)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => mealId = value == '' ? null : value,
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (selectedTime.isAfter(DateTime.now())) {
                  setState(() => error = 'Choose a time that has already happened.');
                  return;
                }
                Navigator.pop(sheetContext, (occurredAt: selectedTime, mealId: mealId));
              },
              child: const Text('Confirm time'),
            ),
          ],
        ),
      ),
    ),
  );
}
