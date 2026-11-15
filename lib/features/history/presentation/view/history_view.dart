import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive.dart';
import '../../data/models/summary_model.dart';
import '../cubit/history_cubit.dart';
import '../cubit/history_state.dart';
import '../widgets/history_card.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.clearAll),
        content: Text(s.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HistoryCubit>().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocConsumer<HistoryCubit, HistoryState>(
      listener: (context, state) {
        final toast = state.toast;
        if (toast != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.deleted)));
          context.read<HistoryCubit>().consumeToast();
        }
      },
      builder: (context, state) {
        final entries = state.filtered;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.historyTitle),
            actions: [
              if (state.entries.isNotEmpty)
                IconButton(
                  tooltip: s.clearAll,
                  onPressed: () => _confirmClearAll(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),

          body: ResponsiveCenter(
            maxWidth: 900,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: context.read<HistoryCubit>().search,
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),

                Expanded(
                  child: state.entries.isEmpty
                      ? _EmptyState(message: s.historyEmpty)
                      : entries.isEmpty
                      ? _EmptyState(message: s.noSearchResults)
                      : _EntriesList(entries: entries),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EntriesList extends StatelessWidget {
  final List<SummaryModel> entries;

  const _EntriesList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final twoColumns = !context.isCompact;

    if (!twoColumns) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return HistoryCard(
            entry: entry,
            onDelete: () => context.read<HistoryCubit>().delete(entry.id),
          );
        },
      );
    }

    final rowCount = (entries.length + 1) ~/ 2;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rowCount,
      itemBuilder: (context, index) {
        final first = entries[index * 2];
        final second = index * 2 + 1 < entries.length
            ? entries[index * 2 + 1]
            : null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HistoryCard(
                entry: first,
                onDelete: () => context.read<HistoryCubit>().delete(first.id),
              ),
            ),
            const SizedBox(width: 12),
            if (second != null)
              Expanded(
                child: HistoryCard(
                  entry: second,
                  onDelete: () =>
                      context.read<HistoryCubit>().delete(second.id),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.hint(context),
            ),
          ],
        ),
      ),
    );
  }
}
