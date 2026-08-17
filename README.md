# TripCost

TripCost 是旅行真实消费成本助手的开发代号。当前工程已完成 M5：Flutter 主应用仅启用 iOS，最低 iOS 15；已具备精确金额、Drift schema v3、Frankfurter v2 与离线汇率链路、快速换算、支付成本与 DCC，以及行程 CRUD、预算仪表盘、消费账本、实际入账和本地费用校准。历史汇率与支付规则均以快照随消费保存。

## 本地启动

```bash
flutter pub get
flutter gen-l10n
flutter test
flutter run -d <ios-simulator-id>
```

环境参数通过 `--dart-define` 注入：

```bash
flutter run \
  --dart-define=APP_FLAVOR=development \
  --dart-define=API_BASE_URL=https://api.frankfurter.dev
```

## 生成 Pigeon 契约

```bash
./tool/generate_pigeon.sh
```

提交 schema 与 Dart/Swift 生成产物。正式名称、Bundle ID、App Group、CloudKit Container 和 Team 尚未冻结，规则见 `docs/IOS_CAPABILITIES.md`。

## 生成数据库代码与 schema

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump \
  lib/core/storage/database/app_database.dart \
  drift_schemas/
dart run drift_dev schema generate \
  drift_schemas/ \
  test/generated_migrations/
```

每次提升 `AppDatabase.schemaVersion` 时同时提交新 schema 导出、显式升级步骤和旧版本迁移测试。

## 汇率网络冒烟

默认测试不会访问公网。需要单独验证 Frankfurter v2 的币种、批量和历史接口时运行：

```bash
RUN_FRANKFURTER_SMOKE=1 \
  flutter test test/core/rates/data/frankfurter_live_smoke_test.dart
```

连接类型只用于执行“仅 Wi-Fi”策略，不能证明互联网一定可用；实际请求仍通过超时、错误映射、缓存回退和指数退避处理失败。
