import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/history/data/datasources/history_local_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/history_usecases.dart';
import '../../features/history/presentation/cubit/history_cubit.dart';
import '../../features/summarize/data/repositories/summarize_repository_impl.dart';
import '../../features/summarize/domain/repositories/summarize_repository.dart';
import '../../features/summarize/domain/usecases/summarize_usecases.dart';
import '../../features/summarize/presentation/cubit/summarize_cubit.dart';
import '../localization/cubit/locale_cubit.dart';
import '../services/file_text_service.dart';
import '../services/local_storage_service.dart';
import '../services/navigation_service.dart';
import '../services/ocr/text_recognition_factory.dart';
import '../services/ocr/text_recognition_service.dart';
import '../theme/cubit/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final preferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(preferences),
  );
  getIt.registerLazySingleton<NavigationService>(() => NavigationServiceImpl());

  getIt.registerLazySingleton<FileTextService>(() => FileTextServiceImpl());
  getIt.registerLazySingleton<TextRecognitionService>(
    createTextRecognitionService,
  );

  getIt.registerLazySingleton<HistoryLocalDataSource>(
    () => HistoryLocalDataSourceImpl(getIt<LocalStorageService>()),
  );
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(getIt<HistoryLocalDataSource>()),
  );
  getIt.registerLazySingleton<SaveSummaryUseCase>(
    () => SaveSummaryUseCase(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<GetHistoryUseCase>(
    () => GetHistoryUseCase(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<GetLatestSummaryUseCase>(
    () => GetLatestSummaryUseCase(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<DeleteSummaryUseCase>(
    () => DeleteSummaryUseCase(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<ClearHistoryUseCase>(
    () => ClearHistoryUseCase(getIt<HistoryRepository>()),
  );

  getIt.registerLazySingleton<SummarizeRepository>(
    () => SummarizeRepositoryImpl(
      fileTextService: getIt<FileTextService>(),
      recognitionService: getIt<TextRecognitionService>(),
    ),
  );
  getIt.registerLazySingleton<SummarizeTextUseCase>(
    () => SummarizeTextUseCase(getIt<SummarizeRepository>()),
  );
  getIt.registerLazySingleton<ExtractTextFromFileUseCase>(
    () => ExtractTextFromFileUseCase(getIt<SummarizeRepository>()),
  );
  getIt.registerLazySingleton<ExtractTextFromImageUseCase>(
    () => ExtractTextFromImageUseCase(getIt<SummarizeRepository>()),
  );
  getIt.registerLazySingleton<ExtractOcrFromScannedPdfUseCase>(
    () => ExtractOcrFromScannedPdfUseCase(getIt<SummarizeRepository>()),
  );

  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(getIt<LocalStorageService>()),
  );
  getIt.registerFactory<LocaleCubit>(
    () => LocaleCubit(getIt<LocalStorageService>()),
  );
  getIt.registerFactory<SummarizeCubit>(
    () => SummarizeCubit(
      summarizeUseCase: getIt<SummarizeTextUseCase>(),
      extractFromFileUseCase: getIt<ExtractTextFromFileUseCase>(),
      extractFromImageUseCase: getIt<ExtractTextFromImageUseCase>(),
      ocrScannedPdfUseCase: getIt<ExtractOcrFromScannedPdfUseCase>(),
      saveSummaryUseCase: getIt<SaveSummaryUseCase>(),
      getLatestSummaryUseCase: getIt<GetLatestSummaryUseCase>(),
    ),
  );
  getIt.registerFactory<HistoryCubit>(
    () => HistoryCubit(
      getHistoryUseCase: getIt<GetHistoryUseCase>(),
      deleteSummaryUseCase: getIt<DeleteSummaryUseCase>(),
      clearHistoryUseCase: getIt<ClearHistoryUseCase>(),
    ),
  );
}
