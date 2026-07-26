import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/server_clock.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/question.dart';
import '../providers/quiz_notifier.dart';
import '../providers/quiz_state.dart';
import '../widgets/answer_option_card.dart';
import '../widgets/circular_timer.dart';
import '../widgets/question_card.dart';
import '../widgets/question_navigation_bar.dart';
import '../widgets/question_progress_bar.dart';
import '../widgets/quiz_completed_view.dart';
import 'opponent_found_page.dart' show QueuePlayer;
import 'result_page.dart';
import 'score_report_page.dart' show QuestionOutcome, QuestionReport;

/// Live quiz screen — the match itself, entered once `OpponentFoundPage`'s
/// countdown hits zero.
///
/// Question set comes from `quizNotifierProvider` -> `GetQuizQuestions`
/// -> `GET ApiConstants.matchQuestions(queueId)` (see that constant's
/// doc comment for the endpoint-path caveat), keyed by the same
/// `queueId` the matched `MatchmakingEntry` was identified by. Same
/// load-on-init / loading-error shape as `LiveCompetitionsPage`.
///
/// [_handleNext]/[_handleAutoSubmit] submit each answer via
/// `quizNotifierProvider.submitAnswer` -> `SubmitAnswer` ->
/// `POST ApiConstants.submitAnswer(queueId)` (`selectedOptionIndex: null`
/// on a timeout auto-submit) before advancing. A failed submission is
/// only logged, not surfaced — see `QuizState.lastAnswerResult`'s doc
/// comment for why gameplay still advances locally either way.
///
/// Per-question timing is synced against a server-issued deadline —
/// `quizNotifierProvider`'s `matchStartedAt`/`secondsPerQuestion` (from
/// `QuizQuestionSet`, via `ApiConstants.matchQuestions`) fix an absolute
/// deadline for each question, and [_startTimer] ticks against
/// [ServerClock.now] rather than counting down a local number, so both
/// opponents' countdowns agree regardless of whose device clock is
/// wrong. Falls back to a purely local, un-synced countdown (the old
/// behavior) if the backend hasn't sent that timing yet — see
/// `QuizQuestionSetModel`'s doc comment on why those fields are still
/// unconfirmed/nullable.
///
/// Not yet added to any router; construct directly from wherever
/// `OpponentFoundPage.onCountdownComplete` fires, passing the matched
/// `MatchmakingEntry.queueId`.
class QuizPage extends ConsumerStatefulWidget {
  final String queueId;
  final int secondsPerQuestion;

  const QuizPage({super.key, required this.queueId, this.secondsPerQuestion = 15});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _questionIndex = 0;
  int? _selectedOption;
  bool _isLocked = false;
  bool _autoSubmitting = false;

  late int _secondsLeft = widget.secondsPerQuestion;
  Timer? _timer;
  bool _timerStarted = false;

  /// Server-issued per-question duration once `QuizQuestionSet` has
  /// loaded, else `widget.secondsPerQuestion` — used anywhere a total
  /// (as opposed to remaining) duration is needed, e.g. `CircularTimer`'s
  /// ring fraction and the fallback local countdown's starting point.
  int get _effectiveSecondsPerQuestion =>
      ref.read(quizNotifierProvider).secondsPerQuestion ?? widget.secondsPerQuestion;

  List<Question> get _questions => ref.read(quizNotifierProvider).questions;
  Question get _current => _questions[_questionIndex];
  bool get _isLastQuestion => _questionIndex == _questions.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizNotifierProvider.notifier).loadQuestions(queueId: widget.queueId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Absolute server-clock deadline for the current question, or null
  /// if the backend hasn't sent match timing yet (see `QuizQuestionSet`'s
  /// doc comment) — in which case [_startTimer] falls back to counting
  /// down locally instead.
  DateTime? get _currentQuestionDeadline {
    final state = ref.read(quizNotifierProvider);
    final startedAt = state.matchStartedAt;
    final perQuestion = state.secondsPerQuestion;
    if (startedAt == null || perQuestion == null) return null;
    return startedAt.add(Duration(seconds: perQuestion * (_questionIndex + 1)));
  }

  void _startTimer() {
    _timer?.cancel();
    final deadline = _currentQuestionDeadline;

    if (deadline == null) {
      // No server-issued deadline available for this match yet — same
      // fully-local countdown as before, just without cross-device sync.
      if (mounted) setState(() => _secondsLeft = _effectiveSecondsPerQuestion);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_secondsLeft <= 1) {
          setState(() => _secondsLeft = 0);
          _handleAutoSubmit();
          return;
        }
        setState(() => _secondsLeft -= 1);
      });
      return;
    }

    // Ticks every 250ms rather than every second so the displayed
    // count and the auto-submit both stay tight against the deadline —
    // recomputing `secondsLeft` from the absolute deadline each tick
    // (instead of decrementing a counter) means this also self-corrects
    // after the app is backgrounded/resumed, rather than resuming a
    // stale countdown.
    void tick() {
      if (!mounted) return;
      final remainingMs = deadline.difference(ServerClock.instance.now()).inMilliseconds;
      if (remainingMs <= 0) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        _handleAutoSubmit();
        return;
      }
      setState(() => _secondsLeft = (remainingMs / 1000).ceil());
    }

    tick(); // sync immediately instead of waiting a quarter-second for the first tick
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  void _selectOption(int index) {
    if (_isLocked) return;
    setState(() => _selectedOption = index);
  }

  Future<void> _handleAutoSubmit() async {
    if (_isLocked) return;
    _timer?.cancel();
    setState(() {
      _isLocked = true;
      _autoSubmitting = true;
    });

    // Timeout — no option was selected, so send `selectedOptionIndex: null`
    // (see `ApiConstants.submitAnswer`'s doc comment).
    await ref.read(quizNotifierProvider.notifier).submitAnswer(
          queueId: widget.queueId,
          questionId: _current.id,
          selectedOptionIndex: null,
        );
    if (!mounted) return;
    _advance();
  }

  Future<void> _handleNext() async {
    if (_selectedOption == null || _isLocked) return;

    // Only the final question's manual submit is confirmed — earlier
    // questions already auto-advance without a prompt (per the
    // forward-only, no-revisit flow), and a timeout auto-submit isn't a
    // deliberate user action to confirm. Ending the whole match is the
    // one step here that's worth a "are you sure", since there's no way
    // back into the quiz afterward.
    if (_isLastQuestion) {
      _timer?.cancel();
      final confirmed = await showConfirmDialog(
        context,
        title: 'Submit final answer?',
        message: "You won't be able to change this once submitted, and the quiz will end.",
        confirmLabel: 'Submit',
        cancelLabel: 'Keep reviewing',
        isDestructive: false,
      );
      if (!mounted) return;
      if (!confirmed) {
        _startTimer(); // resume the countdown from where it paused
        return;
      }
    }

    // Capture before `_advance()` moves `_questionIndex`/`_selectedOption` on.
    final questionId = _current.id;
    final selectedOptionIndex = _selectedOption;

    _timer?.cancel();
    setState(() => _isLocked = true);

    await ref.read(quizNotifierProvider.notifier).submitAnswer(
          queueId: widget.queueId,
          questionId: questionId,
          selectedOptionIndex: selectedOptionIndex,
        );
    if (!mounted) return;
    _advance();
  }

  void _advance() {
    if (_isLastQuestion) {
      _timer?.cancel();
      setState(() => _autoSubmitting = false);
      _goToCompletedThenResult();
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedOption = null;
      _isLocked = false;
      _autoSubmitting = false;
      _secondsLeft = _effectiveSecondsPerQuestion;
    });
    _startTimer();
  }

  /// Navigates Quiz → Quiz Completed → Result. Quiz Completed is pushed
  /// immediately once the last question is answered/auto-submitted;
  /// it's replaced (not stacked) by Result once the settled outcome
  /// comes back, so the player can't navigate back into a finished match.
  ///
  /// TODO(matchmaking-feature, socket-io): `minimumDelayFuture` below is
  /// a stand-in for waiting on the server's match-result *event* — once
  /// a Socket.IO `match:result` message (emitted when both players'
  /// answers are scored) exists, drive the transition off that firing
  /// instead, so Quiz Completed stays up for exactly as long as the
  /// opponent actually takes rather than a fixed floor.
  Future<void> _goToCompletedThenResult() async {
    final navigator = Navigator.of(context);

    navigator.push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(child: QuizCompletedView(total: _questions.length)),
        ),
      ),
    );

    // Fetches the real settled outcome (`ApiConstants.matchResult`)
    // while `QuizCompletedView` is up. Both futures below are started
    // before either is awaited, so awaiting them in sequence still only
    // takes as long as the slower of the two — this just keeps that
    // screen from flashing by too quickly if the response comes back
    // instantly, without capping a genuinely slower response.
    final matchResultFuture = ref.read(quizNotifierProvider.notifier).loadMatchResult(queueId: widget.queueId);
    final minimumDelayFuture = Future<void>.delayed(const Duration(seconds: 2));

    final matchResult = await matchResultFuture;
    await minimumDelayFuture;
    if (!mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => matchResult != null
            ? ResultPage(
                you: _toQueuePlayer(matchResult.you),
                opponent: _toQueuePlayer(matchResult.opponent),
                yourScore: matchResult.yourScore,
                opponentScore: matchResult.opponentScore,
                correctAnswers: matchResult.correctAnswers,
                totalQuestions: matchResult.totalQuestions,
                timeTakenLabel: _formatTimeTaken(matchResult.timeTakenSeconds),
                category: matchResult.category,
                matchId: matchResult.matchId,
                questionBreakdown: matchResult.questionBreakdown?.map(_toQuestionReport).toList(),
              )
            : ResultPage(
                // The result fetch above failed (see
                // `QuizNotifier.loadMatchResult`'s doc comment) — same
                // placeholder values used before the result API existed,
                // so the player still sees *something* rather than
                // getting stuck on Quiz Completed forever.
                you: const QueuePlayer(name: 'You'),
                opponent: const QueuePlayer(name: 'Opponent'),
                yourScore: _questions.length * 10,
                opponentScore: ((_questions.length * 10) * 0.8).round(),
                correctAnswers: _questions.length,
                totalQuestions: _questions.length,
                timeTakenLabel: '—',
                category: 'General Knowledge',
                matchId: 'placeholder-match-id',
              ),
      ),
    );
  }

  QueuePlayer _toQueuePlayer(MatchResultPlayer player) {
    return QueuePlayer(name: player.name, photoUrl: player.photoUrl, rankLabel: player.rankLabel);
  }

  QuestionReport _toQuestionReport(MatchResultQuestion question) {
    return QuestionReport(
      number: question.number,
      question: question.question,
      yourAnswer: question.yourAnswer,
      correctAnswer: question.correctAnswer,
      outcome: question.wasSkipped
          ? QuestionOutcome.skipped
          : question.isCorrect
              ? QuestionOutcome.correct
              : QuestionOutcome.incorrect,
      timeTakenSeconds: question.timeTakenSeconds,
    );
  }

  String _formatTimeTaken(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    final questions = quizState.questions;

    if (quizState.viewState == QuizViewState.error && questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorState(
            message: quizState.errorMessage ?? "Couldn't load questions",
            onRetry: () => ref.read(quizNotifierProvider.notifier).loadQuestions(queueId: widget.queueId),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      // Covers both `initial`/`loading` and a `loaded` response that
      // came back with zero questions — either way there's nothing to
      // quiz on yet, so the per-question timer stays off (see
      // `_timerStarted`) until this page rebuilds with a non-empty list.
      return const Scaffold(body: SafeArea(child: LoadingIndicator()));
    }

    if (!_timerStarted) {
      _timerStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _QuestionCounter(current: _questionIndex + 1, total: questions.length),
                    const Spacer(),
                    CircularTimer(
                      secondsLeft: _secondsLeft,
                      totalSeconds: _effectiveSecondsPerQuestion,
                      warnBelowSeconds: 10,
                      dangerBelowSeconds: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: QuestionProgressBar(
                  total: questions.length,
                  current: _questionIndex,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuestionCard(question: _current.text),
                      const SizedBox(height: AppSpacing.xl),
                      for (int i = 0; i < _current.options.length; i++) ...[
                        AnswerOptionCard(
                          label: String.fromCharCode(65 + i),
                          text: _current.options[i],
                          isSelected: _selectedOption == i,
                          isLocked: _isLocked,
                          onTap: () => _selectOption(i),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _autoSubmitting
                    ? _AutoSubmitBanner(key: const ValueKey('auto'))
                    : Padding(
                        key: const ValueKey('next'),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                        ),
                        child: QuestionNavigationBar(
                          isLastQuestion: _isLastQuestion,
                          canSubmit: _selectedOption != null && !_isLocked,
                          onNext: _handleNext,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCounter extends StatelessWidget {
  final int current;
  final int total;

  const _QuestionCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer),
          children: [
            TextSpan(text: 'Question $current', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: ' of $total', style: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the Next button once time runs out on an
/// unanswered question — makes the auto-submit behaviour explicit rather
/// than silently jumping to the next question.
class _AutoSubmitBanner extends StatelessWidget {
  const _AutoSubmitBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: semantic.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: semantic.onWarningContainer),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              "Time's up — auto-submitting",
              style: theme.textTheme.titleSmall?.copyWith(color: semantic.onWarningContainer),
            ),
          ],
        ),
      ),
    );
  }
}

