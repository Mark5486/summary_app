import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String? detail;
  const Failure([this.detail]);

  @override
  List<Object?> get props => [detail];
}

class InputTooShortFailure extends Failure {
  const InputTooShortFailure([super.detail]);
}

class InvalidFileFailure extends Failure {
  const InvalidFileFailure([super.detail]);
}

class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure([super.detail]);
}

class PdfOpenFailure extends Failure {
  const PdfOpenFailure([super.detail]);
}

class FilePickCancelledFailure extends Failure {
  const FilePickCancelledFailure();
}

class NoTextFoundFailure extends Failure {
  const NoTextFoundFailure([super.detail]);
}

class RecognitionFailure extends Failure {
  const RecognitionFailure([super.detail]);
}

class StorageFailure extends Failure {
  const StorageFailure([super.detail]);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.detail]);
}
