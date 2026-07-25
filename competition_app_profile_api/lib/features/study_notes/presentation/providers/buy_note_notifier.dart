import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../injection_container.dart';
import '../../../payment/data/services/cashfree_checkout_service.dart';
import '../../domain/entities/note_purchase_verification.dart';
import '../../domain/usecases/create_note_order.dart';
import '../../domain/usecases/verify_note_payment.dart';
import 'buy_note_state.dart';

/// Keyed by note id via `.family` + `.autoDispose` - same reasoning as
/// `joinCompetitionNotifierProvider`: two notes' in-flight payment
/// states never share state, and a finished/abandoned flow doesn't
/// linger once `NoteDetailsPage` is popped.
///
/// `ref.watch(buyNoteNotifierProvider(noteId))` gives the current
/// [BuyNoteState]; `ref.read(...notifier).buy()` drives the whole
/// create-order -> Cashfree checkout -> server-verify sequence and
/// resolves to whether the note is now owned.
final buyNoteNotifierProvider =
    StateNotifierProvider.autoDispose.family<BuyNoteNotifier, BuyNoteState, String>((ref, noteId) {
  return BuyNoteNotifier(
    noteId: noteId,
    createNoteOrder: sl(),
    verifyNotePayment: sl(),
    // Reuses the payment feature's checkout wrapper rather than
    // standing up a second Cashfree integration - same instance
    // `JoinCompetitionNotifier` uses, registered once in
    // `registerPaymentDependencies`.
    checkoutService: sl(),
  );
});

class BuyNoteNotifier extends StateNotifier<BuyNoteState> {
  final String noteId;
  final CreateNoteOrder createNoteOrder;
  final VerifyNotePayment verifyNotePayment;
  final CashfreeCheckoutService checkoutService;

  BuyNoteNotifier({
    required this.noteId,
    required this.createNoteOrder,
    required this.verifyNotePayment,
    required this.checkoutService,
  }) : super(const BuyNoteState());

  /// Runs the full buy flow for this note. Returns `true` only once the
  /// backend has confirmed both the payment and the purchase; any
  /// earlier failure leaves `state.errorMessage` set for the page to
  /// show and returns `false` so the "Buy" button can be re-enabled.
  Future<bool> buy() async {
    state = state.copyWith(viewState: BuyNoteViewState.creatingOrder, clearError: true);

    final orderResult = await createNoteOrder(noteId);

    final order = orderResult.fold(
      (failure) {
        AppLogger.warning('createNoteOrder($noteId) failed: ${failure.message}', tag: 'StudyNotes');
        state = state.copyWith(viewState: BuyNoteViewState.error, errorMessage: failure.message);
        return null;
      },
      (order) => order,
    );
    if (order == null) return false;

    state = state.copyWith(viewState: BuyNoteViewState.awaitingCheckout);

    final outcome = await checkoutService.startCheckout(
      orderId: order.orderId,
      paymentSessionId: order.paymentSessionId,
    );

    if (outcome.type == CashfreeCheckoutOutcomeType.sdkError) {
      state = state.copyWith(
        viewState: BuyNoteViewState.error,
        errorMessage: outcome.errorMessage ?? 'Payment could not be started',
      );
      return false;
    }

    state = state.copyWith(viewState: BuyNoteViewState.verifying);

    final verifyResult = await verifyNotePayment(order.orderId);

    final verification = verifyResult.fold(
      (failure) {
        AppLogger.warning('verifyNotePayment(${order.orderId}) failed: ${failure.message}', tag: 'StudyNotes');
        state = state.copyWith(viewState: BuyNoteViewState.error, errorMessage: failure.message);
        return null;
      },
      (verification) => verification,
    );
    if (verification == null) return false;

    if (verification.status != NotePaymentStatus.success || !verification.purchased) {
      AppLogger.warning(
        'Order ${order.orderId} not confirmed purchased: ${verification.status} / purchased=${verification.purchased}',
        tag: 'StudyNotes',
      );
      state = state.copyWith(viewState: BuyNoteViewState.error, errorMessage: verification.message);
      return false;
    }

    state = state.copyWith(viewState: BuyNoteViewState.purchased, clearError: true);
    return true;
  }
}
