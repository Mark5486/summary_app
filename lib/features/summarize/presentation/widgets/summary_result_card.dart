import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/summary.dart';

/// كارت النتيجة: أهم النقاط + شرح مبسط + إحصائيات الاختصار + نسخ.
class SummaryResultCard extends StatelessWidget {
  final Summary summary;

  const SummaryResultCard({super.key, required this.summary});

  String _plainText(AppStrings s) {
    final buffer = StringBuffer()
      ..writeln('${s.pointsTitle}:')
      ..writeln();
    for (var i = 0; i < summary.result.points.length; i++) {
      buffer.writeln('${i + 1}. ${summary.result.points[i]}');
    }
    buffer
      ..writeln()
      ..writeln('${s.explanationTitle}:')
      ..writeln(summary.result.explanation);
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final result = summary.result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── أهم النقاط ───
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.pointsTitle, style: AppTextStyles.title(context)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            for (var i = 0; i < result.points.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      margin: const EdgeInsetsDirectional.only(end: 10, top: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        result.points[i],
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: AppSizes.paddingLarge),

            // ─── شرح مبسط ───
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.explanationTitle,
                    style: AppTextStyles.title(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: SelectableText(
                result.explanation,
                style: AppTextStyles.body(context),
              ),
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // ─── إحصائيات + نسخ ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.originalLabel}: ${result.originalWordCount} ${s.words}'
                    '  •  ${s.compressionLabel}: '
                    '${(result.compressionRatio * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.hint(context),
                  ),
                ),
                IconButton(
                  tooltip: s.copySummary,
                  onPressed: () {
                    // نسخ النص للمسافة اللصق — محلي بالكامل.
                    _copy(context, _plainText(s));
                  },
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    final s = AppStrings.of(context);
    await TextCopyHelper.copy(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.copied)),
      );
    }
  }
}

/// فصل النسخ في helper صغير — سهل الاختبار.
abstract final class TextCopyHelper {
  static Future<void> copy(String text) async {
    // Clipboard من flutter/services.
    await Clipboard.setData(ClipboardData(text: text));
  }
}
