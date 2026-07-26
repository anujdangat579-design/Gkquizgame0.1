import 'package:flutter/material.dart';

/// Shows a Yes/No confirmation dialog and returns true if the user
/// confirmed. Use for any destructive or hard-to-undo action
/// (delete, disable, sign out, etc.) instead of writing a new
/// AlertDialog each time.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
