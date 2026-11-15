import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/features/history/data/models/summary_model.dart';

SummaryModel _sample() => const SummaryModel(
  id: 'abc-123',
  createdAtMs: 1730000000000,
  originalText: 'نص أصلي طويل عن النيل والدلتا والزراعة في مصر القديمة',
  points: ['النيل أهم نهر في مصر', 'الدلتا أخصب أرض'],
  explanation: 'الفكرة: النيل والدلتا',
  keywords: ['النيل', 'الدلتا'],
  originalWordCount: 100,
  summaryWordCount: 12,
);

void main() {
  group('SummaryModel', () {
    test('JSON roundtrip بيحفظ ويرجّع نفس القيم', () {
      final model = _sample();
      final json = model.toJson();
      final restored = SummaryModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.createdAtMs, model.createdAtMs);
      expect(restored.originalText, model.originalText);
      expect(restored.points, model.points);
      expect(restored.explanation, model.explanation);
      expect(restored.keywords, model.keywords);
      expect(restored.originalWordCount, model.originalWordCount);
      expect(restored.summaryWordCount, model.summaryWordCount);
    });

    test('fromJson بيتعامل مع الحقول الناقصة من غير ما يقع', () {
      final restored = SummaryModel.fromJson({'id': 'x', 'createdAtMs': 42});
      expect(restored.originalText, '');
      expect(restored.points, isEmpty);
      expect(restored.keywords, isEmpty);
      expect(restored.originalWordCount, 0);
    });

    group('matches (البحث)', () {
      test('بيلاقي الكلمة في الأصل', () {
        expect(_sample().matches('النيل'), isTrue);
      });

      test('بيلاقي الكلمة في النقاط', () {
        expect(_sample().matches('أخصب'), isTrue);
      });

      test('بيلاقي الكلمة في الشرح', () {
        expect(_sample().matches('الفكرة'), isTrue);
      });

      test('الكلمة الغريبة مش بتلاقي حاجة', () {
        expect(_sample().matches('كوكب الزهرة'), isFalse);
      });

      test('البحث الفاضي بيرجّع الكل', () {
        expect(_sample().matches(''), isTrue);
        expect(_sample().matches('   '), isTrue);
      });

      test('البحث مش حساس لحالة الأحرف الإنجليزية', () {
        const model = SummaryModel(
          id: 'e',
          createdAtMs: 1,
          originalText: 'The Nile River',
          points: [],
          explanation: '',
          keywords: [],
          originalWordCount: 3,
          summaryWordCount: 0,
        );
        expect(model.matches('nile'), isTrue);
        expect(model.matches('NILE'), isTrue);
      });
    });
  });
}
