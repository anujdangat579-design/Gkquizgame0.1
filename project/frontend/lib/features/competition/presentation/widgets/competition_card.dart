import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/competition.dart';

class CompetitionCard extends StatelessWidget {
  final Competition competition;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const CompetitionCard({
    super.key,
    required this.competition,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(AppConstants.dateDisplayFormat);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(competition.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (competition.description != null && competition.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(competition.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            if (competition.startDate != null || competition.endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${competition.startDate != null ? dateFormat.format(competition.startDate!) : '—'} '
                  'to ${competition.endDate != null ? dateFormat.format(competition.endDate!) : '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        leading: StatusAvatar(isActive: competition.isEnabled),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') onToggleStatus();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(competition.isEnabled ? 'Disable' : 'Enable'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
