# Future Invest H5 Embedded 构建与原生桥接手册

> 最后核对：2026-08-21  
> H5 源码工程：`/Users/starburst/Desktop/H5-app-develop`  
> Flutter 内嵌资源：`assets/future_invest_h5/`

## 1. 目的与边界

本文固化 Future Invest H5 在 TripCost iOS 容器中的专用构建、资源同步、WebView 加载和 JSBridge 约定，作为后续升级和排障的事实基线。

本方案负责：

- 从 H5 源码生成 iOS 15+ 使用的 Embedded 专用包。
- 控制总体积、JS、首屏声明资源、字体和二级页脚本预算。
- 生成版本号、逐文件 SHA-256、整包 SHA-256，并校验后原子同步到 Flutter。
- 通过 App 内回环 HTTP 服务向 `WKWebView` 提供正确的 URL、MIME 和缓存策略。
- 实现约定的 `CMSScriptMessageChannel` 请求、回调和原生返回语义。

本方案不负责：

- 修复远端第三方或独立 H5 页面自己的 History、布局、Safe Area、返回按钮等适配问题。
- 保证离线登录、行情、交易、图片或 WebSocket；Embedded 只把静态资源放进 App。
- 让原生容器自动支持 H5 工程中出现的全部 Bridge 方法。
- 在运行时重新计算 659 个资源文件的 SHA-256；当前完整校验发生在构建和同步阶段。

严禁直接修改 `assets/future_invest_h5/static/js/` 中的一行式压缩文件。它们是带内容哈希的构建产物，任何修复都必须回到 H5 源码后重新构建和同步。

## 2. 当前结果

当前资源版本：`3.10.2-embedded.20260821-065308004Z`  
当前整包 SHA-256：`8bfd4f601a6a6a63e0d2fe0f7920db8b0fe53024969d07edefb1a3a55175c054`

| 指标 | 原始基线（约） | 预算 | 当前实际 | 约降幅 | 结果 |
| --- | ---: | ---: | ---: | ---: | --- |
| 总资源包 | 40 MB | ≤ 20 MiB | 9.64 MiB | 75.9% | 通过 |
| JavaScript | 14.4 MB | ≤ 8 MiB | 6.53 MiB | 54.7% | 通过 |
| legacy JS | 7.5 MB | 0 | 0 | 100% | 通过 |
| 首屏声明资源 | 2.96 MB | ≤ 1.2 MiB | 0.49 MiB | 83.4% | 通过 |
| 字体 | 7.7 MB | ≤ 1.5 MiB | 0 | 100% | 通过 |
| 单个普通二级页脚本 | 未设基线 | ≤ 300 KiB | 最大 130.7 KiB | — | 通过 |

说明：历史基线使用约数 MB，清单按字节和 MiB 计算，因此降幅只用于趋势比较，不应作为财务式精确口径。

当前包共 659 个清单文件、10,103,826 字节。主要类型为：JS 6,842,808 字节、CSS 489,142 字节、PNG 1,885,124 字节、SVG 645,796 字节、WebP 176,166 字节、GIF 62,487 字节。

## 3. 端到端架构

```text
H5 源码
  └─ pnpm build:embedded
       ├─ Vite embedded mode
       ├─ finalize-embedded.mjs
       │    ├─ 清理 PWA/SW/Sitemap
       │    ├─ 复制运行时 env.js
       │    ├─ 检查相对路径与禁止项
       │    └─ version.json + asset-manifest.json + SHA-256 + 预算门禁
       └─ dist-embedded/
            └─ pnpm sync:embedded -- <Flutter 目标目录>
                 ├─ 同步前校验
                 ├─ 临时目录复制并再次校验
                 └─ 原子替换 assets/future_invest_h5/
                      └─ FutureInvestAssetServer
                           └─ http://127.0.0.1:<随机端口>/index.html
                                └─ WKWebView + CMSScriptMessageChannel
```

这条链路只允许从源码到产物单向生成。不要把 Flutter 内嵌目录里的哈希文件反向当作源码维护。

## 4. Embedded 专用构建

### 4.1 构建入口

H5 工程 `package.json` 中的入口为：

```json
{
  "build:embedded": "vue-tsc --noEmit && vite build --mode embedded && cross-env EMBEDDED_BUDGET_STRICT=1 node scripts/finalize-embedded.mjs",
  "sync:embedded": "node scripts/sync-embedded.mjs"
}
```

先做 TypeScript 类型检查，再构建，最后整理产物并以严格模式执行预算门禁；任何预算失败都会让命令失败。

### 4.2 兼容性和路由

- Embedded 模式使用 `base: './'`，所有入口和静态资源必须是相对路径。
- Vue Router 保留 `createWebHashHistory(...)`，避免 App 内本地资源依赖服务器回写路由。
- 构建目标为 `safari15`，与最低 iOS 15.0 契约一致。
- Embedded 模式关闭 `modulePreload`，不把二级依赖提前声明进首屏。
- Embedded 模式不启用 `@vitejs/plugin-legacy`，因此不生成 `nomodule` 或 `*-legacy-*`。
- JS 使用 Terser 压缩，并移除 `console` 和 `debugger`。

### 4.3 分包和首屏依赖

- 文件路由由 `unplugin-vue-router` 生成异步页面块；Embedded 模式关闭业务路由预取。
- 图表组件使用 `await import('echarts')`，`echarts`/`zrender` 进入 `vendor-charts`，只有进入图表页面才加载。
- Firebase 功能代码和 Firebase SDK 分别进入 `feature-firebase`、`vendor-firebase`。
- Embedded 入口把 `@/utils/firebaseSession` 指向无 Firebase SDK 的 `firebaseSession.embedded.ts`，避免登录初始化把 Firebase 拉入首屏。
- 交易页面保留路由分块；Embedded 启动时不预取图表、Firebase 和交易路由。
- 多语言使用动态导入。当前语言及其 Vant 语言包在挂载前加载，其他语言文件仍在资源包内，但不属于首屏声明依赖。
- Vue、Pinia、Vue Router 进入 `vendor-core`；Vant 进入独立 UI vendor 块。

不要只看某个 chunk 文件是否存在来判断它进入了首屏。首屏口径以 `index.html` 直接声明的 `<script>`、`modulepreload` 和 stylesheet 为准。

### 4.4 字体和图片

- Embedded 输出不再携带 `SourceHanSansCN` 字体，当前字体字节数为 0。
- 中文优先使用系统字体栈：`-apple-system`、`BlinkMacSystemFont`、`SF Pro Text`、`PingFang SC`、`Hiragino Sans GB`、`Microsoft YaHei`、`sans-serif`。
- 源码中即使仍保留字体原文件，也必须确认它没有被 CSS 引用并进入最终清单。
- 大图按真实展示尺寸重新导出 WebP，再修改源码引用。例如：
  - `guest_hero.png`：1024×1536、682,484 字节；`guest_hero.webp`：570×855、45,778 字节。
  - 分享海报插画 PNG：1254×1254、单张约 1.8–2.0 MB；WebP：400×400、单张约 17–20 KB。
- 当前只是把已确认的大图换成 WebP，不代表所有 PNG 都应机械转换。透明度、文字锐度和视觉验收仍需逐张确认。

### 4.5 Embedded 无效资源清理

Embedded 模式不注册或生成以下 Web 站点能力：

- PWA manifest、PWA icons。
- Service Worker、Workbox、Firebase Messaging Service Worker。
- Sitemap、robots、站点 favicon、Safari pinned tab。
- mock server、Vue DevTools。

`finalize-embedded.mjs` 会再次删除残留文件，并拒绝以下入口内容：legacy bundle、PWA manifest、Service Worker 注册、Sitemap、根绝对路径本地资源。

## 5. 资源清单、版本和同步

### 5.1 `version.json`

格式：

```json
{
  "version": "3.10.2-embedded.20260821-065308004Z",
  "appVersion": "3.10.2",
  "buildId": "20260821-065308004Z"
}
```

`version` 是 H5 版本和 UTC 构建时间的组合，便于判断 App 中实际打包的是哪一版资源。

### 5.2 `asset-manifest.json`

清单记录：

- schema、资源版本、应用版本、构建 ID、生成时间。
- 最低 iOS、`base`、路由类型、入口文件。
- 每个文件的相对路径、字节数、SHA-256。
- 文件总数、总字节数和整包 SHA-256。
- 五项预算的实际值、目标值和通过状态。

整包 SHA-256 不是简单拼接文件内容，而是先按排序后的文件记录生成：

```text
path + NUL + bytes + NUL + fileSha256 + LF
```

再对全部记录计算 SHA-256。这样路径、文件大小或内容任一变化都会改变整包摘要。

### 5.3 原子同步

`sync-embedded.mjs` 的顺序是：

1. 校验源目录每个文件和整包摘要。
2. 复制到目标同级的 `.next-<pid>` 临时目录。
3. 再次校验临时目录。
4. 把旧目标改名为 `.previous-<pid>`，再把新目录原子改名为正式目标。
5. 失败时恢复旧目录，成功后清理旧目录和临时目录。

脚本拒绝把文件系统根目录、用户目录或 H5 当前工作目录作为目标，并阻止清单路径越界。

### 5.4 防止 App 内嵌旧包

发布检查必须同时记录：

- `version.json.version`。
- `asset-manifest.json.sha256`。
- App 构建号或归档号。

同步脚本保证“写入 Flutter 工程的目录”与清单一致；它不能证明某个旧 IPA 已被用户设备替换。归档前仍需检查 App bundle 中的 `version.json`，安装后如需强证据，应通过调试页面或日志暴露资源版本。

当前回环服务用清单作为允许列表，但不会在每次请求时重新计算文件 SHA。不要把“运行时可读取清单”等同于“运行时完成完整性重验”。

## 6. Flutter / WKWebView 加载

### 6.1 为什么不用 `file://` 或直接 `loadFlutterAsset`

这个包包含 Vite ESM、动态 `import()`、相对 chunk 和运行时环境脚本。直接使用 Flutter asset scheme 或 `file://` 时，iOS WebView 可能遇到模块来源、MIME、相对路径或动态 chunk 解析问题，典型现象是主页面纯白且没有 Flutter UI 错误。

当前实现由 `FutureInvestAssetServer` 绑定 `127.0.0.1` 随机端口，再让 WebView 加载：

```text
http://127.0.0.1:<port>/index.html
```

因此 ESM 获得标准 HTTP origin、正确 MIME 和稳定的相对 URL 语义。此实现已解决本项目早期的本地包空白页问题。

### 6.2 Flutter asset 声明

Flutter asset 目录不能依赖“根目录声明一定递归包含所有普通子目录”的假设。当前 `pubspec.yaml` 明确列出：

```yaml
assets:
  - assets/future_invest_h5/
  - assets/future_invest_h5/polymer/env/
  - assets/future_invest_h5/static/css/
  - assets/future_invest_h5/static/gif/
  - assets/future_invest_h5/static/js/
  - assets/future_invest_h5/static/png/
  - assets/future_invest_h5/static/svg/
  - assets/future_invest_h5/static/webp/
```

新增输出扩展名或目录时，先更新这里，否则源码构建成功也可能在 App 内 404。

### 6.3 本地资源服务行为

- 只接受 `GET`、`HEAD`。
- 只服务 `asset-manifest.json` 声明的路径，未声明路径返回 404。
- 为 HTML、JS、CSS、JSON、SVG、PNG、GIF、WebP 设置明确 MIME。
- 返回 `X-Content-Type-Options: nosniff`。
- `index.html`、`asset-manifest.json`、`version.json` 使用 `no-store`。
- 带内容哈希的静态资源使用一年 `immutable` 缓存。
- WebView 页面销毁时关闭回环服务器。

### 6.4 WebView 初始化顺序

顺序必须保持为：

1. 创建控制器。
2. 开启 JavaScript。
3. 设置背景色。
4. 注册 `CMSScriptMessageChannel`。
5. 注册导航和错误回调。
6. 启动回环服务并加载入口。

桥通道必须先于页面加载注册，否则 H5 启动阶段的 Bridge 调用可能丢失。主 frame 错误显示重试页；加载过程显示原生 loading；页面销毁后不能复用已关闭的资源服务器。

### 6.5 本地资源不等于离线业务

`polymer/env/env.js` 仍提供 H5/API/静态文件/WebSocket 主机、包名和版本等运行时配置。以下能力仍可能联网：

- 预登录、正式登录和鉴权。
- 行情、交易、账户和配置接口。
- 远端 H5 页面、远端图片和客服页面。
- WebSocket 行情。

切换环境时必须单独核对 `env.js`，但不要在通用文档、日志或截图中泄露令牌、用户信息或未公开环境地址。

## 7. H5 与原生 JSBridge 契约

### 7.1 通道和请求

通道名固定为：

```text
CMSScriptMessageChannel
```

H5 请求结构：

```json
{
  "method": "close",
  "params": {
    "count": 1,
    "methodId": "cb_close_1720000000000_1"
  }
}
```

`methodId` 由 H5 生成，格式为 `cb_<method>_<timestamp>_<sequence>`，用于把原生回调匹配到 Promise。

传输差异：

| 环境 | H5 发送方式 |
| --- | --- |
| iOS / WKWebView | `window.webkit.messageHandlers.CMSScriptMessageChannel.postMessage(payload)`，发送对象 |
| Android WebView | `window.CMSScriptMessageChannel.postMessage(JSON.stringify(payload))` |
| iframe 子页 | `window.parent.postMessage(payload, '*')`，配合 ready 握手 |

在 `webview_flutter` iOS 通道中，JavaScript 对象可能以原生 Map 的字符串描述出现，例如：

```text
{method: close, params: {methodId: cb_close_1, count: 2}}
```

因此 Flutter 解析器同时支持标准 JSON、WK Map 描述和 `back`/`close`/`pop` 纯文本别名。不要只写 `jsonDecode` 后假定 iOS 一定传入 JSON 字符串。

### 7.2 原生回调

原生响应结构：

```json
{
  "code": "1",
  "method": "close",
  "methodId": "cb_close_1720000000000_1",
  "data": {}
}
```

- `code` 是字符串：`"1"` 表示成功，`"0"` 表示失败。
- `methodId` 必须原样返回，否则 H5 Promise 无法结束。
- Flutter 优先调用 `window.CMSJsCallBack(payload)`；不存在时调用兼容名 `window.CMSCallJsMessage(payload)`。
- H5 同时把这两个全局函数绑定到同一消息处理器。
- 未支持但格式有效的方法，Flutter 返回 `code: "0"` 和错误信息，避免调用方永久等待。
- 缺少可识别 method 的畸形消息会被忽略。

### 7.3 Flutter 当前支持矩阵

| 方法 | 当前行为 | 备注 |
| --- | --- | --- |
| `back` | WebView 返回 | 支持纯文本或结构化请求 |
| `close` | WebView 返回 | 与现有 H5 `callNative('close')` 对齐 |
| `pop` | WebView 返回 | 兼容别名 |
| 其他方法 | 返回失败回调 | 不代表功能已实现 |

`params.count` 默认为 1，并限制在 1–20：

- `count == 1`：先执行 `canGoBack()`；可返回则 `goBack()`，否则重新加载 Embedded 根入口。
- `count > 1`：只有 `window.history.length > count` 时才执行 `history.go(-count)`；否则回到 Embedded 根入口。
- 同一时刻只处理一个 Bridge 返回请求，避免连续点击重复退栈。

当前实现先回调 H5 成功，再执行页面返回。若将来需要“只有导航成功才回调成功”，必须升级双方协议，不能只改原生一侧的时序。

## 8. H5 内部 iframe Bridge 与原生 Bridge 的区别

H5 的 `useJsBridge.ts` 是顶层 H5 与内部 iframe 的 `window.postMessage` 适配层，不等于 Flutter 已实现同名原生能力。它当前处理的方法包括：

```text
getUserInfo, close, getRiseColor, getConfig, getStorage, setStorage,
open, saveImageToPhotosAlbum, codeVerifSucc, systemShareImage,
fundPwdVerif, fundPwdVerifComplete, showLoading, hideLoading, jumpWeb,
setClipBoardData, getPackageName
```

iframe 加载后通过 `web-bridge-ready` 和 `pageWillAppear` 完成握手；通用 `jsBridge.ts` 会在 parent 尚未 ready 时暂存请求，也会暂存早于事件订阅到达的事件。

安全注意：当前 iframe 回复和部分请求使用 `targetOrigin: '*'`。已有 `sourceWindow` 可限制消息来源，但后续安全加固仍应：

- 校验 `event.source`。
- 校验 `event.origin` 是否属于允许列表。
- 能确定目标时使用明确 origin，减少 `'*'`。
- 禁止在 Bridge 日志中打印 token、device ID 或完整用户信息。

## 9. 返回导航的责任边界

必须区分三种返回：

1. **H5 Vue Hash Router 内部返回**：由 H5 Router 自己维护。
2. **H5 明确调用 `CMSScriptMessageChannel` 的 `back`/`close`/`pop`**：由 Flutter 容器处理。
3. **远端页面直接调用浏览器 `history.back()` 或依赖自己的错误历史栈**：由远端页面负责。

远端页面可能通过 `window.location.replace(url)` 替换掉本地 SPA 页面。若该页面没有建立有效 History，左上角按钮直接调用 `history.back()` 时就可能无处可退。这不是容器 Bridge 请求，原生通道不会收到消息。

不要为了兜底第三种情况全局覆盖 `window.history.back`、`history.go` 或注入通用 click 拦截：

- 会改变正常 Vue Router 和远端页面语义。
- 可能把合法的多步历史导航错误地重置到 Embedded 首页。
- 无法区分页面内返回、关闭 WebView、关闭弹层等不同意图。
- 对后续接入的第三方页面有不可预测副作用。

需要原生关闭或返回时，远端页面必须接入约定 Bridge；不接入 Bridge 的页面需自行保证浏览器历史有效。

## 10. 标准升级流程

### 10.1 构建与同步

```bash
cd /Users/starburst/Desktop/H5-app-develop
pnpm build:embedded
pnpm sync:embedded -- /Users/starburst/TripCost/assets/future_invest_h5
```

不要用 Finder 拖拽覆盖，也不要只复制 `index.html`。哈希文件名会随构建变化，残留旧文件或漏文件都会让入口、清单和真实目录失配。

### 10.2 Flutter 校验

```bash
cd /Users/starburst/TripCost
dart format \
  lib/features/future_invest/infrastructure/future_invest_asset_server.dart \
  lib/features/future_invest/infrastructure/future_invest_js_bridge.dart \
  lib/features/future_invest/presentation/future_invest_page.dart \
  test/features/future_invest

flutter test \
  test/features/future_invest/future_invest_asset_server_test.dart \
  test/features/future_invest/future_invest_js_bridge_test.dart

flutter analyze \
  lib/features/future_invest/infrastructure/future_invest_asset_server.dart \
  lib/features/future_invest/infrastructure/future_invest_js_bridge.dart \
  lib/features/future_invest/presentation/future_invest_page.dart \
  test/features/future_invest
```

发布前再做 iOS Simulator 或真机验证，至少覆盖：

- 首次打开不是白屏，首屏内容正常出现。
- 切换回 RoamSum 后状态能保存。
- 进入图表、交易等二级页时动态 chunk 能加载。
- 当前语言正确，切换语言后对应 chunk 能加载。
- H5 主动调用 `close` 时 Promise 收到回调且页面返回。
- 网络不可用时能区分“本地静态资源可读”和“远端业务请求失败”。
- App 内 `version.json` 与发布记录一致。

## 11. 常见故障排查

| 现象 | 优先检查 | 常见根因 |
| --- | --- | --- |
| 打开后纯白 | WebView 主 frame、JS 控制台、入口 URL、JS MIME | 使用 `file://`/asset scheme 加载 ESM；JS MIME 错；入口引用根绝对路径 |
| 首页能开，二级页白屏 | 失败的 chunk URL、`pubspec.yaml` 子目录、清单 allowlist | 动态 chunk 没打进 Flutter；目录未声明；只复制了入口 |
| 安装后仍像旧 H5 | bundle 内 `version.json`、整包 SHA、App 构建号 | 同步后未重新打包；安装的是旧 IPA；只替换了部分资源 |
| H5 Bridge Promise 一直 pending | 通道注册时序、`methodId`、回调函数名、`code` 类型 | 通道在 load 后才注册；没有回传 methodId；把 `1` 当数字而非字符串；回调名不一致 |
| iOS 收到消息但 JSON 解析失败 | 原始消息是否是 Map 描述 | WKWebView 对象经插件暴露成 `{method: ...}` 字符串 |
| 点击远端页面返回无反应 | 是否真的调用了原生 Bridge | 页面直接调用 History 且历史无效，属于远端适配问题 |
| 离线仍无法登录/交易 | `env.js` 和失败请求域 | 静态资源本地化不等于 API、图片和 WebSocket 离线 |
| 资源预算突然超限 | `asset-manifest.json.budgets`、最大文件、首屏声明 | 新依赖被静态 import；恢复路由预取；字体或大图重新进入输出 |
| H5 构建出现 `EMFILE` | 文件监听数和运行环境 | 文件路由扫描/监听触达环境上限；不要因此直接修改业务代码 |

## 12. 变更检查清单

每次升级逐项确认：

- [ ] 只修改 H5 源码，没有手改 Flutter 中的压缩 JS。
- [ ] Embedded 仍是 `base: './'`、Hash Router、`safari15`。
- [ ] 没有 legacy、modulepreload、PWA、SW、Workbox、Sitemap。
- [ ] 图表、Firebase、交易页和非当前语言仍不属于首屏依赖。
- [ ] 最终包没有意外字体，大图仍使用经过视觉验收的 WebP。
- [ ] 五项资源预算全部通过。
- [ ] `version.json`、逐文件 SHA 和整包 SHA 已生成。
- [ ] 使用同步脚本完成原子替换，未手工拼包。
- [ ] `pubspec.yaml` 覆盖所有实际资源子目录。
- [ ] 回环服务器的 MIME、allowlist、缓存和关闭逻辑没有退化。
- [ ] 通道名、请求结构、`methodId`、字符串 `code` 和回调函数名保持兼容。
- [ ] 原生支持矩阵与 H5 实际调用一致，未知方法能明确失败而不是悬挂。
- [ ] 没有注入全局 History monkeypatch 去掩盖远端页面问题。
- [ ] Simulator/真机证据与静态检查、单元测试证据分开记录。

## 13. 当前验证记录

2026-08-21 的证据分层：

- **构建产物证据**：`asset-manifest.json` 的 659 个文件、五项预算和 SHA-256 已读取核对；这证明当前同步目录符合清单，不证明远端接口可用。
- **单元测试证据**：资源服务和 Bridge 解析的 6 个聚焦测试全部通过，包括入口/ESM MIME、清单 allowlist、关闭生命周期、JSON、WK Map 描述、别名和步数边界。
- **静态检查证据**：上述 Future Invest Flutter 实现及测试执行聚焦 `flutter analyze`，结果为 `No issues found`。
- **Simulator 证据**：iPhone 16 Pro、iOS 18.3 Simulator 已验证 Embedded 首页可见并能进入 H5 页面；这不等于真机、所有远端页面、登录、行情、交易或 App Store 归档均已验证。
- **已排除实验**：远端页面 History 返回兜底的全局注入已撤销；当前只保留标准 Bridge 返回处理。

## 14. 相关实现位置

Flutter：

- `lib/features/future_invest/presentation/future_invest_page.dart`
- `lib/features/future_invest/infrastructure/future_invest_asset_server.dart`
- `lib/features/future_invest/infrastructure/future_invest_js_bridge.dart`
- `test/features/future_invest/future_invest_asset_server_test.dart`
- `test/features/future_invest/future_invest_js_bridge_test.dart`
- `assets/future_invest_h5/version.json`
- `assets/future_invest_h5/asset-manifest.json`
- `pubspec.yaml`

H5 源码：

- `vite.config.ts`
- `build/vite/index.ts`
- `scripts/finalize-embedded.mjs`
- `scripts/sync-embedded.mjs`
- `src/router/index.ts`
- `src/main.ts`
- `src/utils/i18n.ts`
- `src/utils/jsBridge.ts`
- `src/composables/useJsBridge.ts`
- `src/utils/firebaseSession.embedded.ts`
- `src/components/Chart/index.vue`
