import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_routes.dart';
import 'core/localization/cubit/locale_cubit.dart';
import 'core/localization/cubit/locale_state.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/theme/cubit/theme_state.dart';
import 'core/utils/service_locator.dart';
import 'core/widgets/app_scroll_behavior.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupServiceLocator();

  final themeCubit = getIt<ThemeCubit>();
  final localeCubit = getIt<LocaleCubit>();
  await themeCubit.ensureLoaded();
  await localeCubit.ensureLoaded();

  runApp(BesbasaApp(themeCubit: themeCubit, localeCubit: localeCubit));
}

class BesbasaApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  final LocaleCubit localeCubit;

  const BesbasaApp({
    super.key,
    required this.themeCubit,
    required this.localeCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<LocaleCubit>.value(value: localeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
                title: 'ببساطة',
                debugShowCheckedModeBanner: false,

                scrollBehavior: const AppScrollBehavior(),

                locale: Locale(localeState.languageCode),
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                theme: LightTheme.theme,
                darkTheme: DarkTheme.theme,
                themeMode: themeState.mode,

                initialRoute: AppRoutes.initial,
                onGenerateRoute: AppRouter.onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
