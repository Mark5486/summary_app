import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/summary_model.dart';
import '../repositories/history_repository.dart';

class SaveSummaryUseCase {
  final HistoryRepository repository;

  const SaveSummaryUseCase(this.repository);

  Future<Either<Failure, void>> call(SummaryModel model) async {
    try {
      await repository.save(model);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

class GetHistoryUseCase {
  final HistoryRepository repository;

  const GetHistoryUseCase(this.repository);

  Future<Either<Failure, List<SummaryModel>>> call() async {
    try {
      return Right(await repository.getAll());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

class GetLatestSummaryUseCase {
  final HistoryRepository repository;

  const GetLatestSummaryUseCase(this.repository);

  Future<Either<Failure, SummaryModel?>> call() async {
    try {
      return Right(await repository.latest());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

class DeleteSummaryUseCase {
  final HistoryRepository repository;

  const DeleteSummaryUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    try {
      await repository.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}

class ClearHistoryUseCase {
  final HistoryRepository repository;

  const ClearHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    try {
      await repository.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
