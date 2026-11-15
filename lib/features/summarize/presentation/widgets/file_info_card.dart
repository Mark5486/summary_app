import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/summarize_state.dart';

class FileInfoCard extends StatelessWidget {
  final FileLoadInfo info;
  final VoidCallback? onRunOcr;
  final double? ocrProgress;
  final bool previewing;

  const FileInfoCard({
    super.key,
    required this.info,
    this.onRunOcr,
    this.ocrProgress,
    this.previewing = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (info.scanned) {
      return _card(
        context,
        color: Theme.of(context).colorScheme.tertiaryContainer,
        icon: Icons.image_search_outlined,
        title: s.scannedPdf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onRunOcr != null)
              FilledButton.icon(
                onPressed: onRunOcr,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(s.runOcr),
              ),
            if (ocrProgress != null) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              LinearProgressIndicator(value: ocrProgress!.clamp(0.0, 1.0)),
            ],
          ],
        ),
      );
    }

    final String title;
    if (info.fromOcr) {
      title = s.ocrExtracted(info.wordCount);
    } else if (info.isPdf) {
      title = s.pdfExtracted(info.wordCount, info.pageCount ?? 1);
    } else {
      title = s.txtLoaded(info.wordCount);
    }

    final notes = <String>[
      if (info.pageLimitReached) s.pdfPagesLimited,
      if (info.charLimitReached) s.pdfCharLimited,
      if (previewing) s.previewNote,
    ];

    final IconData icon;
    if (info.isPdf) {
      icon = Icons.picture_as_pdf_outlined;
    } else if (info.fromOcr) {
      icon = Icons.photo_camera_outlined;
    } else {
      icon = Icons.description_outlined;
    }

    return _card(
      context,
      color: Theme.of(context).colorScheme.primaryContainer,
      icon: icon,
      title: title,
      child: notes.isEmpty
          ? null
          : Text(notes.join(' • '), style: AppTextStyles.hint(context)),
    );
  }

  Widget _card(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    Widget? child,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: AppSizes.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(context)),
                  if (child != null) ...[
                    const SizedBox(height: AppSizes.paddingSmall),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
