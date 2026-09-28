/// 界面描述协议契约文件在哪：`app/assets/contracts/ui_protocol/`，服务端和 App
/// 都从这一份读，不各写一份（见 docs/adr/0005-界面描述协议共享契约.md）。放在
/// `app/assets/` 下面是普通的包内资产路径；Flutter 测试的 asset bundle 对转义包根
/// 目录的 `../` 路径处理不稳定，这里的路径要和 `app/pubspec.yaml` 的
/// `flutter.assets` 保持一致。
library;

/// App 自己实现的协议版本。#77 阶段只认这一个版本；App 请求组合时把它带给服务端。
const supportedProtocolVersion = '1.0';

const _contractsRoot = 'assets/contracts/ui_protocol';

String pageDescriptionSchemaAsset(String protocolMajor) =>
    '$_contractsRoot/schema/$protocolMajor/page_description.schema.json';

String componentSchemaAsset(String protocolMajor, String componentType) =>
    '$_contractsRoot/schema/$protocolMajor/components/$componentType.schema.json';

String sampleAsset(String category, String name) =>
    '$_contractsRoot/samples/$category/$name';
