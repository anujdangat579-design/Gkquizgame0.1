import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/competition.dart';
import '../providers/competition_notifier.dart';

class CompetitionFormPage extends ConsumerStatefulWidget {
  final Competition? competition;

  const CompetitionFormPage({super.key, this.competition});

  bool get isEditing => competition != null;

  @override
  ConsumerState<CompetitionFormPage> createState() => _CompetitionFormPageState();
}

class _CompetitionFormPageState extends ConsumerState<CompetitionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.competition?.name ?? '');
    _descriptionController = TextEditingController(text: widget.competition?.description ?? '');
    _startDate = widget.competition?.startDate;
    _endDate = widget.competition?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = ref.watch(
      competitionNotifierProvider.select((state) => state.isMutating),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Competition' : 'New Competition')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              maxLength: AppConstants.nameMaxLength,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              maxLength: AppConstants.descriptionMaxLength,
            ),
            const SizedBox(height: 16),
            DatePickerTile(
              label: 'Start date',
              value: _startDate,
              onChanged: (date) => setState(() => _startDate = date),
            ),
            DatePickerTile(
              label: 'End date',
              value: _endDate,
              onChanged: (date) => setState(() => _endDate = date),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: isMutating,
              onPressed: _submit,
              child: Text(widget.isEditing ? 'Save changes' : 'Create competition'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(competitionNotifierProvider.notifier);
    final bool success;

    if (widget.isEditing) {
      success = await notifier.update(
        id: widget.competition!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      success = await notifier.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );
    }

    if (!mounted) return;
    if (success) {
      context.pop();
    } else {
      final errorMessage = ref.read(competitionNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'Something went wrong')),
      );
    }
  }
}
