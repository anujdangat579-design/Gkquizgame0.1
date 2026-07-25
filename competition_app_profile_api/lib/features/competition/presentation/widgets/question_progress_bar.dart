import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Segmented (per-question) progress bar rather than one smooth line —
/// in a fixed-question-count quiz, showing each question as its own
/// filled/unfilled segment communicates "3 of 10 done" at a glance more
/// precisely than a continuous bar would.
///
/// Standalone and reusable: used below the header row in `QuizPage`, but
/// takes plain `current`/`total` rather than anything quiz-specific, so
/// it's equally suited to any other fixed-step flow (e.g. a multi-step
/// onboarding or KYC form) once one needs the same "N filled segments
/// out of a known total" language.
///
/// UI only: purely presentational — driven by whatever index the caller
/// tracks (see `QuizPage`'s own `_questionIndex`), not by any state of
/// its own.
class QuestionProgressBar extends StatelessWidget {
  final int total;
  final int current;
  final double height;
  final double gap;

  const QuestionProgressBar({
    super.key,
    required this.total,
    required this.current,
    this.height = 6,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: height,
                decoration: BoxDecoration(
                  color: i <= current ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            if (i != total - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }
}
