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
    ListedItem(
      '个人量具',
      '按自家勺、碗、杯显示用量并在登录设备间同步',
      '你主动登记的名称、种类和毫升容量；存在账号中，离线缓存只保留已有量具，'
          '不改动菜谱版本，也不交给第三方 SDK；可以随时修改或删除',
    ),
    ListedItem(
      '一句话生成、修改请求与内部模型日志',
      '检索、生成或预览修改菜谱、配额核算和排查模型错误',
      '你主动输入的菜名、口味、限制、人数、厨具、问题回答或修改要求及所编辑的私有菜谱；'
          '修改事件记录请求 ID、意图、候选操作、每条决定及最终值、保存版本 ID，未保存也可区分。'
          '内部日志保存模型请求/回答、'
          '用户 ID、模型、用量、成本、耗时和提示词版本，默认 90 天后清理请求/回答。'
          '经验事件只记录解析约束、选择及保存结果，不记录原始输入全文；日志不向其他用户开放。'
          '生成菜谱默认私有，修改预览只在你确认后保存版本，不自动公开或修改口味档案；'
          '请勿输入身份、联系方式或其他敏感信息',
    ),
    ListedItem('时区', '按你的日期计算“今天”“本周”和每月回顾', '从手机系统设置读取'),
    ListedItem('设备 ID', '区分登录的设备、防止验证码被滥用', 'App 安装时随机生成，卸载后失效'),
    ListedItem('同意记录', '证明你何时同意或撤回了哪一版协议', '类型、版本、时间、设备 ID'),
    ListedItem('崩溃信息', '修复闪退和错误', '只在同意隐私政策后收集，不含菜谱、口味和健康信息'),
    ListedItem(
      '产品使用统计',
      '了解哪些功能好用、哪里加载慢，改进产品',
      '页面访问、入口点击、加载耗时；和你的菜谱、口味档案、做菜记录等经验数据完全分开存放，'
          '不含菜谱内容、口味档案、过敏和健康信息；只在同意隐私政策后采集，'
          '可以在设置里随时关闭“产品改进统计”；阶段一不会交给任何第三方统计服务',
    ),
    ListedItem(
      '操作和使用事件',
      '同步做菜进度、支撑后续的推荐和统计功能',
      '登录后收集，例如事件类型、发生时间、关联的菜谱版本/做菜记录等 ID 和事件内容；'
          '离线时先存在手机本地，联网后再上传',
    ),
    ListedItem(
      '菜谱成品照片',
      '显示在你自己的私有菜谱版本里',
      '你主动选择或拍摄后上传；上传前压缩并移除位置等照片元数据，'
          '照片放在私有对象存储中，读取使用短期地址；拒绝相机或相册权限不影响其他编辑功能',
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
    ListedItem(
      '服务端配置的模型服务（非 App SDK）',
      '理解一句话、设计或预览修改菜谱、食材匹配和向量检索',
      '使用一句话生成时，将请求内容和约束发给服务端当前配置的模型供应商；'
          '主动请求修改时，发送修改要求、基准菜谱快照和提取的意图，用于提出有限编辑操作。'
          '模型启用后，保存的私有菜谱文本也会交给向量模型用于检索。'
          '不发送邮箱、登录凭据或用户 ID。'
          '供应商可替换，上线前需公布实际供应商及其隐私条款；禁用模型时仍可手动编辑和查看菜谱',
    ),
    ListedItem(
      '图片选择组件（image_picker）',
      '从相机或相册选择成品图',
      '只在你主动选择拍照或选图时调用系统能力；不把照片交给该组件的第三方服务',
    ),
  ],
);
