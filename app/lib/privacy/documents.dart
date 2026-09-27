/// 随 App 发布的静态清单：个人信息收集清单、第三方 SDK 共享清单。
///
/// 每新增一个 SDK 或一项收集内容，都要同步更新这里（CLAUDE.md 第 5 节检查清单）。
/// 正文是占位文本，上线前由产品负责人确认、律师审阅（SPEC-011）。
class ListedItem {
  const ListedItem(this.title, this.purpose, this.detail);

  final String title;
  final String purpose;
  final String detail;
}

class StaticDocument {
  const StaticDocument({
    required this.id,
    required this.title,
    required this.intro,
    required this.items,
  });

  final String id;
  final String title;
  final String intro;
  final List<ListedItem> items;
}

const personalInfoList = StaticDocument(
  id: 'personal-info',
  title: '个人信息收集清单',
  intro: '【占位文本】味谱收集以下信息，只用于列出的用途。',
  items: [
    ListedItem('邮箱地址', '登录、找回账号', '用邮箱验证码登录时收集；用 Apple 登录时可能是 Apple 的中转邮箱'),
    ListedItem('Apple 用户标识', '通过 Apple 登录', '只在你选择通过 Apple 登录时收集'),
    ListedItem('昵称', '菜谱和改良版的署名', '默认自动生成，你可以修改'),
    ListedItem('时区', '按你的日期计算“今天”“本周”和每月回顾', '从手机系统设置读取'),
    ListedItem('设备 ID', '区分登录的设备、防止验证码被滥用', 'App 安装时随机生成，卸载后失效'),
    ListedItem('同意记录', '证明你何时同意或撤回了哪一版协议', '类型、版本、时间、设备 ID'),
    ListedItem('崩溃信息', '修复闪退和错误', '只在同意隐私政策后收集，不含菜谱、口味和健康信息'),
    ListedItem(
      '操作和使用事件',
      '同步做菜进度、支撑后续的推荐和统计功能',
      '登录后收集，例如事件类型、发生时间、关联的菜谱版本/做菜记录等 ID 和事件内容；'
          '离线时先存在手机本地，联网后再上传',
    ),
  ],
);

const sdkList = StaticDocument(
  id: 'sdk',
  title: '第三方 SDK 共享清单',
  intro: '【占位文本】味谱使用以下第三方组件。同意隐私政策前，它们都不会启动。',
  items: [
    ListedItem(
      'Sentry Flutter SDK（sentry_flutter）',
      '崩溃和错误上报',
      '数据发到味谱自建的 GlitchTip 服务器，不交给第三方；上报前去掉菜谱、口味、健康信息',
    ),
    ListedItem(
      'Sign in with Apple（sign_in_with_apple）',
      '通过 Apple 登录（仅 iPhone）',
      '只在你点“通过 Apple 登录”时调用系统的 Apple 登录',
    ),
  ],
);
