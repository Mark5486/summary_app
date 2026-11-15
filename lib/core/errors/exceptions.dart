sealed class BesbasaException implements Exception {
  const BesbasaException();
}

class InputTooShortException extends BesbasaException {
  const InputTooShortException();
}

class InvalidFileException extends BesbasaException {
  const InvalidFileException();
}

class FileTooLargeException extends BesbasaException {
  const FileTooLargeException();
}

class PdfOpenException extends BesbasaException {
  final String? detail;
  const PdfOpenException([this.detail]);
}

class FilePickCancelledException extends BesbasaException {
  const FilePickCancelledException();
}

class NoTextFoundException extends BesbasaException {
  const NoTextFoundException();
}

class RecognitionException extends BesbasaException {
  final String? detail;
  const RecognitionException([this.detail]);
}
