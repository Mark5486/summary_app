import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/summary.dart';
import '../cubit/summarize_cubit.dart';
import 'summary_result_card.dart';

/// قسم النتيجة على الهوم: عنوان واضح + شارة الحفظ + الكارت نفسه.
///
/// - نتيجة تلخيص جديدة → العنوان "النتيجة" + شارة "محفوظ في السجل ✓".
/// - آخر ملخص مترجّع من السجل → العنوان "آخر ملخص من السجل" + زرار
///   مسح من الهوم (السجل نفسه مبيتلمس).
class SummaryResultSection extends StatelessWidget {
  final Summary summary;
  final bool restoredFromHistory;

  const SummaryResultSection({
    super.key,
    required this.summary,
    this.restoredFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              restoredFromHistory
                  ? Icons.history_rounded
                  : Icons.auto_awesome_outlined,
              color: primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                restoredFromHistory ? s.lastSummaryTitle : s.resultTitle,
                style: AppTextStyles.title(context),
              ),
            ),
            // شارة الحفظ للنتيجة الجديدة — وزرار مسح للمرجّع من السجل.
            if (restoredFromHistory)
              IconButton(
                tooltip: s.removeFromHome,
                onPressed: () =>
                    context.read<SummarizeCubit>().dismissRestoredSummary(),
                icon: const Icon(Icons.delete_outline, size: 20),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Text(
                  s.savedToHistory,
                  style: AppTextStyles.hint(context).copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        SummaryResultCard(summary: summary),
      ],
    );
  }
}
