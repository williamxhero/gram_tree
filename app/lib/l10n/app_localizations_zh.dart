// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get familyTitle => '家庭成员';

  @override
  String get familyIntro => '只记必要的称呼、年龄段和简单偏好；不创建家庭账号，不推断过敏。';

  @override
  String get familyEmpty => '还没有家庭成员';

  @override
  String get familyHidden => '家庭成员信息已从内存清除';

  @override
  String get familyUnavailable => '家庭信息暂不可用；仍可在设置撤回同意';

  @override
  String get familySaveUnconfirmed => '保存尚未确认，请联网后重试';

  @override
  String get familyCreateUnconfirmed => '创建尚未确认；请关闭并重新打开家庭成员列表，确认是否已创建后再操作。';

  @override
  String get familyDeleteUnconfirmed => '删除尚未确认，信息已从本机内存清除；请重试';

  @override
  String get familyDeleteRetry => '重试删除';

  @override
  String get familyAdd => '添加家庭成员';

  @override
  String get familyConsentTitle => '家庭成员信息单独同意';

  @override
  String get familyConsentBody =>
      '只收集家人的称呼、年龄段、与标准不同的简单口味、忌口和你手动选择的过敏，用于保存和查看本账号内的必要做菜信息。不收集真实姓名、生日或照片，不建立可登录或共享的家庭账号。涉及不满十四周岁儿童时，请由监护人确认同意并仅填写必要信息。当前资料和可识别修改历史加密保存、仅本人可见，不进入公开内容、持久缓存或模型日志。删除成员会删除其资料、可识别历史和关联；在设置的隐私入口撤回敏感同意，会删除所有家庭成员及本人过敏，账号注销也会删除。拒绝不影响普通口味。本同意不代表同意外部 AI 或第三方共享。';

  @override
  String get familyRefuse => '暂不填写';

  @override
  String get familyAgree => '单独同意并继续';

  @override
  String get familyEditorTitle => '家庭成员简化档案';

  @override
  String get familyDetailTitle => '家庭成员档案';

  @override
  String get familyNickname => '称呼（不是真实姓名）';

  @override
  String get familyNicknameRequired => '请填写称呼和年龄段';

  @override
  String get familyAgeBand => '年龄段';

  @override
  String get familyAgeUnder1 => '1 岁以下';

  @override
  String get familyAge1To3 => '1～3 岁';

  @override
  String get familyAge3To6 => '3～6 岁';

  @override
  String get familyAge6To12 => '6～12 岁';

  @override
  String get familyAge12To18 => '12～18 岁';

  @override
  String get familyAgeAdult => '成人';

  @override
  String get familyAgeElder => '老人';

  @override
  String get familyFlavors => '只填写与标准不同的口味';

  @override
  String get familyNoChili => '不吃辣';

  @override
  String get familyStandard => '标准（不单独记录）';

  @override
  String get familySavedCoefficient => '已保存系数';

  @override
  String get familyAvoidances => '忌口';

  @override
  String get familyAvoidanceAdd => '添加忌口食材或分类';

  @override
  String get familyAllergies => '手动过敏（不会自动推断）';

  @override
  String get familyAllergyAdd => '添加具体过敏食材';

  @override
  String get familyUnset => '未填写';

  @override
  String get familyView => '查看';

  @override
  String get familyEdit => '修改';

  @override
  String get familyDelete => '删除成员';

  @override
  String get familyDeleteTitle => '删除这位家庭成员？';

  @override
  String get familyDeleteBody => '删除其全部资料、可识别修改历史和关联引用。其他成员和普通口味不受影响。';

  @override
  String get familyHistory => '家庭成员私密修改历史';

  @override
  String get familyHistoryEmpty => '没有家庭成员私密修改历史';

  @override
  String get familyHistoryUnavailable => '私密历史暂不可用';

  @override
  String get familyManual => '家庭成员手动填写';

  @override
  String get familyDeletedReceipt => '家庭成员已删除（不保留身份）';

  @override
  String get familyWhy => '为什么';

  @override
  String get familyClose => '关闭';

  @override
  String get familyRemove => '移除';

  @override
  String get networkConsentRequired => '需要先同意隐私政策';

  @override
  String get networkChecking => '正在检查连接，在线功能需要联网';

  @override
  String get networkConnected => '服务已连接';

  @override
  String syncPendingCount(int count) {
    return '待同步 $count 条';
  }

  @override
  String syncRetryExhaustedCount(int count) {
    return '重试次数已达上限，已保留 $count 条内容';
  }

  @override
  String syncDependencyFailedCount(int count) {
    return '前置写入失败，已保留 $count 条内容';
  }

  @override
  String syncDependencyConflictCount(int count) {
    return '前置写入存在冲突，$count 条暂缓同步';
  }

  @override
  String syncDependencyMissingCount(int count) {
    return '依赖写入尚未到达，$count 条暂缓同步';
  }

  @override
  String syncDependencyCycleCount(int count) {
    return '依赖写入存在循环，已保留 $count 条内容';
  }

  @override
  String syncLegacyOwnerUnknownCount(int count) {
    return '本机有 $count 条旧写入无法确定原账号，已隔离保留，不会上传';
  }

  @override
  String syncLegacyRejectedCount(int count) {
    return '本机保留 $count 条旧拒收记录，仅有拒收凭据，无法恢复原内容';
  }

  @override
  String get networkUnavailable => '需要联网：暂时连接不到服务，请检查网络；本机内容仍可使用。';

  @override
  String get snapshotCapacityRejected => '本机缓存空间不足，此版本未离线保存；菜单和正在做的内容已保留。';

  @override
  String get snapshotProtectedOverLimit => '受保护的菜谱超出缓存容量，内容已保留；请释放不再需要的保护。';

  @override
  String get recipeAnswerBasis => '这是一般经验，还没有足够记录验证';

  @override
  String get recipeAnswerAnswered => '已回答 · 一般经验';

  @override
  String get recipeAnswerUncertain => '不确定 · 一般经验';

  @override
  String get recipeAnswerCannotAnswer => '无法回答 · 一般经验';

  @override
  String get recipeAnswerUnavailable => '能力不可用 · 一般经验';

  @override
  String get recipeAnswerBudget => '月预算已用完';

  @override
  String get recipeAnswerQuota => '今日解释配额已用完';

  @override
  String get recipeAnswerTimeout => '模型响应超时';

  @override
  String get recipeAnswerDisabled => '模型已停用';

  @override
  String get recipeAnswerNotConfigured => '模型暂未配置';

  @override
  String get recipeAnswerNetwork => '模型或网络暂时不可用';

  @override
  String recipeAnswerUnavailableConclusion(String reason) {
    return '菜谱解释（explain）：$reason。';
  }

  @override
  String get recipeAnswerSource => 'AI 估算 · 菜谱解释';

  @override
  String get recipeAnswerClose => '关闭解释';

  @override
  String recipeAnswerQuestion(String question) {
    return '问题：$question';
  }

  @override
  String get recipeAnswerContinue => '查看、表单编辑和规则换算仍可使用；问题已保留，可以重试。';

  @override
  String recipeAnswerVersion(int version) {
    return '明细 · 第 $version 版；解释不会自动修改菜谱。';
  }

  @override
  String recipeAnswerAllergens(String allergens) {
    return '过敏原：$allergens';
  }

  @override
  String recipeAnswerReplacementAllergens(String allergens) {
    return '替换食材过敏原：$allergens';
  }

  @override
  String get recipeAnswerIncompleteAllergens => '过敏信息可能不完整，请核对实际食材。';

  @override
  String get recipeAnswerTitle => '问这版的做法';

  @override
  String get recipeAnswerSemantics => '问这版的做法；只提供一般经验，不改动菜谱';

  @override
  String get recipeAnswerInput => '厨房问题';

  @override
  String get recipeAnswerHint => '例如：这一步为什么要炒熟？';

  @override
  String get recipeAnswerBusy => '正在解释…';

  @override
  String get recipeAnswerRetry => '重试解释';

  @override
  String get recipeAnswerSubmit => '查看解释';

  @override
  String get recipeAnswerExperience => '一般经验';

  @override
  String get recipeAnswerWhy => '为什么 · 明细';

  @override
  String get appTitle => '味谱';

  @override
  String get measureInputAction => '用自家量具录入';

  @override
  String get measureInputTitle => '量具用量换算';

  @override
  String get measureInputTool => '自家量具';

  @override
  String get measureInputCount => '几勺、几碗或几杯';

  @override
  String get measureInputBaseUnit => '采用的基础单位';

  @override
  String get measureInputPreview => '查看换算';

  @override
  String get measureInputConfirm => '确认采用基础量';

  @override
  String get measureInputEstimate => '我了解这是估算，继续换算';

  @override
  String get measureInputFallback => '返回填写基础量';

  @override
  String get measureInputNoTools => '还没有登记量具，请先在个人中心登记，或直接填写克、毫升。';

  @override
  String get measureInputOffline => '离线或缺少转换数据，不能可靠换算；请返回填写基础量。草稿不会改变。';

  @override
  String get measureInputInvalid => '请输入有限、非负且不超过 10000000 的数量。';

  @override
  String get measureInputUnchanged => '尚未确认，当前食材用量不会改变。';

  @override
  String get measureInputEvidence => '量具输入依据';

  @override
  String get recipeFlavorUnknown => '味型贡献未填写';

  @override
  String get recipeFlavorFunctionalOff => '不作功能性用料';

  @override
  String get recipeFlavorAuthorBasis => '作者按这道菜的实际作用填写';

  @override
  String get recipeFlavorEditorTitle => '这道菜的味型贡献';

  @override
  String get recipeFlavorEditorHint => '强度 0–3；未填写不代表零贡献';

  @override
  String recipeFlavorAxisLabel(Object axis) {
    return '$axis味贡献';
  }

  @override
  String recipeFlavorAxisUnknown(Object axis) {
    return '$axis 未填写';
  }

  @override
  String recipeFlavorStrength(String axis, int strength) {
    return '$axis $strength';
  }

  @override
  String get recipeFlavorSalty => '咸';

  @override
  String get recipeFlavorSweet => '甜';

  @override
  String get recipeFlavorSour => '酸';

  @override
  String get recipeFlavorSpicy => '辣';

  @override
  String get recipeFlavorUmami => '鲜';

  @override
  String get recipeFlavorNumbing => '麻';

  @override
  String get recipeFlavorOily => '油';

  @override
  String get recipeComparisonTitle => '食材版本对比';

  @override
  String get recipeComparisonError => '无法比较这些版本，请确认两版仍可查看';

  @override
  String get recipeComparisonFrom => '从 A';

  @override
  String get recipeComparisonTo => '到 B';

  @override
  String get recipeComparisonScope => '仅比较食材，尚未比较步骤';

  @override
  String recipeComparisonServings(int servings) {
    return '已按 $servings 人份对比';
  }

  @override
  String recipeComparisonServingValue(int servings) {
    return '$servings 人份';
  }

  @override
  String get recipeComparisonServingBasis =>
      'B 的基础量按线性、固定或阶梯规则归一到 A 的份数；原版本未修改。';

  @override
  String get recipeComparisonShowAll => '展开全部食材';

  @override
  String get recipeComparisonEmpty => '没有食材配方变化';

  @override
  String get recipeComparisonSnapshotFields => '菜谱字段变化';

  @override
  String recipeComparisonVersion(String author, int version, int servings) {
    return '$author · 第 $version 版 · $servings 人份';
  }

  @override
  String get recipeComparisonDetails => '查看版本详情';

  @override
  String get recipeComparisonUnchangedBasis => '基础量按相同份数比较，食材与执行字段均未改变';

  @override
  String get recipeComparisonUnchanged => '无食材变化';

  @override
  String recipeComparisonBefore(Object value) {
    return 'A：$value';
  }

  @override
  String recipeComparisonAfter(Object value) {
    return 'B：$value';
  }

  @override
  String get recipeComparisonIngredientDetails => '食材明细';

  @override
  String get recipeComparisonNone => '无';

  @override
  String get recipeComparisonYes => '是';

  @override
  String get recipeComparisonNo => '否';

  @override
  String get recipeComparisonAdded => '新增';

  @override
  String get recipeComparisonRemoved => '删除';

  @override
  String get recipeComparisonReplacement => '替换';

  @override
  String get recipeComparisonQuantity => '用量变化';

  @override
  String get recipeComparisonUnit => '单位不同';

  @override
  String get recipeComparisonField => '执行字段变化';

  @override
  String get recipeComparisonText => '文字修改';

  @override
  String get recipeComparisonBaseQuantity => '基础量';

  @override
  String get recipeComparisonBaseUnit => '基础单位';

  @override
  String get recipeComparisonDisplayName => '显示名';

  @override
  String get recipeComparisonPreparation => '处理方式';

  @override
  String get recipeComparisonOptional => '可选性';

  @override
  String get recipeComparisonFlavor => '味型贡献';

  @override
  String get recipeComparisonTags => '标签';

  @override
  String get recipeDescription => '描述';

  @override
  String get recipeBaseMold => '基准模具';

  @override
  String get recipeCuisine => '菜系';

  @override
  String get recipeDesignRationale => '设计理由';

  @override
  String get whyTitle => '为什么';

  @override
  String get recipeComparisonTotalTime => '总时长';

  @override
  String get recipeComparisonActiveTime => '需守着的时长';

  @override
  String recipeComparisonDetailField(Object label, Object value) {
    return '$label：$value';
  }

  @override
  String get recipeComparisonCancelSelection => '取消选择';

  @override
  String get recipeComparisonSelect => '选两版对比';

  @override
  String get recipeComparisonSelectionHint => '先选 A，再选 B；方向为 A 到 B，仅比较食材';

  @override
  String get recipeComparisonAction => '比较食材';

  @override
  String get recipeComparisonPrevious => '和上一版比食材';

  @override
  String recipeComparisonCandidate(String author, String recipe, int version) {
    return '$author · 菜谱 $recipe · 第 $version 版';
  }

  @override
  String get tabToday => '今天';

  @override
  String get tabDiscover => '发现';

  @override
  String get tabCreate => '新建';

  @override
  String get tabRecords => '记录';

  @override
  String get tabMe => '我的';

  @override
  String get todayEmptyTitle => '今天还没有安排';

  @override
  String get todayEmptyBody => '这里会显示今天要做的菜。点下方的＋开始添加。';

  @override
  String get todayEmptyAction => '添加第一道菜谱';

  @override
  String get discoverEmptyTitle => '还没有可发现的内容';

  @override
  String get discoverEmptyBody => '以后这里会推荐适合你的菜谱和做法。';

  @override
  String get createEmptyTitle => '想做点什么？';

  @override
  String get createEmptyBody => '以后可以在这里录入菜谱、记录一次做菜。';

  @override
  String get recordsEmptyTitle => '还没有做菜记录';

  @override
  String get recordsEmptyBody => '每次做完菜后的记录和心得会保存在这里。';

  @override
  String get meEmptyTitle => '个人中心';

  @override
  String get meEmptyBody => '做过的菜、口味档案会出现在这里。';

  @override
  String get featureReceiptScan => '拍小票记价格';

  @override
  String get comingSoon => '这个功能正在准备中';

  @override
  String get consentEyebrow => '欢迎使用味谱';

  @override
  String get consentTitle => '开始之前，先说清楚我们会用到什么';

  @override
  String get consentCollectLabel => '我们会收集';

  @override
  String get consentCollect1 => '登录用的邮箱，或 Apple 提供的中转邮箱';

  @override
  String get consentCollect2 => '你写的菜谱、做菜记录和口味设置，用来给你推荐和换算';

  @override
  String get consentCollect3 => '出错时的崩溃信息，不含菜谱和口味内容';

  @override
  String get consentNotLabel => '我们不会';

  @override
  String get consentNot1 => '放广告，或把你的数据卖给别人';

  @override
  String get consentNot2 => '在你用到相机、麦克风之前申请权限';

  @override
  String get consentLinksPrefix => '完整内容见';

  @override
  String get termsTitle => '用户协议';

  @override
  String get privacyTitle => '隐私政策';

  @override
  String get consentAgree => '同意并继续';

  @override
  String get consentDecline => '不同意';

  @override
  String get consentExplainTitle => '不同意的话，味谱没法工作';

  @override
  String get consentExplainLead => '这几项是最少需要的：';

  @override
  String get consentExplain1 => '邮箱：登录和找回账号';

  @override
  String get consentExplain2 => '你的菜谱和记录：保存到云端，换手机不丢';

  @override
  String get consentExplain3 => '崩溃信息：修复闪退，可以随时在设置里撤回';

  @override
  String get consentExplainTail => '如果仍不同意，App 会退出，不保存任何信息。下次打开时会再问你。';

  @override
  String get consentExplainQuit => '仍不同意，退出';

  @override
  String get consentUpdatedEyebrow => '隐私政策已更新';

  @override
  String get consentUpdatedTitle => '这次改了什么';

  @override
  String consentUpdatedVersion(String from, String to) {
    return '$from → $to';
  }

  @override
  String get consentUpdatedTail => '重新同意后才能继续使用。';

  @override
  String get consentUpdatedAgree => '同意新版本';

  @override
  String get goodbyeTitle => '你没有同意隐私政策';

  @override
  String get goodbyeBody => '味谱没有收集任何信息。现在可以关掉 App 了，下次打开时会再问你。';

  @override
  String get goodbyeReconsider => '重新考虑';

  @override
  String get loginTitle => '登录味谱';

  @override
  String get loginSubtitle => '第一次用会自动创建账号。';

  @override
  String get emailLabel => '邮箱';

  @override
  String get sendCode => '发送验证码';

  @override
  String get or => '或';

  @override
  String get appleSignIn => '通过 Apple 登录';

  @override
  String get loginFooter => '登录即表示你已同意用户协议和隐私政策。';

  @override
  String get codeTitle => '输入验证码';

  @override
  String codeSentTo(String email, int minutes) {
    return '已发到 $email，$minutes 分钟内有效。';
  }

  @override
  String get codeFieldLabel => '6 位验证码';

  @override
  String resendIn(int seconds) {
    return '$seconds 秒后可以重新发送';
  }

  @override
  String get resend => '重新发送';

  @override
  String get codeHelp => '收不到？看看垃圾邮件，或返回检查邮箱是否填对。';

  @override
  String get sessionExpired => '登录已失效，请重新登录';

  @override
  String get meEdit => '改昵称';

  @override
  String get meNicknameTitle => '改昵称';

  @override
  String meNicknameHint(int max) {
    return '最多 $max 个字';
  }

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get confirm => '确定';

  @override
  String get settings => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsIdentities => '登录方式';

  @override
  String get settingsTimezone => '时区';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsWithdraw => '撤回同意';

  @override
  String get settingsProductAnalytics => '产品改进统计';

  @override
  String get settingsProductAnalyticsDetail =>
      '页面访问、入口点击、加载耗时；不含菜谱内容、口味档案、过敏和健康信息，同意隐私政策后才采集';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '退出这台设备的登录？其他设备不受影响。';

  @override
  String get deleteAccount => '注销账号';

  @override
  String get openFullText => '在浏览器里看完整版';

  @override
  String get identityEmail => '邮箱';

  @override
  String get identityApple => 'Apple';

  @override
  String get identityNotBound => '未绑定';

  @override
  String get identitiesHint => '多绑一种方式，原来的方式不能用时还能登录。以后加手机号、微信也不影响你的菜谱和记录。';

  @override
  String get bindEmail => '绑定邮箱';

  @override
  String get bindApple => '绑定 Apple';

  @override
  String get bindDone => '已绑定';

  @override
  String get withdrawBody => '撤回后，味谱会立刻停止收集信息、关闭崩溃上报，并退出登录。';

  @override
  String get withdrawDataLabel => '已存的数据';

  @override
  String get withdrawDataBody =>
      '撤回不会删除已保存的菜谱和记录。想拿走数据，可以先导出（即将提供）；想彻底删除，请注销账号。';

  @override
  String get withdrawConfirm => '撤回并退出';

  @override
  String get deleteStepVerify => '先确认是你本人';

  @override
  String deleteVerifyEmail(String email) {
    return '验证码会发到 $email。';
  }

  @override
  String get deleteVerifyApple => '通过 Apple 重新验证';

  @override
  String deleteVerifyWindow(int minutes) {
    return '验证后 $minutes 分钟内完成注销。';
  }

  @override
  String get deleteWhatTitle => '这些会被删除';

  @override
  String get deleteWhat1 => '昵称和登录方式（邮箱、Apple）';

  @override
  String get deleteWhat2 => '你的同意记录';

  @override
  String get deleteWhat3 => '和 Apple 账号的授权关联会被解除';

  @override
  String deleteWhatTail(int days) {
    return '确认后立即退出，账号不能再登录；$days 个工作日内删除完毕，无法恢复。';
  }

  @override
  String get deleteCheck => '我已了解，确认注销';

  @override
  String get deleteDone => '已申请注销，账号不能再登录';

  @override
  String permissionNeeded(String label) {
    return '需要使用$label';
  }

  @override
  String get permissionContinue => '继续';

  @override
  String get permissionNotNow => '暂不';

  @override
  String permissionUnavailableTitle(String feature) {
    return '$feature不可用';
  }

  @override
  String permissionUnavailableBody(String label) {
    return '你没有允许使用$label。其他功能不受影响。';
  }

  @override
  String get permissionOpenSettings => '去系统设置打开';

  @override
  String compositionLastUpdatedAt(String time) {
    return '上次更新于 $time';
  }

  @override
  String get myRecipes => '我的菜谱';

  @override
  String get myRecipesSubtitle => '管理私有菜谱和版本历史';

  @override
  String get newRecipe => '新建菜谱';

  @override
  String get viewMyRecipes => '查看我的菜谱';

  @override
  String get recipeEmptyTitle => '还没有菜谱';

  @override
  String get recipeEmptyBody => '把常做的一道菜写下来，之后可以继续改良。';

  @override
  String get recipeLoadError => '菜谱暂时加载不了';

  @override
  String get recipeLoadMore => '加载更多';

  @override
  String get recipeLoadMoreRetry => '加载失败，重试';

  @override
  String get recipeRetry => '重试';

  @override
  String get recipeName => '菜名';

  @override
  String get recipeContinueEdit => '继续编辑菜谱';

  @override
  String get recipeFood => '食材';

  @override
  String get recipeSearchOrFill => '搜索或填写食材';

  @override
  String get recipeQuantity => '用量';

  @override
  String get recipeUnit => '单位（克、毫升、个、勺）';

  @override
  String get recipePreparationGroup => '处理方式和分组';

  @override
  String get recipeSteps => '步骤';

  @override
  String get recipeInstruction => '步骤说明';

  @override
  String get recipeWhy => '为什么这样做（可选）';

  @override
  String get recipeChangeNote => '这次改了什么';

  @override
  String get changeExplanationTitle => '改动说明';

  @override
  String get changeExplanationChanged => '改动已变化，请重新生成说明或手写。';

  @override
  String get changeExplanationModelUnavailable => '模型暂不可用，可手写说明和标签。';

  @override
  String get changeExplanationDailyQuota => '今日 AI 额度已用完，可手写说明和标签。';

  @override
  String get changeExplanationMonthlyBudget => 'AI 预算暂不可用，可手写说明和标签。';

  @override
  String get changeExplanationNoChanges => '本次没有可说明的实际改动，可手写说明和标签。';

  @override
  String get changeExplanationFailed => '说明生成失败，请重试或手写说明和标签。';

  @override
  String get changeExplanationBasis => '仅依据本次最终改动生成，不代表已做过验证。作者可以修改说明和标签。';

  @override
  String get changeExplanationGenerating => '正在生成说明…';

  @override
  String get changeExplanationGenerate => '生成改动说明';

  @override
  String get changeExplanationHandwritten => '可手写说明和标签';

  @override
  String changeExplanationSaveAvailable(String message) {
    return '$message 手动保存不受影响。';
  }

  @override
  String get textEditDraftSaveFailed => '本机草稿保存失败，请保留当前页面并重试。';

  @override
  String get textEditDraftCleanupFailed => '本机草稿清理失败，已保留修改，请重试。';

  @override
  String get textEditInvalidJsonNumber => '请输入有效的 JSON 数值。';

  @override
  String get textEditInvalidJsonValue => '请输入与原值类型一致的有效 JSON（最多 4000 字符）。';

  @override
  String get textEditAfterJsonLabel => '修改后的 JSON 值';

  @override
  String get textEditTitle => '一句话修改菜谱';

  @override
  String get textEditSupportedChanges =>
      '支持改文字、换厨具、调整时间或难度、调整做法；口味和缺料替代暂未支持。确认前不会保存。';

  @override
  String get textEditRequestLabel => '想怎样修改菜谱？';

  @override
  String get textEditPreview => '预览菜谱修改';

  @override
  String get textEditRetrySaveCleanup => '重试保存与本机清理';

  @override
  String get textEditUnsupportedIntent =>
      '这类修改暂未支持，不会应用。支持改文字、换厨具、调整时间或难度、调整做法；口味和缺料替代请手动编辑。';

  @override
  String get recipeSaveVersion => '保存为新版本';

  @override
  String get recipeSaving => '保存中…';

  @override
  String get recipeDiscardDraft => '放弃草稿';

  @override
  String get recipeDishRequired => '请先填写菜名';

  @override
  String recipeSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get recipeRestoreTitle => '恢复未保存修改？';

  @override
  String get recipeRestoreBody => '上次编辑还有未保存内容。要恢复这份草稿吗？';

  @override
  String get recipeDiscardDraftAction => '放弃草稿';

  @override
  String get recipeRestore => '恢复';

  @override
  String recipeAuthorVersion(int version, int servings) {
    return '第 $version 版 · $servings 份';
  }

  @override
  String recipeDuration(int total, int active) {
    return '总时长 $total 分钟 · 动手 $active 分钟';
  }

  @override
  String recipeDurationServingNote(int servings) {
    return '按 $servings 份重新估算：步骤时长和火候不随份数变化，总时长和动手时长不变。';
  }

  @override
  String get recipeDurationBatchNote => '份量变大后可能要分批下锅，实际用时会更长，以成熟判断为准。';

  @override
  String get recipeDurationMoldNote => '换模具后烘烤时间不按底面积比例放大，时长按原步骤估算，以成熟判断为准。';

  @override
  String recipeAllergens(String items, String incomplete) {
    return '过敏原：$items$incomplete';
  }

  @override
  String get recipeSafetyTitle => '食品安全提醒';

  @override
  String get recipeSafetyCheck => '检查食品安全';

  @override
  String get recipeSafetyChecking => '正在检查……';

  @override
  String get recipeSafetySaveBlocked => '食品安全检查未通过，请调整菜谱后再保存。';

  @override
  String get recipeSafetyHighRisk => '高风险：请谨慎处理，不能只依赖计时或颜色判断。';

  @override
  String get recipeSafetyWarning => '食品安全警告';

  @override
  String get recipeSafetyInfo => '食品安全提示';

  @override
  String get recipeSafetyNoFindings => '暂未发现需要额外提醒的安全规则。';

  @override
  String get recipeSafetyLoading => '正在检查食品安全……';

  @override
  String get recipeSafetyAwaitingCheck => '菜谱已修改，等待重新检查食品安全。保存前必须完成检查。';

  @override
  String get recipeSafetyUnavailable => '这份旧版本没有保存安全检查结果，请结合食材和步骤谨慎判断。';

  @override
  String get recipeSafetyStale => '安全规则已更新，以下结果可能已过期；请重新检查后再依赖它。';

  @override
  String recipeSafetyError(String error) {
    return '食品安全检查暂时失败：$error';
  }

  @override
  String recipeSafetyRulesVersion(String version) {
    return '安全规则版本：$version';
  }

  @override
  String recipeSafetyThreshold(String temperature) {
    return '中心温度至少 $temperature°C';
  }

  @override
  String recipeSafetyRest(int minutes) {
    return '静置至少 $minutes 分钟';
  }

  @override
  String recipeSafetySteps(String steps) {
    return '关联步骤：$steps';
  }

  @override
  String recipeSafetyClaims(String claims, String basis) {
    return '禁止用语：$claims。$basis';
  }

  @override
  String get recipeSafetyClaimRewrite => '请改写为对做法的客观描述。';

  @override
  String get recipeAllergenTitle => '过敏原提示';

  @override
  String get recipeAllergenNone => '未检测到已知过敏原';

  @override
  String get recipeAllergenIncompleteBasis => '含有未收录食材，过敏原信息可能不完整。';

  @override
  String recipeReplacementAllergens(
    String name,
    String allergens,
    String incomplete,
  ) {
    return '替代品“$name”的过敏原：$allergens$incomplete';
  }

  @override
  String recipeNutrition(String incomplete) {
    return '每份营养：估算值$incomplete';
  }

  @override
  String get recipeIngredients => '食材';

  @override
  String get recipeStepsTitle => '步骤';

  @override
  String get recipeOptional => '可选';

  @override
  String get recipeAddPhoto => '添加成品图';

  @override
  String get recipeTakePhoto => '拍一张成品图';

  @override
  String get recipePhotoAvailable => '可以从相册选择成品图';

  @override
  String get recipePhotoDenied => '相册权限未开启，菜谱编辑不受影响';

  @override
  String get recipeCameraAvailable => '可以拍摄成品图';

  @override
  String get recipeCameraDenied => '相机权限未开启，菜谱编辑不受影响';

  @override
  String get recipeHistory => '查看版本历史';

  @override
  String get recipeDelete => '删除这份私有菜谱';

  @override
  String get recipeNoHistory => '还没有版本历史';

  @override
  String recipeVersionTitle(int version, String ai) {
    return '第 $version 版$ai';
  }

  @override
  String get recipeNoChangeNote => '未填写修改说明';

  @override
  String get recipeRationale => '为什么这样做';

  @override
  String get recipeKeyPoint => '要点';

  @override
  String get recipeUnnamedIngredient => '未收录食材';

  @override
  String get recipeCompleteStep => '完成这一步';

  @override
  String get recipeNotFound => '菜谱不存在或你没有权限查看';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get recipeDraftSaved => '草稿已保存';

  @override
  String get recipeCameraPermission => '拍照';

  @override
  String get recipePhotoPermission => '从相册选图';

  @override
  String get recipeComingSoon => '图片选择功能正在准备中';

  @override
  String get recipeIncomplete => '（可能不完整）';

  @override
  String recipeSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get recipeAi => ' · AI 协助';

  @override
  String get recipeEditAction => '我来改一版';

  @override
  String get recipeBaseOnVersion => '基于这一版继续编辑';

  @override
  String get recipePhotoTitle => '成品图';

  @override
  String get recipePhotoStageHint => '先选图，保存菜谱时会把它放进第 1 版。';

  @override
  String get recipePhotoVersionHint => '照片会生成新的菜谱版本，不会改动旧版本。';

  @override
  String get recipePhotoSelected => '已选择的成品图';

  @override
  String get recipePhotoSuccess => '已上传，图片会以短期私有地址读取。';

  @override
  String get recipePhotoPicking => '正在打开照片选择器…';

  @override
  String get recipePhotoProcessing => '正在压缩并清除照片元数据…';

  @override
  String get recipePhotoUploading => '正在安全上传…';

  @override
  String get recipePhotoUploadError => '图片上传失败，请稍后重试。';

  @override
  String get recipePhotoReadError => '图片无法读取，请换一张图片。';

  @override
  String get recipePhotoTooLarge => '图片尺寸过大，无法安全处理。';

  @override
  String get recipePhotoUnsafe => '图片无法安全处理，请换一张图片。';

  @override
  String get recipeCameraButton => '拍照';

  @override
  String get recipeGalleryButton => '从相册选图';

  @override
  String get recipeSourceAuthorFilled => '作者填写';

  @override
  String get recipeEmptyRecipeHeader => '没有菜谱头部';

  @override
  String get recipeEmptyIngredients => '没有食材';

  @override
  String get recipeEmptySteps => '没有步骤';

  @override
  String get recipeEmptyCard => '没有菜谱卡';

  @override
  String recipeListSummary(int version, int servings, int minutes) {
    return '第 $version 版 · $servings 份 · $minutes 分钟';
  }

  @override
  String get recipeAliases => '别名（用逗号分隔）';

  @override
  String get recipeServings => '份数';

  @override
  String get recipeServingsAdjust => '调整份数';

  @override
  String get recipeServingsDecrease => '减少一份';

  @override
  String get recipeServingsIncrease => '增加一份';

  @override
  String get recipeServingsUnit => '份';

  @override
  String recipeServingsRange(int min, int max) {
    return '可调范围：$min–$max 份';
  }

  @override
  String get recipeServingsReset => '恢复原份数';

  @override
  String get recipeBatchWarning => '注意分批下锅，时间以成熟判断为准。';

  @override
  String get recipeRuleProportional => '按比例换算';

  @override
  String get recipeRuleUnchanged => '保持原值不变';

  @override
  String get recipeRuleRound => '按个取整';

  @override
  String get recipeRuleMoldRatio => '模具比例';

  @override
  String get recipeRuleUnknown => '换算规则未识别';

  @override
  String recipeConversionRuleDetail(String original, String rule) {
    return '原值 $original，$rule';
  }

  @override
  String get recipeModeServing => '按份数';

  @override
  String get recipeModeMold => '按模具';

  @override
  String get recipeMoldConversion => '模具换算';

  @override
  String get recipeMoldReset => '恢复原模具';

  @override
  String recipeMoldOriginal(String mold, String ratio) {
    return '原模具：$mold · 底面积比例 $ratio';
  }

  @override
  String get recipeMoldTargetShape => '目标模具形状';

  @override
  String get recipeMoldRound => '圆模';

  @override
  String get recipeMoldSquare => '方模';

  @override
  String get recipeMoldRectangular => '长方模';

  @override
  String get recipeMoldCustom => '自定义尺寸';

  @override
  String get recipeMoldDiameter => '直径';

  @override
  String get recipeMoldTargetDiameter => '目标直径';

  @override
  String get recipeMoldUnit => '单位';

  @override
  String get recipeMoldInch => '英寸';

  @override
  String get recipeMoldCm => '厘米';

  @override
  String get recipeMoldSide => '边长（厘米）';

  @override
  String get recipeMoldWidth => '宽（厘米）';

  @override
  String get recipeMoldLength => '长（厘米）';

  @override
  String get recipeMoldTargetSide => '目标边长（厘米）';

  @override
  String get recipeMoldTargetWidth => '目标宽（厘米）';

  @override
  String get recipeMoldTargetLength => '目标长（厘米）';

  @override
  String get recipeMoldBakingNote => '温度保持不变；时间不按比例放大，以成熟判断为准。';

  @override
  String get recipeMoldTimeAdvisory => '时间不按模具比例放大，建议从原时间开始检查，以成熟判断为准。';

  @override
  String get recipeMoldDonenessWarning => '请以成熟判断为准，不要只看计时。';

  @override
  String get recipeMoldInvalid => '目标模具尺寸无效，请填写大于 0 的尺寸后再换算。';

  @override
  String get recipeMoldUnavailable => '这份菜谱没有记录基准模具，暂时只能按份数显示。';

  @override
  String recipeServingRoundWarning(String name) {
    return '$name取整后与按比例结果相差较大，请按口味微调其他用量。';
  }

  @override
  String recipeMoldRoundWarning(String name) {
    return '$name取整后与模具比例结果相差较大，请按实际情况微调其他用量。';
  }

  @override
  String get recipeMeasureStandardDisplayOnly => '常用量具换算；菜谱基础值未改变';

  @override
  String recipeReplacementValue(String label) {
    return '$label';
  }

  @override
  String get sourceAuthorFilled => '作者填写';

  @override
  String get sourceTasteAdjusted => '按你的口味换算';

  @override
  String get sourceScenarioAdjusted => '按场景调整';

  @override
  String get sourceAiEstimated => 'AI 估算';

  @override
  String get sourceVerified => '已验证';

  @override
  String get sourceUnknown => '来源未标注';

  @override
  String get sourceBasisUnavailable => '暂无可显示的依据';

  @override
  String whyOriginal(String value) {
    return '原来：$value';
  }

  @override
  String whyCurrent(String value) {
    return '现在：$value';
  }

  @override
  String get whyRequired => '这是必显内容，不能关掉';

  @override
  String get whySkipThisTime => '这次不用';

  @override
  String get whyDontDoAgain => '以后别这样';

  @override
  String sourceSemantics(String source) {
    return '来源：$source，点开查看为什么';
  }

  @override
  String get recipeDifficulty => '难度';

  @override
  String get recipeDishType => '菜型';

  @override
  String get recipeTags => '标签（用逗号分隔）';

  @override
  String get recipeTotalTime => '总时长（秒）';

  @override
  String get recipeActiveTime => '动手时长（秒）';

  @override
  String get recipeIngredientAdd => '添加食材';

  @override
  String get recipeIngredientDelete => '删除食材';

  @override
  String get recipeIngredientMoveUp => '食材上移';

  @override
  String get recipeIngredientMoveDown => '食材下移';

  @override
  String get recipeSearchStandard => '搜索标准食材';

  @override
  String get recipeStandardIngredient => '标准食材';

  @override
  String get recipeUnknownIngredient => '未收录';

  @override
  String get recipeBaseQuantity => '基础用量';

  @override
  String get recipeBaseUnit => '基础单位（克、毫升、个）';

  @override
  String get recipeIngredientGroup => '分组';

  @override
  String get recipeScalingMode => '缩放方式';

  @override
  String get recipeScalingProportional => '按比例';

  @override
  String get recipeScalingUnchanged => '保持不变';

  @override
  String get recipeScalingRound => '按个取整';

  @override
  String recipeScalingLibraryDefault(String mode) {
    return '跟随食材库默认（$mode）';
  }

  @override
  String get recipeScalingLibraryDefaultUnknown => '跟随食材库默认（没有默认值时按比例）';

  @override
  String get recipeOptionalToggle => '可选食材';

  @override
  String get recipeFunctionalToggle => '功能性用料';

  @override
  String get recipeReplacement => '替代品';

  @override
  String get recipeReplacementSearch => '搜索替代标准食材';

  @override
  String get recipeReplacementName => '替代品名称';

  @override
  String get recipeReplacementRatio => '替代比例';

  @override
  String get recipeReplacementNote => '替代说明';

  @override
  String get recipeStepAdd => '添加步骤';

  @override
  String get recipeStepDelete => '删除步骤';

  @override
  String get recipeStepMoveUp => '步骤上移';

  @override
  String get recipeStepMoveDown => '步骤下移';

  @override
  String get recipeStepAction => '动作类型';

  @override
  String get recipeStepIngredientRefs => '引用食材';

  @override
  String get recipeStepDuration => '时长（秒）';

  @override
  String get recipeStepUnattended => '可以走开';

  @override
  String get recipeStepHeat => '火候';

  @override
  String get recipeStepTemperature => '温度（摄氏度）';

  @override
  String get recipeStepCookware => '厨具';

  @override
  String get recipeStepDoneness => '成熟判断';

  @override
  String get recipeStepDepends => '依赖的前置步骤';

  @override
  String get recipeStepNotes => '要点';

  @override
  String get recipeStepWhy => '原理';

  @override
  String get recipeNoIngredients => '还没有食材';

  @override
  String get recipeNoSteps => '还没有步骤';

  @override
  String recipeNutritionValues(
    String energy,
    String protein,
    String fat,
    String carb,
    String sodium,
    String incomplete,
  ) {
    return '每份营养估算：能量 $energy 千卡，蛋白质 $protein 克，脂肪 $fat 克，碳水 $carb 克，钠 $sodium 毫克$incomplete';
  }

  @override
  String get recipeNoNutrition => '暂无营养估算';

  @override
  String recipeCookware(Object items) {
    return '厨具：$items';
  }

  @override
  String get recipeImagePlaceholder => '成品图将在这里显示';

  @override
  String get recipeNoTags => '未设置标签';

  @override
  String recipeDifficultyValue(String value) {
    return '难度：$value';
  }

  @override
  String recipeDishTypeValue(String value) {
    return '菜型：$value';
  }

  @override
  String recipeVersionDate(String date) {
    return '保存于 $date';
  }

  @override
  String recipeOperationCount(int count) {
    return '$count 条修改';
  }

  @override
  String get recipeInvalidStepReference => '步骤引用了不存在的食材或前置步骤';

  @override
  String get recipeIngredientRequired => '请先填写食材名称';

  @override
  String get recipeInvalidNumber => '请填写有效的非负数字';

  @override
  String get recipeDiscardConfirmTitle => '放弃未保存修改？';

  @override
  String get recipeDiscardConfirmBody => '这会删除本机草稿，已保存的版本不会受影响。';

  @override
  String get recipeKeepEditing => '继续编辑';

  @override
  String get recipeDiscardConfirm => '放弃修改';

  @override
  String get recipeDeleteConfirmTitle => '删除这份菜谱？';

  @override
  String get recipeDeleteConfirmBody => '删除后不能恢复。';

  @override
  String get recipeDeleteConfirm => '确认删除';

  @override
  String get recipeCancel => '取消';

  @override
  String get recipeSaveSuccess => '已保存为新版本';

  @override
  String get recipeSearchNoResults => '没有找到标准食材，可以继续填写未收录食材';

  @override
  String get recipeAiAssisted => 'AI 协助';

  @override
  String get tasteCategory => '或选择食材分类';

  @override
  String get tastePreference => '偏好';

  @override
  String get tastePreferenceDelete => '删除偏好';

  @override
  String get tastePreferenceDeleteBody => '只删除这项明确选择，不改动其他口味和过敏设置；修改历史保留。';

  @override
  String get tasteIngredients => '食材偏好';

  @override
  String get tasteIngredientsIntro => '喜欢、不喜欢和忌口由你明确选择，不等于过敏。';

  @override
  String get tasteIngredientsEmpty => '还没有食材偏好';

  @override
  String get tastePreferenceAdd => '添加食材偏好';

  @override
  String get tasteIngredientSearch => '搜索标准食材';

  @override
  String get tasteSearch => '搜索';

  @override
  String get tasteSearchEmpty => '没有找到标准食材，请换一个名称搜索；不能保存自由文字。';

  @override
  String get tasteLiked => '喜欢';

  @override
  String get tasteDisliked => '不喜欢';

  @override
  String get tasteAvoided => '忌口';

  @override
  String get tasteUnset => '未设置';

  @override
  String get tasteTitle => '我的口味';

  @override
  String get tasteIntro => '只代表你明确设置的七项口味，不会从行为猜测你的偏好。';

  @override
  String get tasteReset => '恢复标准默认';

  @override
  String get tasteResetBody => '七项口味恢复为标准，重新标记为把握低；修改记录保留。';

  @override
  String get tasteManual => '你手动填写';

  @override
  String get tasteDefault => '标准默认';

  @override
  String get tasteWhy => '为什么';

  @override
  String get tasteHistory => '修改历史';

  @override
  String get tasteHistoryEmpty => '还没有修改记录';

  @override
  String get tasteHistoryReadonly => '只读查看原因和历史，暂不提供撤销或锁定。';

  @override
  String get tasteLocal => '菜系局部偏好';

  @override
  String get tasteLocalEmpty => '还没有菜系局部偏好';

  @override
  String get tasteLocalReadonly => '菜系对应的味型调整只读显示，暂不提供学习或编辑。';

  @override
  String get tasteActive => '生效';

  @override
  String get tasteReverted => '已撤销';

  @override
  String get tasteSalty => '咸';

  @override
  String get tasteSweet => '甜';

  @override
  String get tasteSour => '酸';

  @override
  String get tasteSpicy => '辣';

  @override
  String get tasteNumbing => '麻';

  @override
  String get tasteUmami => '鲜';

  @override
  String get tasteOily => '油';

  @override
  String get personalMeasuresTitle => '自家量具';

  @override
  String get personalMeasuresIntro =>
      '把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。可用于显示或确认录入；重新校准不会修改已保存菜谱。';

  @override
  String get personalMeasuresOffline => '离线：正在使用已缓存的量具；登记、修改和删除需要联网。';

  @override
  String get personalMeasuresAdd => '登记量具';

  @override
  String get personalMeasuresEmpty => '还没有登记量具';

  @override
  String get personalMeasuresDeleteTooltip => '删除量具';

  @override
  String get personalMeasuresDeleteTitle => '删除量具？';

  @override
  String personalMeasuresDeleteBody(Object name) {
    return '删除“$name”不会改动菜谱。';
  }

  @override
  String get personalMeasuresEdit => '修改量具';

  @override
  String get personalMeasuresRegister => '登记量具';

  @override
  String get personalMeasuresName => '量具名称';

  @override
  String get personalMeasuresKind => '种类';

  @override
  String get personalMeasuresCapacity => '满水容量（毫升）';

  @override
  String personalMeasuresCapacityValue(Object value) {
    return '$value 毫升';
  }

  @override
  String get personalMeasuresValidation => '名称需为 1–64 个字，容量需大于 0 且不超过 10000 毫升';

  @override
  String get personalMeasuresSpoon => '勺';

  @override
  String get personalMeasuresBowl => '碗';

  @override
  String get personalMeasuresCup => '杯';

  @override
  String get recipeMeasureModeTitle => '用量显示方式';

  @override
  String get recipeMeasureModeBase => '克/毫升';

  @override
  String get recipeMeasureModeStandard => '汤匙/茶匙';

  @override
  String get recipeMeasureModeHome => '自家量具';

  @override
  String get recipeMeasureChoose => '选择量具';

  @override
  String get recipeMeasureRefresh => '刷新我的量具';

  @override
  String get recipeMeasureManage => '登记自家量具';

  @override
  String get recipeMeasureModeNoHome => '还没有登记自家量具，请先到“我的”登记。';

  @override
  String get recipeMeasureDisplayOnly => '个人量具只改变显示，菜谱基础值未改变';

  @override
  String get recipeMeasureDisplaySource => '量具表达';

  @override
  String recipeMeasureNoDensity(String unit) {
    return '没有密度数据，保留$unit';
  }

  @override
  String get recipeMeasureGram => '克';

  @override
  String get recipeMeasureMillilitre => '毫升';

  @override
  String get recipeMeasureTablespoon => '汤匙';

  @override
  String get recipeMeasureTeaspoon => '茶匙';

  @override
  String get recipeMeasureApproximate => '约';

  @override
  String get cookingConstraintsTitle => '做菜约束';

  @override
  String get cookingConstraintsUnset => '未设置';

  @override
  String get cookingConstraintsLoadError => '做菜约束暂时无法读取';

  @override
  String get cookingConstraintsIntro => '做菜约束 · 仅作为家庭默认，不修改作者菜谱';

  @override
  String get cookingConstraintsSourceValue => '家庭做菜约束';

  @override
  String get cookingConstraintsBasis =>
      '来自你手动填写；未设置的项目为空。人数只用于新一次查看的默认份数，本次手动选择优先，作者配方和原始版本不变。厨具、时间与餐型仅保存，不在这里推荐或改写菜谱。';

  @override
  String get cookingConstraintsManual => '你手动设置';

  @override
  String get cookingConstraintsEdit => '设置做菜约束';

  @override
  String get cookingConstraintsClear => '清除做菜约束';

  @override
  String get cookingConstraintsClearTitle => '清除做菜约束？';

  @override
  String get cookingConstraintsClearBody => '人数、厨具、时间和餐型恢复为空。菜谱原始版本不会改变。';

  @override
  String get cookingConstraintsClearConfirm => '清除';

  @override
  String get cookingHouseholdEmpty => '人数未设置，菜谱沿用作者份数';

  @override
  String cookingHouseholdDefault(String count) {
    return '家庭默认：$count 人';
  }

  @override
  String cookingHouseholdHistory(String count) {
    return '$count 人';
  }

  @override
  String get cookingHouseholdInput => '家庭人数（留空沿用作者份数）';

  @override
  String get cookingEquipmentInput => '家里有哪些厨具';

  @override
  String get cookingEquipmentEmpty => '厨具未设置';

  @override
  String cookingEquipmentSummary(String names) {
    return '厨具：$names';
  }

  @override
  String get cookingMealTimesEmpty => '各餐可用时间未设置';

  @override
  String get cookingMealTemplatesEmpty => '餐型未设置';

  @override
  String get cookingMealInput => '每餐时间与餐型（留空清除）';

  @override
  String cookingMealTemplateHint(String types) {
    return '菜型用逗号分隔：$types。每项代表一道，可重复。';
  }

  @override
  String get cookingMealMinutesInput => '可用分钟';

  @override
  String cookingMealTemplateInput(String example) {
    return '菜型组合，例如 $example';
  }

  @override
  String cookingIntegerValidation(int minimum, int maximum) {
    return '请输入 $minimum～$maximum 的整数；留空清除';
  }

  @override
  String cookingTemplateValidation(int maximum) {
    return '请用上述菜型组合，最多 $maximum 道';
  }

  @override
  String get cookingWeekday => '工作日';

  @override
  String get cookingWeekend => '周末';

  @override
  String get cookingBreakfast => '早餐';

  @override
  String get cookingLunch => '午餐';

  @override
  String get cookingDinner => '晚餐';

  @override
  String get cookingDishMeat => '荤菜';

  @override
  String get cookingDishVegetable => '素菜';

  @override
  String get cookingDishSoup => '汤';

  @override
  String get cookingDishStaple => '主食';

  @override
  String get cookingDishOther => '其他';

  @override
  String get cookingListSeparator => '、';

  @override
  String cookingMealSlot(String day, String meal) {
    return '$day$meal';
  }

  @override
  String cookingMealTimeSummary(String slot, String minutes) {
    return '$slot：$minutes 分钟';
  }

  @override
  String cookingMealTemplateSummary(
    String slot,
    String count,
    String composition,
  ) {
    return '$slot：$count 道（$composition）';
  }

  @override
  String get personalMeasuresSummaryIntro => '你登记的量具，仅用于显示，不改变配方。';

  @override
  String get personalMeasuresManage => '管理个人量具';

  @override
  String personalMeasuresSummaryValue(String name, String capacity) {
    return '$name · $capacity 毫升';
  }

  @override
  String get allergyTitle => '本人过敏';

  @override
  String get allergyIntro => '仅本人手动填写 · 单独同意 · 加密保存。拒绝不影响普通口味。';

  @override
  String get allergyNotFilled => '未填写';

  @override
  String get allergyEmpty => '尚未填写本人过敏';

  @override
  String get allergyEdit => '设置本人过敏';

  @override
  String get allergyConsentTitle => '过敏信息单独同意';

  @override
  String get allergyConsentBody =>
      '只收集你手动选择的八类过敏原和标准食材，用于保存本人过敏设置及修改历史。当前值和历史加密保存，仅本人可见，不从行为或模型推断。可在设置的隐私入口撤回这项敏感同意，删除本人过敏、所有家庭成员、可识别私密历史及关联副本；重新同意从空状态开始。家庭成员首次添加时另行说明必要收集和儿童保护。拒绝不影响普通口味，不代表同意外部 AI 共享。';

  @override
  String get allergyRefuse => '暂不同意';

  @override
  String get allergyAgree => '单独同意';

  @override
  String get allergyUnavailable => '过敏设置暂不可用，授权或保存未确认，请重试';

  @override
  String get allergyPrivateUnavailable => '私密信息暂不可用；仍可在设置撤回同意';

  @override
  String get allergyHidden => '本机私密信息已隐藏，撤回尚未确认时请在设置重试';

  @override
  String get allergyHistory => '私密修改历史';

  @override
  String get allergyHistoryEmpty => '没有私密修改历史';

  @override
  String get allergyHistoryUnavailable => '私密历史暂不可用';

  @override
  String get allergyWhy => '为什么';

  @override
  String get allergyManual => '本人手动填写';

  @override
  String get allergyEditorTitle => '手动设置本人过敏';

  @override
  String get allergyDeleteIngredient => '删除食材';

  @override
  String get allergySearchLabel => '搜索标准食材（不保存自由文字）';

  @override
  String get allergySearch => '搜索食材';

  @override
  String get allergySearchUnavailable => '食材搜索暂不可用，请重试';

  @override
  String get allergySave => '保存过敏设置';

  @override
  String get allergySaveUnconfirmed => '保存未确认，请重新打开过敏设置后重试';

  @override
  String get allergyWithdrawEntry => '撤回敏感信息同意';

  @override
  String get allergyWithdrawDetail => '删除本人过敏、所有家庭成员和私密历史，保留普通口味';

  @override
  String get allergyWithdrawTitle => '撤回敏感信息同意？';

  @override
  String get allergyWithdrawBody =>
      '删除本人过敏、所有家庭成员、可识别私密修改历史及关联副本。普通口味、食材偏好和做菜约束保留；重新同意后从空状态开始。';

  @override
  String get allergyWithdrawConfirm => '撤回并删除';

  @override
  String get allergyWithdrawing => '撤回处理中，本机私密信息已隐藏';

  @override
  String get allergyWithdrawn => '敏感同意已撤回，过敏、家庭成员及私密历史已删除';

  @override
  String get allergyWithdrawUnconfirmed => '撤回尚未确认，请联网后重试；普通口味不受影响';
}
