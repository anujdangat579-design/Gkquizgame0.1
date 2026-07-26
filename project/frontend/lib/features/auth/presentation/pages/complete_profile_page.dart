import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// Post-signup profile completion screen — UI only, mirroring
/// `RegisterPage`'s scope. No `auth/domain` or `auth/data` layer exists
/// yet, so [_handleSubmit] validates the form and toggles the loading
/// affordance without calling a real endpoint. See the doc comment on
/// `LoginPage` for the intended wiring once the auth feature's use cases
/// land — this would plug into something like
/// `authNotifierProvider.notifier.completeProfile(...)`.
///
/// Sits between OTP verification and the main app: once a user is
/// verified but hasn't filled in name/DOB/gender/avatar yet, route here
/// instead of straight into `CompetitionRoutes.list`.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // No back button — this step is mandatory once a user is
        // verified but incomplete; there's nowhere meaningful to go
        // back to (mirrors LoginPage's reasoning for having no AppBar).
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Complete your profile',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'A few more details before you start with ${AppConstants.appName}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    _AvatarPicker(
                      onTap: _isLoading ? null : _handlePickAvatar,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      maxLength: AppConstants.nameMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                        counterText: '',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email),
                        helperText: 'This is how others will see you on leaderboards',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Username is required';
                        if (value.trim().length < 3) return 'Use at least 3 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                          return 'Letters, numbers, and underscores only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    DatePickerTile(
                      label: 'Date of birth',
                      value: _dateOfBirth,
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                      formatDate: (date) => DateFormat(AppConstants.dateDisplayFormat).format(date),
                      onChanged: (date) => setState(() => _dateOfBirth = date),
                    ),
                    const Divider(height: AppSpacing.lg),

                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: _genderOptions
                          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => value == null ? 'Select a gender' : null,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                      child: const Text('Continue'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePickAvatar() {
    // TODO(auth-feature): wire up an image_picker (or similar) call once
    // the profile media pipeline exists, then upload through whatever
    // storage the backend expects. Placeholder so the affordance isn't a
    // dead tap target.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo picker isn\'t wired up yet')),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      setState(() => _errorMessage = 'Date of birth is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // TODO(auth-feature): replace with a real call once `auth/domain` +
    // `auth/data` exist, e.g.:
    //   final result = await ref.read(authNotifierProvider.notifier).completeProfile(
    //     name: _nameController.text.trim(),
    //     username: _usernameController.text.trim(),
    //     dateOfBirth: _dateOfBirth!,
    //     gender: _gender!,
    //   );
    // For now this only proves out the UI's loading/error states.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO(auth-feature): once wired, navigate into the main app instead,
    // e.g. `context.go(CompetitionRoutes.list)`.
  }
}

class _AvatarPicker extends StatelessWidget {
  final VoidCallback? onTap;

  const _AvatarPicker({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
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
