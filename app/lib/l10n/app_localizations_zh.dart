// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '味谱';

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
  String recipeAllergens(String items, String incomplete) {
    return '过敏原：$items$incomplete';
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
  String get personalMeasuresTitle => '自家量具';

  @override
  String get personalMeasuresIntro =>
      '把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。只影响显示，不会修改菜谱。';

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
  String get recipeMeasureModeNoHome => '还没有登记自家量具，请先到“我的”登记。';

  @override
  String get recipeMeasureDisplayOnly => '个人量具只改变显示，菜谱基础值未改变';

  @override
  String get recipeMeasureNoDensity => '没有密度数据，保留克数';

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
}
