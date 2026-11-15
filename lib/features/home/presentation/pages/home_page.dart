import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../history/presentation/cubit/history_cubit.dart';
import '../../../history/presentation/view/history_view.dart';
import '../../../settings/presentation/view/settings_view.dart';
import '../../../summarize/presentation/cubit/summarize_cubit.dart';
import '../../../summarize/presentation/view/summarize_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _selectTab(BuildContext context, int i) {
    setState(() => _index = i);

    if (i == 1) context.read<HistoryCubit>().load();
  }

  List<NavigationRailDestination> _railDestinations(AppStrings s) => [
    NavigationRailDestination(
      icon: const Icon(Icons.auto_stories_outlined),
      selectedIcon: const Icon(Icons.auto_stories),
      label: Text(s.tabSummarize),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history),
      label: Text(s.tabHistory),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: Text(s.tabSettings),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SummarizeCubit>(
          create: (_) {
            final cubit = getIt<SummarizeCubit>();

            cubit.restoreLastSummary();
            return cubit;
          },
        ),
        BlocProvider<HistoryCubit>(
          create: (_) => getIt<HistoryCubit>()..load(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final tabs = IndexedStack(
            index: _index,
            children: const [SummarizeView(), HistoryView(), SettingsView()],
          );

          if (context.isExpanded) {
            final width = context.screenWidth;
            final extended = width >= 1400;
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => _selectTab(context, i),

                    extended: extended,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: _railDestinations(s),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: tabs),
                ],
              ),
            );
          }

          return Scaffold(
            body: tabs,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => _selectTab(context, i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: s.tabSummarize,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history),
                  label: s.tabHistory,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: s.tabSettings,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
