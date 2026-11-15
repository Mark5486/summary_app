import '../localization/app_strings.dart';
import '../errors/failures.dart';

String failureToMessage(Failure failure, AppStrings s) {
  switch (failure) {
    case InputTooShortFailure():
      return s.inputTooShort;
    case InvalidFileFailure():
      return s.invalidFile;
    case FileTooLargeFailure():
      return s.fileTooLarge;
    case PdfOpenFailure():
      return s.pdfOpenFailed;
    case FilePickCancelledFailure():
      return s.filePickCancelled;
    case NoTextFoundFailure():
      return s.noTextFound;
    case RecognitionFailure():
      return s.recognitionFailed;
    case StorageFailure():
      return s.unexpected;
    case UnexpectedFailure():
      return s.unexpected;
  }
}
