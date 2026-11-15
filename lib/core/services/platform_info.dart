// معلومات المنصة — شرطي بين الويب والـ IO.
// الاستخدام: `import 'platform_info.dart';` و يشتغل على كل المنصات.
export 'platform_info_stub.dart'
    if (dart.library.io) 'platform_info_real.dart';
