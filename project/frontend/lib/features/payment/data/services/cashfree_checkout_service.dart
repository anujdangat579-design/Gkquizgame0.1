import 'dart:async';

import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Outcome of a `CashfreeCheckoutService.startCheckout` call. Deliberately
/// *not* "success"/"failure" — the SDK's own callbacks never report the
/// actual payment result (see [CashfreeCheckoutOutcome.finished]'s doc
/// comment), only whether checkout finished normally or errored out
/// before the customer could even attempt payment.
enum CashfreeCheckoutOutcomeType { finished, sdkError }

class CashfreeCheckoutOutcome {
  final CashfreeCheckoutOutcomeType type;
  final String orderId;
  final String? errorMessage;

  const CashfreeCheckoutOutcome._({required this.type, required this.orderId, this.errorMessage});

  /// The checkout UI ran to completion (customer paid, failed, backed
  /// out, or closed it). This is only ever a signal to now confirm the
  /// real outcome server-side via `VerifyPayment` — Cashfree's
  /// `onVerify` callback does not itself mean the payment succeeded.
  factory CashfreeCheckoutOutcome.finished(String orderId) =>
      CashfreeCheckoutOutcome._(type: CashfreeCheckoutOutcomeType.finished, orderId: orderId);

  /// The SDK itself failed before/during checkout (bad session, no
  /// network reaching Cashfree, malformed payment object, etc.) —
  /// distinct from the customer's payment being declined, which still
  /// surfaces as [finished] since the checkout UI did run.
  factory CashfreeCheckoutOutcome.sdkError(String orderId, String message) =>
      CashfreeCheckoutOutcome._(
        type: CashfreeCheckoutOutcomeType.sdkError,
        orderId: orderId,
        errorMessage: message,
      );
}

/// Thin wrapper around `flutter_cashfree_pg_sdk`'s Web Checkout flow so
/// the rest of the app never touches the plugin's callback-based API
/// directly — mirrors `DioClient`'s role for Dio. Only Web Checkout
/// (`CFWebCheckoutPaymentBuilder`) is used, matching the entry-fee
/// use case (one-shot payment, any method the hosted checkout page
/// offers) rather than the SDK's component-level flows (raw UPI/card/
/// netbanking widgets), which this app has no UI for.
///
/// **Server-side prerequisites this depends on:**
/// - Order creation (`ApiConstants.paymentOrders`) happens entirely on
///   the backend, since it requires the Cashfree secret key — this
///   class only ever sees the `orderId`/`paymentSessionId` that
///   endpoint returns.
/// - The `environment` passed to `CFSessionBuilder` must match whichever
///   Cashfree keys the backend used to create that order. This app
///   derives it from `EnvConfig.isProd` — sandbox for dev/staging,
///   production for prod — since there's no reason those would ever
///   diverge from which backend a build talks to.
class CashfreeCheckoutService {
  final CFPaymentGatewayService _gateway;

  CashfreeCheckoutService({CFPaymentGatewayService? gateway})
      : _gateway = gateway ?? CFPaymentGatewayService();

  /// Launches the Web Checkout screen for `orderId`/`paymentSessionId`
  /// and resolves once the SDK hands control back to the app — via
  /// either callback, whichever fires first. Never throws for a normal
  /// checkout failure/cancellation (that's still a [CashfreeCheckoutOutcome.finished],
  /// left for `VerifyPayment` to interpret); only rejects if `CFException`
  /// is thrown synchronously while building the session/payment object.
  Future<CashfreeCheckoutOutcome> startCheckout({
    required String orderId,
    required String paymentSessionId,
  }) {
    final completer = Completer<CashfreeCheckoutOutcome>();

    void onVerify(String verifiedOrderId) {
      AppLogger.info('Checkout finished for $verifiedOrderId, verifying server-side', tag: 'Payment');
      if (!completer.isCompleted) {
        completer.complete(CashfreeCheckoutOutcome.finished(verifiedOrderId));
      }
    }

    void onError(CFErrorResponse errorResponse, String erroredOrderId) {
      AppLogger.warning(
        'Cashfree checkout error for $erroredOrderId: ${errorResponse.getMessage()}',
        tag: 'Payment',
      );
      if (!completer.isCompleted) {
        completer.complete(
          CashfreeCheckoutOutcome.sdkError(
            erroredOrderId,
            errorResponse.getMessage() ?? 'Payment could not be started',
          ),
        );
      }
    }

    _gateway.setCallback(onVerify, onError);

    try {
      final environment = EnvConfig.isProd ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;
      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
      final webCheckout = CFWebCheckoutPaymentBuilder().setSession(session).build();
      _gateway.doPayment(webCheckout);
    } on CFException catch (e) {
      AppLogger.warning('Cashfree session/payment build failed: ${e.message}', tag: 'Payment');
      if (!completer.isCompleted) {
        completer.complete(CashfreeCheckoutOutcome.sdkError(orderId, e.message));
      }
    }

    return completer.future;
  }
}
