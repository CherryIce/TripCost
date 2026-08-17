# iOS 标识符与平台能力清单

> M1 使用无签名能力的开发占位值。正式值必须通过构建配置替换，源码不保存证书、描述文件或密钥。

## 可替换标识符

| 项目 | 开发占位 | 发布前动作 |
| --- | --- | --- |
| App 展示名 | TripCost | 冻结正式中英文名称并更新 InfoPlist.strings/商店元数据 |
| Runner Bundle ID | `dev.tripcost.app` | 在 Apple Developer Portal 注册正式 ID |
| Widget Bundle ID | `dev.tripcost.app.widget` | 作为 Runner 相关扩展注册 |
| App Group | `group.dev.tripcost.app` | Runner 与 Widget 同时启用正式 Group |
| CloudKit Container | `iCloud.dev.tripcost.app` | 创建正式容器并绑定 Runner |
| Development Team | 空 | 由本地/CI 的 xcconfig 或签名设置注入 |

占位标识符集中放在 `ios/Config/Identifiers.xcconfig`，业务 Dart、路由、数据库表名和 Pigeon 契约不得读取或硬编码这些值；配置键使用通用 `APP_*`，便于正式改名。

## Target 与最低系统

- Runner：iOS 15.0。
- AppWidget：iOS 15.0，SwiftUI + WidgetKit，不链接 Flutter Engine，不访问 Drift 数据库。
- RunnerTests / 后续原生测试 Target：iOS 15.0。

## Apple Developer Portal 后续准备

1. 注册正式 Runner 与 Widget App ID。
2. 创建 App Group，并同时分配给 Runner/Widget profiles。
3. 为 Runner 启用 iCloud/CloudKit，创建 production/development container；Widget 不直接访问 CloudKit。
4. 为 Runner 添加相机、相册用途文案；仅在对应功能实际触发时请求权限。
5. 生成 Development/Distribution profiles；密钥只进入 Keychain 或 CI secret store。
6. 在 TC-071 前确认 CloudKit environment、record zone、subscriptions 和迁移流程。

## 当前 M1 能力边界

- Pigeon 和 Widget 只建立可编译骨架。
- M1 不启用真实 App Group、iCloud entitlement 或签名依赖，避免占位标识符污染开发者账户。
- 真正的 Widget 共享、OCR 与 CloudKit 行为分别在 TC-060、TC-071、TC-072 验收。
