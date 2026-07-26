import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/account_notifier.dart';

/// Edit-profile form, pushed from `AccountPage`'s new edit action.
///
/// Wires the `UpdateProfile` use case (account/domain) that already
/// existed — see `AccountRepository.updateProfile`'s doc comment — but
/// had no screen calling it. Pre-fills from the profile already loaded
/// by `AccountPage`, so this never needs its own `GetProfile` fetch.
///
/// Avatar isn't editable here: there's no image-upload endpoint/pipeline
/// yet (see `CompleteProfilePage._handlePickAvatar`'s same gap at
/// signup), so this form only covers the fields `ApiConstants.profile`'s
/// `PATCH` already accepts — name, username, date of birth, gender.
class EditProfilePage extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;

  DateTime? _dateOfBirth;
  String? _gender;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _usernameController = TextEditingController(text: widget.profile.username ?? '');
    _dateOfBirth = widget.profile.dateOfBirth;
    // Only preselect a gender the dropdown actually offers — an
    // unrecognized value from the backend would otherwise crash
    // DropdownButtonFormField's assertion that `initialValue` is one of
    // `items`.
    _gender = _genderOptions.contains(widget.profile.gender) ? widget.profile.gender : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
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
                  items: _genderOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: AppSpacing.xxl),

                LoadingButton(
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Only sends fields that actually changed — a PATCH shouldn't push
    // back the same value as a fresh "update" for no reason, though
    // `UserProfileModel.toUpdateJson` would no-op unchanged nulls anyway.
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    final succeeded = await ref.read(accountNotifierProvider.notifier).editProfile(
          name: name != widget.profile.name ? name : null,
          username: username != (widget.profile.username ?? '') ? username : null,
          dateOfBirth: _dateOfBirth != widget.profile.dateOfBirth ? _dateOfBirth : null,
          gender: _gender != widget.profile.gender ? _gender : null,
        );

    if (!mounted) return;

    if (!succeeded) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = ref.read(accountNotifierProvider).errorMessage ?? 'Couldn\u2019t save changes. Please try again.';
      });
      return;
    }

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
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
            child: Text(message, style: TextStyle(color: colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
