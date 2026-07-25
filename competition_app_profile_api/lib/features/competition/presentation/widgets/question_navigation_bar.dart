import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Forward-only navigation controls for a single question in a
/// real-time, server-authoritative quiz match.
///
/// Deliberately asymmetric: `Previous` is rendered but permanently
/// disabled (`onPressed: null`) rather than omitted, so the UI makes the
/// "no revisiting" rule visible instead of leaving it ambiguous. There is
/// no way to reach a previous question from this widget or otherwise —
/// once the opponent-synced timer for a question elapses or an answer is
/// submitted, that question is final on the server, so allowing local
/// back-navigation would just desync the client from match state.
///
/// `Next`/`Submit` only enables once an option is selected and the
/// question isn't already locked; the caller is expected to also
/// auto-advance on timeout, independent of this widget ever being tapped
/// (see `QuizPage._handleAutoSubmit`).
///
/// Standalone and reusable: takes plain flags/callbacks, not coupled to
/// `QuizPage`'s internal state.
class QuestionNavigationBar extends StatelessWidget {
  final bool isLastQuestion;
  final bool canSubmit;
  final VoidCallback onNext;

  const QuestionNavigationBar({
    super.key,
    required this.isLastQuestion,
    required this.canSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              // Always disabled: revisiting a prior question isn't
              // possible in a server-authoritative real-time match.
              onPressed: null,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: canSubmit ? onNext : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text(isLastQuestion ? 'Submit' : 'Next question'),
            ),
          ),
        ),
      ],
    );
  }
}
