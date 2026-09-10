import 'package:stmini_flutter/stmini_flutter.dart';

const kifxMiniDownloadUrl =
    'https://site.761242.com/maple/v1/static/'
    '20260908_018ee521a82c8c4edb72c8d9f2a2b18157.zip';
const kifxMiniVersion = '2.0.0';
const kifxHostPackageName = 'com.tripcost.lite';

final kifxMiniLink = Uri(
  scheme: 'mini',
  host: 'kifx',
  queryParameters: const <String, String>{
    'downloadUrl': kifxMiniDownloadUrl,
    'currentVersion': kifxMiniVersion,
    'minSupportVersion': kifxMiniVersion,
    'miniName': 'KIFX',
    'miniNameEn': 'KIFX',
  },
).toString();

Future<void> launchKifxMini() async {
  await StminiFlutter.initialize(
    bridgeContext: const <String, Object?>{'packageName': kifxHostPackageName},
  );
  await StminiFlutter.openMini(kifxMiniLink);
}
