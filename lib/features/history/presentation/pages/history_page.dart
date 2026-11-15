import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/service_locator.dart';
import '../cubit/history_cubit.dart';
import '../view/history_view.dart';

/// صفحة السجل المستقلة (للراوتر) — بتملك الـ Cubit بتاعها.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => getIt<HistoryCubit>()..load(),
      child: const HistoryView(),
    );
  }
}
