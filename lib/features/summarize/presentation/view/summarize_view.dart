import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/platform_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/responsive.dart';
import '../pages/capture_page.dart';
import '../cubit/summarize_cubit.dart';
import '../cubit/summarize_state.dart';
import '../widgets/file_info_card.dart';
import '../widgets/summary_result_section.dart';

class SummarizeView extends StatefulWidget {
  const SummarizeView({super.key});

  @override
  State<SummarizeView> createState() => _SummarizeViewState();
}

class _SummarizeViewState extends State<SummarizeView> {
  final _inputController = TextEditingController();

  final _resultKey = GlobalKey();

  SummarizeStatus? _lastStatus;

  String? _countedInput;
  int _cachedWordCount = 0;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final captured = await Navigator.of(
      context,
    ).push<XFile>(MaterialPageRoute(builder: (_) => const CapturePage()));

    if (captured != null && mounted) {
      context.read<SummarizeCubit>().recognizeImage(captured);
    }
  }

  void _summarize() {
    if (_inputController.text.trim().isEmpty) {
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.emptyInput)));
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<SummarizeCubit>().summarize();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocConsumer<SummarizeCubit, SummarizeState>(
      listener: (context, state) {
        if (state.status == SummarizeStatus.success &&
            _lastStatus != SummarizeStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final resultContext = _resultKey.currentContext;
            if (resultContext != null) {
              Scrollable.ensureVisible(
                resultContext,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
        _lastStatus = state.status;

        final preview = state.previewText;
        if (preview != null) {
          if (_inputController.text != preview) {
            _inputController.text = preview;
            _inputController.selection = const TextSelection.collapsed(
              offset: 0,
            );
          }
        } else if (state.inputText != _inputController.text) {
          _inputController.text = state.inputText;
          _inputController.selection = TextSelection.collapsed(
            offset: _inputController.text.length,
          );
        }

        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(failureToMessage(failure, s))),
            );
        }

        final notice = state.notice;
        if (notice != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  notice == 'pdfLimited' ? s.pdfPagesLimited : s.textTruncated,
                ),
              ),
            );
          context.read<SummarizeCubit>().consumeNotice();
        }
      },
      builder: (context, state) {
        if (state.fileInfo == null && _countedInput != state.inputText) {
          _countedInput = state.inputText;
          _cachedWordCount = _countWords(state.inputText);
        }
        final wordCount = state.fileInfo?.wordCount ?? _cachedWordCount;
        final busy =
            state.status == SummarizeStatus.loading || state.extracting;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  s.appName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  s.appTagline,
                  style: AppTextStyles.hint(context).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildScrollContent(
                    context,
                    s,
                    state,
                    wordCount,
                    busy: busy,
                  ),
                ),
                _SummarizeBar(
                  busy: busy,
                  loading: state.status == SummarizeStatus.loading,
                  extracting: state.extracting,
                  label: s.summarizeButton,
                  onSummarize: _summarize,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollContent(
    BuildContext context,
    AppStrings s,
    SummarizeState state,
    int wordCount, {
    required bool busy,
  }) {
    if (context.isTwoPane && state.summary != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildInputCard(context, s, state, wordCount, busy: busy),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.paddingMedium),

            Expanded(
              flex: 4,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [_buildResultSection(state)],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      children: [
        ResponsiveCenter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(context, s, state, wordCount, busy: busy),

              if (state.summary != null) ...[
                const SizedBox(height: AppSizes.paddingLarge),
                _buildResultSection(state),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(
    BuildContext context,
    AppStrings s,
    SummarizeState state,
    int wordCount, {
    required bool busy,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.previewText != null)
              SelectableText(
                state.previewText!,
                style: AppTextStyles.body(context),
              )
            else
              TextField(
                controller: _inputController,
                onChanged: context.read<SummarizeCubit>().setInput,
                minLines: 6,
                maxLines: 12,

                maxLength: SummarizeCubit.maxInputChars,
                textDirection: null,
                decoration: InputDecoration(
                  hintText: s.inputHint,
                  border: InputBorder.none,

                  counterText: '',
                ),
                style: AppTextStyles.body(context),
              ),
            const SizedBox(height: AppSizes.paddingSmall),

            Wrap(
              spacing: AppSizes.paddingSmall,
              runSpacing: AppSizes.paddingSmall,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : context.read<SummarizeCubit>().loadFromFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(s.openFile),
                ),
                if (!_cameraHiddenOnThisPlatform)
                  OutlinedButton.icon(
                    onPressed: busy ? null : _openCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(s.camera),
                  ),
              ],
            ),

            if (state.fileInfo != null) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              FileInfoCard(
                info: state.fileInfo!,
                previewing: state.previewText != null,
                ocrProgress: state.ocrProgress,
                onRunOcr: state.fileInfo!.scanned && !state.extracting
                    ? context.read<SummarizeCubit>().ocrScannedPdf
                    : null,
              ),
            ],

            const SizedBox(height: AppSizes.paddingSmall),
            Row(
              children: [
                if (state.inputText.isNotEmpty)
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : context.read<SummarizeCubit>().clearInput,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: Text(s.clearButton),
                  ),
                const Spacer(),
                Text(
                  '$wordCount ${s.words}',
                  style: AppTextStyles.hint(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  KeyedSubtree _buildResultSection(SummarizeState state) {
    return KeyedSubtree(
      key: _resultKey,
      child: SummaryResultSection(
        summary: state.summary!,
        restoredFromHistory: state.restoredFromHistory,
      ),
    );
  }

  static final bool _cameraHiddenOnThisPlatform = isWindows;

  static int _countWords(String text) {
    var count = 0;
    for (final w in text.split(RegExp(r'\s+'))) {
      if (w.trim().isNotEmpty) count++;
    }
    return count;
  }
}

class _SummarizeBar extends StatelessWidget {
  final bool busy;
  final bool loading;
  final bool extracting;
  final String label;
  final VoidCallback onSummarize;

  const _SummarizeBar({
    required this.busy,
    required this.loading,
    required this.extracting,
    required this.label,
    required this.onSummarize,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: outline.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSizes.paddingMedium,
          AppSizes.paddingSmall,
          AppSizes.paddingMedium,
          AppSizes.paddingSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extracting) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: AppSizes.paddingSmall),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onSummarize,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  extracting ? '…' : label,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
