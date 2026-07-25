import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../../matchmaking/domain/usecases/enter_matchmaking_queue.dart';
import '../../data/services/cashfree_checkout_service.dart';
import '../../domain/entities/payment_verification.dart';
import '../../domain/usecases/create_payment_order.dart';
import '../../domain/usecases/verify_payment.dart';
import 'join_competition_state.dart';

/// Keyed by competition id via `.family` (same reasoning as
/// `competitionDetailsNotifierProvider`) so joining two different
/// competitions in the same session doesn't share in-flight payment
/// state, and `.autoDispose` so a finished/abandoned flow doesn't linger
/// once `CompetitionDetailsPage` is popped.
///
/// `ref.watch(joinCompetitionNotifierProvider(id))` gives the current
/// [JoinCompetitionState]; `ref.read(...notifier).join(...)` drives the
/// whole create-order -> Cashfree checkout -> server-verify ->
/// enter-matchmaking-queue sequence and resolves to whether the player
/// is now joined and queued.
final joinCompetitionNotifierProvider = StateNotifierProvider.autoDispose
    .family<JoinCompetitionNotifier, JoinCompetitionState, String>((ref, competitionId) {
  return JoinCompetitionNotifier(
    competitionId: competitionId,
    createPaymentOrder: sl(),
    verifyPayment: sl(),
    checkoutService: sl(),
    enterMatchmakingQueue: sl(),
  );
});

class JoinCompetitionNotifier extends StateNotifier<JoinCompetitionState> {
  final String competitionId;
  final CreatePaymentOrder createPaymentOrder;
  final VerifyPayment verifyPayment;
  final CashfreeCheckoutService checkoutService;
  final EnterMatchmakingQueue enterMatchmakingQueue;

  JoinCompetitionNotifier({
    required this.competitionId,
    required this.createPaymentOrder,
    required this.verifyPayment,
    required this.checkoutService,
    required this.enterMatchmakingQueue,
  }) : super(const JoinCompetitionState());

  /// Runs the full join flow for the difficulty tier the player picked
  /// on `CompetitionDetailsPage`. Returns `true` only once the backend
  /// has confirmed both the payment and the competition entry; any
  /// earlier failure leaves `state.errorMessage` set for the page to
  /// show and returns `false` so the "Join competition" button can be
  /// re-enabled.
  Future<bool> join({required String difficultyLevel}) async {
    state = state.copyWith(viewState: JoinCompetitionViewState.creatingOrder, clearError: true);

    final orderResult = await createPaymentOrder(
      CreatePaymentOrderParams(competitionId: competitionId, difficultyLevel: difficultyLevel),
    );

    final order = orderResult.fold(
      (failure) {
        AppLogger.warning('createOrder($competitionId) failed: ${failure.message}', tag: 'Payment');
        state = state.copyWith(viewState: JoinCompetitionViewState.error, errorMessage: failure.message);
        return null;
      },
      (order) => order,
    );
    if (order == null) return false;

    state = state.copyWith(viewState: JoinCompetitionViewState.awaitingCheckout);

    final outcome = await checkoutService.startCheckout(
      orderId: order.orderId,
      paymentSessionId: order.paymentSessionId,
    );

    if (outcome.type == CashfreeCheckoutOutcomeType.sdkError) {
      state = state.copyWith(
        viewState: JoinCompetitionViewState.error,
        errorMessage: outcome.errorMessage ?? 'Payment could not be started',
      );
      return false;
    }

    state = state.copyWith(viewState: JoinCompetitionViewState.verifying);

    final verifyResult = await verifyPayment(order.orderId);

    final verification = verifyResult.fold(
      (failure) {
        AppLogger.warning('verifyPayment(${order.orderId}) failed: ${failure.message}', tag: 'Payment');
        state = state.copyWith(viewState: JoinCompetitionViewState.error, errorMessage: failure.message);
        return null;
      },
      (verification) => verification,
    );
    if (verification == null) return false;

    if (verification.status != PaymentStatus.success || !verification.joined) {
      AppLogger.warning(
        'Order ${order.orderId} not confirmed joined: ${verification.status} / joined=${verification.joined}',
        tag: 'Payment',
      );
      state = state.copyWith(viewState: JoinCompetitionViewState.error, errorMessage: verification.message);
      return false;
    }

    // Payment is confirmed and the player is joined server-side — now
    // place them into the live matchmaking pool so `WaitingQueuePage`
    // has a real queue entry (position/players-ahead/wait-time) instead
    // of starting from placeholder defaults.
    state = state.copyWith(viewState: JoinCompetitionViewState.enteringQueue);

    final queueResult = await enterMatchmakingQueue(
      EnterMatchmakingQueueParams(competitionId: competitionId, orderId: order.orderId),
    );

    return queueResult.fold(
      (failure) {
        AppLogger.warning(
          'enterMatchmakingQueue($competitionId, ${order.orderId}) failed: ${failure.message}',
          tag: 'Matchmaking',
        );
        state = state.copyWith(viewState: JoinCompetitionViewState.error, errorMessage: failure.message);
        return false;
      },
      (entry) {
        state = state.copyWith(
          viewState: JoinCompetitionViewState.joined,
          matchmakingEntry: entry,
          clearError: true,
        );
        return true;
      },
    );
  }
}
