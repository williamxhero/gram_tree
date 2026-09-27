/// 用户协议和隐私政策的当前版本。
///
/// 改版时：提高这里的版本号，在 [privacyChangeLog] 里写一句用户看得懂的变更摘要，
/// 同步更新服务端 `gramtree/legal/router.py` 的正文。已同意旧版本的用户下次打开会先看到变更摘要、
/// 重新同意后才能继续。
const termsVersion = 'v1';
const privacyVersion = 'v1';

/// “产品改进统计”开关本身的版本（不是隐私政策的版本）。改了采集范围就提高这个版本号。
const productAnalyticsVersion = 'v1';

/// 每个版本相对上一版改了什么（给已同意旧版的用户看）。
const privacyChangeLog = <String, List<String>>{
  // 'v2': ['新增：……', '修改：……'],
};

/// 同意记录的类型，和服务端 ConsentRecord.kind 一致。
enum ConsentKind {
  terms('terms'),
  privacy('privacy'),
  sensitivePersonalInfo('sensitive_personal_info'),
  productAnalytics('product_analytics');

  const ConsentKind(this.value);

  final String value;

  static ConsentKind parse(String value) =>
      values.firstWhere((k) => k.value == value);
}

/// 静态网页地址（服务端提供）。
String legalUrl(String apiBaseUrl, String doc) => '$apiBaseUrl/legal/$doc.html';
