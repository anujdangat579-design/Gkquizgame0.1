import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// OTP verification screen — UI only for now, mirroring [LoginPage]'s
/// approach: there's no `AuthNotifier` / use case wired up yet (no
/// `auth/domain` or `auth/data` layer exists), so [_handleVerify] and
/// [_handleResend] only drive the local loading/error/timer states. When
/// the auth feature's data/domain layers land, swap those bodies for
/// calls through `ref.read(authNotifierProvider.notifier).verifyOtp(...)`
/// and `.resendOtp(...)` — this page shouldn't need any other changes.
///
/// Expects the destination (phone/email) the code was sent to, purely for
/// display in the subtitle — pass it via GoRouter's `extra` or a query
/// param once this is wired into [AuthRoutes].
class OtpVerificationPage extends StatefulWidget {
  final String destination;

  const OtpVerificationPage({
    super.key,
    this.destination = 'your registered contact',
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 30;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    // Handles paste of the full code into a single box: fan it out across
    // the remaining fields instead of leaving the rest empty.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextEmpty = digits.length.clamp(0, _otpLength - 1);
      _focusNodes[nextEmpty].requestFocus();
      if (digits.length >= _otpLength) {
        FocusScope.of(context).unfocus();
        _handleVerify();
      }
      return;
    }

    if (_errorMessage != null) setState(() => _errorMessage = null);

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isNotEmpty && index == _otpLength - 1) {
      FocusScope.of(context).unfocus();
      if (_code.length == _otpLength) _handleVerify();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 36,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Verify your code',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter the $_otpLength-digit code sent to ${widget.destination}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLength, (index) {
                      return SizedBox(
                        width: 44,
                        height: 52,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.backspace) {
                              _onBackspace(index);
                            }
                          },
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: index == 0 ? _otpLength : 1,
                            style: theme.textTheme.headlineSmall,
                            inputFormatters: index == 0
                                ? [FilteringTextInputFormatter.digitsOnly]
                                : [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                            ),
                            onChanged: (value) => _onDigitChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  LoadingButton(
                    isLoading: _isVerifying,
                    onPressed: _code.length == _otpLength ? _handleVerify : null,
                    child: const Text('Verify'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: _secondsRemaining > 0
                        ? Text(
                            'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : TextButton(
                            onPressed: _isResending ? null : _handleResend,
                            child: _isResending
                                ? const InlineLoadingIndicator()
                                : const Text("Didn't get a code? Resend"),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (_code.length != _otpLength) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // TODO(auth-feature): replace with a real call once `auth/domain` +
    // `auth/data` exist, e.g.:
    //   final result = await ref.read(authNotifierProvider.notifier)
    //       .verifyOtp(destination: widget.destination, code: _code);
    // For now this only proves out the UI's loading/error states.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isVerifying = false);
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);

    // TODO(auth-feature): replace with a real call once `auth/domain` +
    // `auth/data` exist, e.g.:
    //   await ref.read(authNotifierProvider.notifier).resendOtp(widget.destination);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() => _isResending = false);
    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code has been sent')),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
