import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/errors/exceptions.dart';
import 'package:besbasa/core/summarizer/arabic_normalizer.dart';
import 'package:besbasa/core/summarizer/extractive_summarizer.dart';
import 'package:besbasa/core/summarizer/sentence_splitter.dart';
import 'package:besbasa/core/summarizer/stopwords.dart';

void main() {
  group('ArabicNormalizer', () {
    test('بيوحد أشكال الألف والهمزات', () {
      expect(ArabicNormalizer.normalizeWord('أحمد'), 'احمد');
      expect(ArabicNormalizer.normalizeWord('إبراهيم'), 'ابراهيم');
      expect(ArabicNormalizer.normalizeWord('آمن'), 'امن');
    });

    test('بيوحّد التاء المربوطة والألف المقصورة', () {
      expect(ArabicNormalizer.normalizeWord('مدرسة'), 'مدرسه');
      expect(ArabicNormalizer.normalizeWord('مستشفى'), 'مستشفي');
    });

    test('بيشيل التشكيل والتطويل', () {
      expect(ArabicNormalizer.normalizeWord('مُحَمَّـد'), 'محمد');
    });

    test('النص المطبع بيحافظ على السطور وبيمسح الترقيم', () {
      final out = ArabicNormalizer.normalizeText('مرحباً، بك!\n\nفي التطبيق');
      expect(out.contains('\n\n'), isTrue);
      expect(out.contains('،'), isFalse);
      expect(out.contains('!'), isFalse);
    });

    test('التشكيل بيتشال من غير ما الحروف تتفكك (إِنَّ مش بتتقطع)', () {
      final out = ArabicNormalizer.normalizeText('إِنَّ الْعِلْمَ نُورٌ');
      expect(out, 'إن العلم نور');
    });
  });

  group('Stopwords', () {
    test('كلمات التوقف العربية المطبعّة بتتصاد', () {
      expect(Stopwords.isStopword('في'), isTrue);
      expect(Stopwords.isStopword('التي'), isTrue);

      expect(Stopwords.isStopword('علي'), isTrue);
    });

    test('كلمات المحتوى مش بتتصاد', () {
      expect(Stopwords.isStopword('النيل'), isFalse);
      expect(Stopwords.isStopword('photosynthesis'), isFalse);
    });

    test('الكلمات الإنجليزية بتتصاد بأي حالة', () {
      expect(Stopwords.isStopword('The'), isTrue);
      expect(Stopwords.isStopword('AND'), isTrue);
    });
  });

  group('SentenceSplitter', () {
    test('بيقسم على النقطة وعلامة الاستفهام العربية', () {
      final text =
          'هذه جملة أولى طويلة بما يكفي لتتحسب جملة صحيحة هنا. وهذه جملة تانية '
          'طويلة أيضا بما يكفي للاحتساب الصحيح؟ وجملة ثالثة كذلك طويلة بما يكفي '
          'عشان تتحسب برضه هنا.';
      final sentences = SentenceSplitter.split(text);
      expect(sentences.length, 3);
    });

    test('بيقسم على السطور الجديدة كذلك', () {
      final text =
          'سطر أول طويل بما يكفي ليتم احتسابه جملة كاملة صحيحة\n'
          'وسطر تاني طويل برضه بما يكفي عشان يتحسب جملة تانية صحيحة';
      final sentences = SentenceSplitter.split(text);
      expect(sentences.length, 2);
    });

    test('الجمل القصيرة بتنمسك وبترجع قايمة فاضية للنص الفاضي', () {
      expect(SentenceSplitter.split('قصير. جدا. لا.'), isEmpty);
      expect(SentenceSplitter.split(''), isEmpty);
    });

    test('بيحافظ على ترتيب الجمل بالمؤشر', () {
      final text =
          'الجملة الأولى هنا طويلة كفاية عشان تتحسب جملة صحيحة. '
          'والجملة التانية كذلك طويلة كفاية عشان تتحسب كمان جملة صحيحة.';
      final sentences = SentenceSplitter.split(text);
      expect(sentences[0].index, 0);
      expect(sentences[1].index, 1);
    });

    test('الجملة بتحتفظ بنصها الأصلي (تشكيل) للعرض — مش نسخة مطبّعة', () {
      final sentences = SentenceSplitter.split(
        'إِنَّ الْعِلْمَ نُورٌ يُضِيءُ دَرْبَ الْمُتَعَلِّمِ فِي كُلِّ الأَحْوَالِ.',
      );
      expect(sentences, isNotEmpty);

      expect(sentences.first.text.contains('إِنَّ'), isTrue);
      expect(sentences.first.text.contains('إ ن'), isFalse);

      expect(sentences.first.normalizedWords.first, 'ان');
    });

    test("النص الإنجليزي ببيّن علاماته في العرض (Don't و 3.5%)", () {
      final sentences = SentenceSplitter.split(
        "Don't stop believing in yourself, ever. Growth reached 3.5% this "
        'year, which beat every forecast published by the team last spring.',
      );
      expect(sentences.length, 2);
      expect(sentences[0].text.contains("Don't"), isTrue);
      expect(sentences[0].text.contains('Don t'), isFalse);
      expect(sentences[1].text.contains('3.5%'), isTrue);
      expect(sentences[1].text.contains('3 5'), isFalse);
    });
  });

  group('ExtractiveSummarizer — عربي', () {
    const arabicText =
        'نهر النيل هو أطول نهر في العالم ويمر عبر إحدى عشرة '
        'دولة أفريقية قبل أن يصل إلى البحر المتوسط. يعتمد مصر والسودان على '
        'مياه النيل في الزراعة والشرب بشكل شبه كامل. توجد اتفاقيات تاريخية '
        'تنظم تقاسم مياه النيل بين دول الحوض. السد العالي في أسوان يحمي مصر '
        'من الفيضانات ويخزن المياه للزراعة الصيفية. تعدد مصادر النيل أهمها '
        'النيل الأبيض والنيل الأزرق الذي يلتقيان في الخرطوم عاصمة السودان. '
        'الدلتا شمال مصر هي أخصب أراضي الزراعة بسبب طمي النيل العريق. '
        'ملوثات النيل بقت مشكلة بيئية كبيرة في السنين الأخيرة وتحتاج حلول '
        'عاجلة. تلوث مياه النيل بيأثر على الأسماك والزراعة وصحة الملايين. '
        'مشروعات التنمية الحديثة بتحاول تحسّن جودة مياه النيل وتنظيفه من '
        'المخلفات الصناعية والزراعية المختلفة في كل الفروع.';

    test('بيطلع نقاط قليلة ومن 1 لـ 5', () {
      final result = ExtractiveSummarizer.summarize(arabicText);
      expect(result.points, isNotEmpty);
      expect(result.points.length, lessThanOrEqualTo(5));
      expect(result.points.length, greaterThanOrEqualTo(1));
    });

    test('الشرح المبسط مش فاضي وفيه كلمات مفتاحية', () {
      final result = ExtractiveSummarizer.summarize(arabicText);
      expect(result.explanation, isNotEmpty);
      expect(result.keywords, isNotEmpty);

      expect(result.keywords.contains('النيل'), isTrue);
    });

    test('النقاط مرتّبة على ترتيب ظهورها في الأصل', () {
      final result = ExtractiveSummarizer.summarize(arabicText);
      final positions = result.points.map(arabicText.indexOf).toList();
      final sorted = [...positions]..sort();
      expect(positions, sorted);
    });

    test('نسبة الاختصار بين 0 و 1 والملخص أقصر من الأصل', () {
      final result = ExtractiveSummarizer.summarize(arabicText);
      expect(result.compressionRatio, greaterThanOrEqualTo(0));
      expect(result.compressionRatio, lessThanOrEqualTo(1));
      expect(result.summaryWordCount, lessThan(result.originalWordCount));
    });

    test('النص القصير بيرمي InputTooShortException', () {
      expect(
        () => ExtractiveSummarizer.summarize('جملة قصيرة أوي خالص.'),
        throwsA(isA<InputTooShortException>()),
      );
    });
  });

  group('ExtractiveSummarizer — إنجليزي', () {
    const englishText =
        'Photosynthesis is the process plants use to convert '
        'light energy into chemical energy stored in glucose molecules. The '
        'process happens inside chloroplasts which contain the green pigment '
        'chlorophyll that absorbs sunlight. Water and carbon dioxide are the '
        'raw materials while oxygen is released as a byproduct of the '
        'reaction. Light dependent reactions occur in the thylakoid '
        'membranes and produce ATP energy carriers for the cell. The Calvin '
        'cycle happens in the stroma and fixes carbon dioxide into sugars. '
        'Farmers optimize photosynthesis through proper lighting irrigation '
        'and carbon dioxide enrichment in greenhouses. Understanding '
        'photosynthesis helps scientists improve crop yields worldwide. '
        'Climate change affects photosynthesis rates in forests and oceans '
        'significantly every single year across many ecosystems.';

    test('بيطلع نقاط وكلمات مفتاحية إنجليزية', () {
      final result = ExtractiveSummarizer.summarize(englishText);
      expect(result.points, isNotEmpty);
      expect(result.keywords, isNotEmpty);
      expect(result.keywords.contains('photosynthesis'), isTrue);
    });

    test('الشرح بيتكتب إنجليزي للنص الإنجليزي', () {
      final result = ExtractiveSummarizer.summarize(englishText);
      expect(result.explanation, contains('main idea'));
      expect(result.explanation.contains('الفكرة'), isFalse);
    });
  });

  group('ExtractiveSummarizer — النص الأصلي للعرض', () {
    const diacriticText =
        'إِنَّ الْعِلْمَ نُورٌ يُزِيلُ ظُلُمَاتِ الْجَهْلِ، '
        'وَالْعِلْمُ سِلَاحٌ قَوِيٌّ يَحْمِي صَاحِبَهُ فِي كُلِّ زَمَانٍ. '
        'طَلَبُ الْعِلْمِ عِبَادَةٌ تُقَرِّبُ الْإِنْسَانَ مِنْ رَبِّهِ، '
        'وَالْمُعَلِّمُ الْأَمِينُ يَبْنِي أَجْيَالًا تَقْرَأُ وَتَفْكِرُ. '
        'الْكِتَابُ الْجَيِّدُ صَدِيقٌ أَمِينٌ لَا يَمْنَعُ عِلْمَهُ عَمَّنْ '
        'سَأَلَهُ يَوْمًا مَا.';

    const englishSignedText =
        "Don't underestimate the power of small daily "
        'habits, because they compound into remarkable results over time. '
        'Growth reached 3.5% this year, which beat every forecast that the '
        'analysts published last spring. Reading one chapter each night '
        'keeps your mind sharp and your vocabulary steadily expanding. '
        'Small wins build momentum, and momentum builds confidence for '
        'bigger challenges ahead. Consistency beats intensity almost every '
        'single time, whether you are training or studying.';

    test('كل نقطة موجودة حرفيًا في النص الأصلي — عربي متشكّل', () {
      final result = ExtractiveSummarizer.summarize(diacriticText);
      expect(result.points, isNotEmpty);
      for (final p in result.points) {
        expect(
          diacriticText.contains(p),
          isTrue,
          reason: 'النقطة اتعملها تطبيع قبل العرض: $p',
        );
      }

      expect(result.points.join(' ').contains('إ ن'), isFalse);
    });

    test('كل نقطة موجودة حرفيًا في النص الأصلي — إنجليزي بعلامات', () {
      final result = ExtractiveSummarizer.summarize(englishSignedText);
      // ignore: avoid_print
      print('ORIGINAL TEXT: $englishSignedText');
      // ignore: avoid_print
      print('SUMMARY POINTS: ${result.points}');
      expect(result.points, isNotEmpty);
      for (final p in result.points) {
        expect(
          englishSignedText.contains(p),
          isTrue,
          reason: 'Original text does not contain this point: "$p"',
        );
      }
      expect(result.points.join(' ').contains("Don't"), isTrue);
      expect(result.points.join(' ').contains('3.5%'), isTrue);
    });
  });
}
