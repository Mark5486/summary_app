import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/cubit/theme_cubit.dart';
import '../../../../core/theme/cubit/theme_state.dart';
import '../../../../core/localization/cubit/locale_cubit.dart';
import '../../../../core/localization/cubit/locale_state.dart';
import '../../../../core/widgets/responsive.dart';

/// شاشة الإعدادات: الثيم + اللغة + ملاحظة الخصوصية.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // توسيط المحتوى على الشاشات الكبيرة (مهمة 6) — الإعدادات
          // شكلها أحلى بعرض محدود وموسّط بدل ما تبصط على الشاشة.
          ResponsiveCenter(
            maxWidth: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── الوضع الغامق ───
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    return Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title:
                            Text(s.darkMode, style: AppTextStyles.body(context)),
                        value: themeState.mode == ThemeMode.dark,
                        onChanged: (_) => context.read<ThemeCubit>().toggle(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ─── اللغة ───
                BlocBuilder<LocaleCubit, LocaleState>(
                  builder: (context, localeState) {
                    return Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.language),
                                const SizedBox(width: 16),
                                Text(s.language,
                                    style: AppTextStyles.body(context)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'ar',
                                  label: Text(s.arabic),
                                  icon: const Icon(Icons.translate),
                                ),
                                ButtonSegment(
                                  value: 'en',
                                  label: Text(s.english),
                                  icon: const Icon(Icons.abc),
                                ),
                              ],
                              selected: {localeState.languageCode},
                              onSelectionChanged: (selection) {
                                context
                                    .read<LocaleCubit>()
                                    .setLanguage(selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ─── شارة أوفلاين + الخصوصية ───
                Center(
                  child: Chip(
                    avatar: Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(s.offlineBadge),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.privacyNote,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.hint(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
