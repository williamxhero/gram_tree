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
}
