import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/summary_model.dart';

class HistoryCard extends StatelessWidget {
  final SummaryModel entry;
  final VoidCallback? onDelete;

  const HistoryCard({super.key, required this.entry, this.onDelete});

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}/${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final title = entry.points.isNotEmpty
        ? entry.points.first
        : entry.originalText.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title.length > 70 ? '${title.substring(0, 70)}…' : title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title(context).copyWith(fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_formatDate(entry.createdAtMs)}'
            ' • ${entry.summaryWordCount}/${entry.originalWordCount} ${s.words}',
            style: AppTextStyles.hint(context),
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(s.pointsTitle, style: AppTextStyles.title(context)),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < entry.points.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      entry.points[i],
                      style: AppTextStyles.body(context),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              s.explanationTitle,
              style: AppTextStyles.title(context),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(entry.explanation, style: AppTextStyles.body(context)),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(s.delete),
            ),
          ),
        ],
      ),
    );
  }
}
