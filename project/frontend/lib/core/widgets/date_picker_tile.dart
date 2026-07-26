import 'package:flutter/material.dart';

/// A ListTile-style row that shows a nullable date and lets the user pick
/// or clear it. Used in any form that collects a date field.
class DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String Function(DateTime date)? formatDate;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'Not set'
        : (formatDate?.call(value!) ?? '${value!.toLocal()}'.split(' ').first);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(display),
      trailing: Wrap(
        children: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            },
          ),
          if (value != null)
            IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => onChanged(null)),
        ],
      ),
    );
  }
}
