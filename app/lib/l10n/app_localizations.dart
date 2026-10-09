import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @networkConsentRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要先同意隐私政策'**
  String get networkConsentRequired;

  /// No description provided for @networkChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检查连接，在线功能需要联网'**
  String get networkChecking;

  /// No description provided for @networkConnected.
  ///
  /// In zh, this message translates to:
  /// **'服务已连接'**
  String get networkConnected;

  /// No description provided for @logoutUnfinishedCount.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 条内容未同步'**
  String logoutUnfinishedCount(int count);

  /// No description provided for @logoutRetainedExplanation.
  ///
  /// In zh, this message translates to:
  /// **'包括待同步、失败和冲突内容。退出后仍保留在这台设备，再次登录同一账号后可继续同步；其他账号无法查看或上传。'**
  String get logoutRetainedExplanation;

  /// No description provided for @logoutIdentityChanged.
  ///
  /// In zh, this message translates to:
  /// **'登录状态已改变，请重新操作'**
  String get logoutIdentityChanged;

  /// No description provided for @logoutViewSync.
  ///
  /// In zh, this message translates to:
  /// **'查看同步状态'**
  String get logoutViewSync;

  /// No description provided for @syncStatusTitle.
  ///
  /// In zh, this message translates to:
  /// **'同步状态'**
  String get syncStatusTitle;

  /// No description provided for @syncUnfinishedCount.
  ///
  /// In zh, this message translates to:
  /// **'未完成 {count} 条'**
  String syncUnfinishedCount(int count);

  /// No description provided for @syncCategoryCount.
  ///
  /// In zh, this message translates to:
  /// **'{category} {count} 条'**
  String syncCategoryCount(String category, int count);

  /// No description provided for @syncWaiting.
  ///
  /// In zh, this message translates to:
  /// **'待上传'**
  String get syncWaiting;

  /// No description provided for @syncDeferred.
  ///
  /// In zh, this message translates to:
  /// **'暂缓'**
  String get syncDeferred;

  /// No description provided for @syncLoginPaused.
  ///
  /// In zh, this message translates to:
  /// **'登录暂停'**
  String get syncLoginPaused;

  /// No description provided for @syncConflict.
  ///
  /// In zh, this message translates to:
  /// **'等待冲突选择'**
  String get syncConflict;

  /// No description provided for @syncFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get syncFailed;

  /// No description provided for @syncNever.
  ///
  /// In zh, this message translates to:
  /// **'尚未同步'**
  String get syncNever;

  /// No description provided for @syncLastSuccess.
  ///
  /// In zh, this message translates to:
  /// **'上次服务端确认：{time}'**
  String syncLastSuccess(String time);

  /// No description provided for @syncBasis.
  ///
  /// In zh, this message translates to:
  /// **'来自当前账号的本机持久队列；每条写入只计一次。上次成功只记录服务端确认的写入，不表示其余内容已全部同步。网页测试使用内存替身。'**
  String get syncBasis;

  /// No description provided for @syncQueueSource.
  ///
  /// In zh, this message translates to:
  /// **'本机队列记录'**
  String get syncQueueSource;

  /// No description provided for @syncRetryAction.
  ///
  /// In zh, this message translates to:
  /// **'重试可恢复项'**
  String get syncRetryAction;

  /// No description provided for @syncRetryError.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法重试，内容仍在本机，请稍后再试。'**
  String get syncRetryError;

  /// No description provided for @syncLoadingError.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取本机同步状态，请稍后重试。'**
  String get syncLoadingError;

  /// No description provided for @syncNetworkReason.
  ///
  /// In zh, this message translates to:
  /// **'网络或服务暂不可用；请恢复连接后重试。'**
  String get syncNetworkReason;

  /// No description provided for @syncDependencyReason.
  ///
  /// In zh, this message translates to:
  /// **'前置内容尚未确认；请先恢复前置内容的同步。'**
  String get syncDependencyReason;

  /// No description provided for @syncDependencyCycleReason.
  ///
  /// In zh, this message translates to:
  /// **'前置内容互相依赖；已保留内容，请联系支持处理。'**
  String get syncDependencyCycleReason;

  /// No description provided for @syncPermissionReason.
  ///
  /// In zh, this message translates to:
  /// **'权限或内容校验未通过；已保留内容，请检查权限或修改内容后另存，不会盲目重试。'**
  String get syncPermissionReason;

  /// No description provided for @syncExhaustedReason.
  ///
  /// In zh, this message translates to:
  /// **'重试次数已达上限；内容已保留，可恢复连接后手动重试。'**
  String get syncExhaustedReason;

  /// No description provided for @syncLoginReason.
  ///
  /// In zh, this message translates to:
  /// **'需要恢复当前账号登录，内容保留且不会上传给其他账号。'**
  String get syncLoginReason;

  /// No description provided for @syncConflictReason.
  ///
  /// In zh, this message translates to:
  /// **'需要先比较两份内容并选择；重试不会代替你的选择。'**
  String get syncConflictReason;

  /// No description provided for @syncUnknownReason.
  ///
  /// In zh, this message translates to:
  /// **'服务未接收这条内容；已保留，请检查内容或联系支持。'**
  String get syncUnknownReason;

  /// No description provided for @syncUploadingReason.
  ///
  /// In zh, this message translates to:
  /// **'写入正在上传；关闭后保留原 ID，重新打开会恢复确认，不会重复保存。'**
  String get syncUploadingReason;

  /// No description provided for @syncPendingReason.
  ///
  /// In zh, this message translates to:
  /// **'已保存在本机，等待上传确认。'**
  String get syncPendingReason;

  /// No description provided for @syncEventType.
  ///
  /// In zh, this message translates to:
  /// **'操作记录'**
  String get syncEventType;

  /// No description provided for @syncRecipeType.
  ///
  /// In zh, this message translates to:
  /// **'菜谱修改'**
  String get syncRecipeType;

  /// No description provided for @syncMeasureType.
  ///
  /// In zh, this message translates to:
  /// **'个人量具'**
  String get syncMeasureType;

  /// No description provided for @syncOtherType.
  ///
  /// In zh, this message translates to:
  /// **'离线写入'**
  String get syncOtherType;

  /// No description provided for @syncItemIdentity.
  ///
  /// In zh, this message translates to:
  /// **'{type} · 条目 {sequence}'**
  String syncItemIdentity(String type, int sequence);

  /// No description provided for @syncResolveConflict.
  ///
  /// In zh, this message translates to:
  /// **'查看并选择'**
  String get syncResolveConflict;

  /// No description provided for @syncConflictAdapterMissing.
  ///
  /// In zh, this message translates to:
  /// **'此类型的选择入口暂不可用，内容已保留，请稍后再试。'**
  String get syncConflictAdapterMissing;

  /// Current account's writes awaiting synchronization.
  ///
  /// In zh, this message translates to:
  /// **'待同步 {count} 条'**
  String syncPendingCount(int count);

  /// No description provided for @syncRetryExhaustedCount.
  ///
  /// In zh, this message translates to:
  /// **'重试次数已达上限，已保留 {count} 条内容'**
  String syncRetryExhaustedCount(int count);

  /// No description provided for @syncDependencyFailedCount.
  ///
  /// In zh, this message translates to:
  /// **'前置写入失败，已保留 {count} 条内容'**
  String syncDependencyFailedCount(int count);

  /// No description provided for @syncDependencyConflictCount.
  ///
  /// In zh, this message translates to:
  /// **'前置写入存在冲突，{count} 条暂缓同步'**
  String syncDependencyConflictCount(int count);

  /// No description provided for @syncDependencyMissingCount.
  ///
  /// In zh, this message translates to:
  /// **'依赖写入尚未到达，{count} 条暂缓同步'**
  String syncDependencyMissingCount(int count);

  /// No description provided for @syncDependencyCycleCount.
  ///
  /// In zh, this message translates to:
  /// **'依赖写入存在循环，已保留 {count} 条内容'**
  String syncDependencyCycleCount(int count);

  /// No description provided for @syncLegacyOwnerUnknownCount.
  ///
  /// In zh, this message translates to:
  /// **'本机有 {count} 条旧写入无法确定原账号，已隔离保留，不会上传'**
  String syncLegacyOwnerUnknownCount(int count);

  /// No description provided for @syncLegacyRejectedCount.
  ///
  /// In zh, this message translates to:
  /// **'本机保留 {count} 条旧拒收记录，仅有拒收凭据，无法恢复原内容'**
  String syncLegacyRejectedCount(int count);

  /// No description provided for @networkUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'需要联网：暂时连接不到服务，请检查网络；本机内容仍可使用。'**
  String get networkUnavailable;

  /// No description provided for @snapshotCapacityRejected.
  ///
  /// In zh, this message translates to:
  /// **'本机缓存空间不足，此版本未离线保存；菜单和正在做的内容已保留。'**
  String get snapshotCapacityRejected;

  /// No description provided for @snapshotProtectedOverLimit.
  ///
  /// In zh, this message translates to:
  /// **'受保护的菜谱超出缓存容量，内容已保留；请释放不再需要的保护。'**
  String get snapshotProtectedOverLimit;

  /// No description provided for @recipeAnswerBasis.
  ///
  /// In zh, this message translates to:
  /// **'这是一般经验，还没有足够记录验证'**
  String get recipeAnswerBasis;

  /// No description provided for @recipeAnswerAnswered.
  ///
  /// In zh, this message translates to:
  /// **'已回答 · 一般经验'**
  String get recipeAnswerAnswered;

  /// No description provided for @recipeAnswerUncertain.
  ///
  /// In zh, this message translates to:
  /// **'不确定 · 一般经验'**
  String get recipeAnswerUncertain;

  /// No description provided for @recipeAnswerCannotAnswer.
  ///
  /// In zh, this message translates to:
  /// **'无法回答 · 一般经验'**
  String get recipeAnswerCannotAnswer;

  /// No description provided for @recipeAnswerUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'能力不可用 · 一般经验'**
  String get recipeAnswerUnavailable;

  /// No description provided for @recipeAnswerBudget.
  ///
  /// In zh, this message translates to:
  /// **'月预算已用完'**
  String get recipeAnswerBudget;

  /// No description provided for @recipeAnswerQuota.
  ///
  /// In zh, this message translates to:
  /// **'今日解释配额已用完'**
  String get recipeAnswerQuota;

  /// No description provided for @recipeAnswerTimeout.
  ///
  /// In zh, this message translates to:
  /// **'模型响应超时'**
  String get recipeAnswerTimeout;

  /// No description provided for @recipeAnswerDisabled.
  ///
  /// In zh, this message translates to:
  /// **'模型已停用'**
  String get recipeAnswerDisabled;

  /// No description provided for @recipeAnswerNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'模型暂未配置'**
  String get recipeAnswerNotConfigured;

  /// No description provided for @recipeAnswerNetwork.
  ///
  /// In zh, this message translates to:
  /// **'模型或网络暂时不可用'**
  String get recipeAnswerNetwork;

  /// No description provided for @recipeAnswerUnavailableConclusion.
  ///
  /// In zh, this message translates to:
  /// **'菜谱解释（explain）：{reason}。'**
  String recipeAnswerUnavailableConclusion(String reason);

  /// No description provided for @recipeAnswerSource.
  ///
  /// In zh, this message translates to:
  /// **'AI 估算 · 菜谱解释'**
  String get recipeAnswerSource;

  /// No description provided for @recipeAnswerClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭解释'**
  String get recipeAnswerClose;

  /// No description provided for @recipeAnswerQuestion.
  ///
  /// In zh, this message translates to:
  /// **'问题：{question}'**
  String recipeAnswerQuestion(String question);

  /// No description provided for @recipeAnswerContinue.
  ///
  /// In zh, this message translates to:
  /// **'查看、表单编辑和规则换算仍可使用；问题已保留，可以重试。'**
  String get recipeAnswerContinue;

  /// No description provided for @recipeAnswerVersion.
  ///
  /// In zh, this message translates to:
  /// **'明细 · 第 {version} 版；解释不会自动修改菜谱。'**
  String recipeAnswerVersion(int version);

  /// No description provided for @recipeAnswerAllergens.
  ///
  /// In zh, this message translates to:
  /// **'过敏原：{allergens}'**
  String recipeAnswerAllergens(String allergens);

  /// No description provided for @recipeAnswerReplacementAllergens.
  ///
  /// In zh, this message translates to:
  /// **'替换食材过敏原：{allergens}'**
  String recipeAnswerReplacementAllergens(String allergens);

  /// No description provided for @recipeAnswerIncompleteAllergens.
  ///
  /// In zh, this message translates to:
  /// **'过敏信息可能不完整，请核对实际食材。'**
  String get recipeAnswerIncompleteAllergens;

  /// No description provided for @recipeAnswerTitle.
  ///
  /// In zh, this message translates to:
  /// **'问这版的做法'**
  String get recipeAnswerTitle;

  /// No description provided for @recipeAnswerSemantics.
  ///
  /// In zh, this message translates to:
  /// **'问这版的做法；只提供一般经验，不改动菜谱'**
  String get recipeAnswerSemantics;

  /// No description provided for @recipeAnswerInput.
  ///
  /// In zh, this message translates to:
  /// **'厨房问题'**
  String get recipeAnswerInput;

  /// No description provided for @recipeAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：这一步为什么要炒熟？'**
  String get recipeAnswerHint;

  /// No description provided for @recipeAnswerBusy.
  ///
  /// In zh, this message translates to:
  /// **'正在解释…'**
  String get recipeAnswerBusy;

  /// No description provided for @recipeAnswerRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试解释'**
  String get recipeAnswerRetry;

  /// No description provided for @recipeAnswerSubmit.
  ///
  /// In zh, this message translates to:
  /// **'查看解释'**
  String get recipeAnswerSubmit;

  /// No description provided for @recipeAnswerExperience.
  ///
  /// In zh, this message translates to:
  /// **'一般经验'**
  String get recipeAnswerExperience;

  /// No description provided for @recipeAnswerWhy.
  ///
  /// In zh, this message translates to:
  /// **'为什么 · 明细'**
  String get recipeAnswerWhy;

  /// App name shown in the task switcher and web tab.
  ///
  /// In zh, this message translates to:
  /// **'味谱'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get tabToday;

  /// No description provided for @tabDiscover.
  ///
  /// In zh, this message translates to:
  /// **'发现'**
  String get tabDiscover;

  /// Semantics label of the center ＋ primary button.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get tabCreate;

  /// No description provided for @tabRecords.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get tabRecords;

  /// No description provided for @tabMe.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get tabMe;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'今天还没有安排'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'这里会显示今天要做的菜。点下方的＋开始添加。'**
  String get todayEmptyBody;

  /// No description provided for @todayEmptyAction.
  ///
  /// In zh, this message translates to:
  /// **'添加第一道菜谱'**
  String get todayEmptyAction;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有可发现的内容'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'以后这里会推荐适合你的菜谱和做法。'**
  String get discoverEmptyBody;

  /// No description provided for @createEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'想做点什么？'**
  String get createEmptyTitle;

  /// No description provided for @createEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'以后可以在这里录入菜谱、记录一次做菜。'**
  String get createEmptyBody;

  /// No description provided for @recordsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有做菜记录'**
  String get recordsEmptyTitle;

  /// No description provided for @recordsEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'每次做完菜后的记录和心得会保存在这里。'**
  String get recordsEmptyBody;

  /// No description provided for @meEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get meEmptyTitle;

  /// No description provided for @meEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'做过的菜、口味档案会出现在这里。'**
  String get meEmptyBody;

  /// Entry on the ＋ page, shown only when the server enables feature receipt_scan.
  ///
  /// In zh, this message translates to:
  /// **'拍小票记价格'**
  String get featureReceiptScan;

  /// No description provided for @comingSoon.
  ///
  /// In zh, this message translates to:
  /// **'这个功能正在准备中'**
  String get comingSoon;

  /// No description provided for @consentEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用味谱'**
  String get consentEyebrow;

  /// No description provided for @consentTitle.
  ///
  /// In zh, this message translates to:
  /// **'开始之前，先说清楚我们会用到什么'**
  String get consentTitle;

  /// No description provided for @consentCollectLabel.
  ///
  /// In zh, this message translates to:
  /// **'我们会收集'**
  String get consentCollectLabel;

  /// No description provided for @consentCollect1.
  ///
  /// In zh, this message translates to:
  /// **'登录用的邮箱，或 Apple 提供的中转邮箱'**
  String get consentCollect1;

  /// No description provided for @consentCollect2.
  ///
  /// In zh, this message translates to:
  /// **'你写的菜谱、做菜记录和口味设置，用来给你推荐和换算'**
  String get consentCollect2;

  /// No description provided for @consentCollect3.
  ///
  /// In zh, this message translates to:
  /// **'出错时的崩溃信息，不含菜谱和口味内容'**
  String get consentCollect3;

  /// No description provided for @consentNotLabel.
  ///
  /// In zh, this message translates to:
  /// **'我们不会'**
  String get consentNotLabel;

  /// No description provided for @consentNot1.
  ///
  /// In zh, this message translates to:
  /// **'放广告，或把你的数据卖给别人'**
  String get consentNot1;

  /// No description provided for @consentNot2.
  ///
  /// In zh, this message translates to:
  /// **'在你用到相机、麦克风之前申请权限'**
  String get consentNot2;

  /// No description provided for @consentLinksPrefix.
  ///
  /// In zh, this message translates to:
  /// **'完整内容见'**
  String get consentLinksPrefix;

  /// No description provided for @termsTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyTitle;

  /// No description provided for @consentAgree.
  ///
  /// In zh, this message translates to:
  /// **'同意并继续'**
  String get consentAgree;

  /// No description provided for @consentDecline.
  ///
  /// In zh, this message translates to:
  /// **'不同意'**
  String get consentDecline;

  /// No description provided for @consentExplainTitle.
  ///
  /// In zh, this message translates to:
  /// **'不同意的话，味谱没法工作'**
  String get consentExplainTitle;

  /// No description provided for @consentExplainLead.
  ///
  /// In zh, this message translates to:
  /// **'这几项是最少需要的：'**
  String get consentExplainLead;

  /// No description provided for @consentExplain1.
  ///
  /// In zh, this message translates to:
  /// **'邮箱：登录和找回账号'**
  String get consentExplain1;

  /// No description provided for @consentExplain2.
  ///
  /// In zh, this message translates to:
  /// **'你的菜谱和记录：保存到云端，换手机不丢'**
  String get consentExplain2;

  /// No description provided for @consentExplain3.
  ///
  /// In zh, this message translates to:
  /// **'崩溃信息：修复闪退，可以随时在设置里撤回'**
  String get consentExplain3;

  /// No description provided for @consentExplainTail.
  ///
  /// In zh, this message translates to:
  /// **'如果仍不同意，App 会退出，不保存任何信息。下次打开时会再问你。'**
  String get consentExplainTail;

  /// No description provided for @consentExplainQuit.
  ///
  /// In zh, this message translates to:
  /// **'仍不同意，退出'**
  String get consentExplainQuit;

  /// No description provided for @consentUpdatedEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策已更新'**
  String get consentUpdatedEyebrow;

  /// No description provided for @consentUpdatedTitle.
  ///
  /// In zh, this message translates to:
  /// **'这次改了什么'**
  String get consentUpdatedTitle;

  /// No description provided for @consentUpdatedVersion.
  ///
  /// In zh, this message translates to:
  /// **'{from} → {to}'**
  String consentUpdatedVersion(String from, String to);

  /// No description provided for @consentUpdatedTail.
  ///
  /// In zh, this message translates to:
  /// **'重新同意后才能继续使用。'**
  String get consentUpdatedTail;

  /// No description provided for @consentUpdatedAgree.
  ///
  /// In zh, this message translates to:
  /// **'同意新版本'**
  String get consentUpdatedAgree;

  /// No description provided for @goodbyeTitle.
  ///
  /// In zh, this message translates to:
  /// **'你没有同意隐私政策'**
  String get goodbyeTitle;

  /// No description provided for @goodbyeBody.
  ///
  /// In zh, this message translates to:
  /// **'味谱没有收集任何信息。现在可以关掉 App 了，下次打开时会再问你。'**
  String get goodbyeBody;

  /// No description provided for @goodbyeReconsider.
  ///
  /// In zh, this message translates to:
  /// **'重新考虑'**
  String get goodbyeReconsider;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录味谱'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'第一次用会自动创建账号。'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get emailLabel;

  /// No description provided for @sendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendCode;

  /// No description provided for @or.
  ///
  /// In zh, this message translates to:
  /// **'或'**
  String get or;

  /// No description provided for @appleSignIn.
  ///
  /// In zh, this message translates to:
  /// **'通过 Apple 登录'**
  String get appleSignIn;

  /// No description provided for @loginFooter.
  ///
  /// In zh, this message translates to:
  /// **'登录即表示你已同意用户协议和隐私政策。'**
  String get loginFooter;

  /// No description provided for @codeTitle.
  ///
  /// In zh, this message translates to:
  /// **'输入验证码'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In zh, this message translates to:
  /// **'已发到 {email}，{minutes} 分钟内有效。'**
  String codeSentTo(String email, int minutes);

  /// No description provided for @codeFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'6 位验证码'**
  String get codeFieldLabel;

  /// No description provided for @resendIn.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒后可以重新发送'**
  String resendIn(int seconds);

  /// No description provided for @resend.
  ///
  /// In zh, this message translates to:
  /// **'重新发送'**
  String get resend;

  /// No description provided for @codeHelp.
  ///
  /// In zh, this message translates to:
  /// **'收不到？看看垃圾邮件，或返回检查邮箱是否填对。'**
  String get codeHelp;

  /// No description provided for @sessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已失效，请重新登录'**
  String get sessionExpired;

  /// No description provided for @meEdit.
  ///
  /// In zh, this message translates to:
  /// **'改昵称'**
  String get meEdit;

  /// No description provided for @meNicknameTitle.
  ///
  /// In zh, this message translates to:
  /// **'改昵称'**
  String get meNicknameTitle;

  /// No description provided for @meNicknameHint.
  ///
  /// In zh, this message translates to:
  /// **'最多 {max} 个字'**
  String meNicknameHint(int max);

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @settingsAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get settingsAccount;

  /// No description provided for @settingsIdentities.
  ///
  /// In zh, this message translates to:
  /// **'登录方式'**
  String get settingsIdentities;

  /// No description provided for @settingsTimezone.
  ///
  /// In zh, this message translates to:
  /// **'时区'**
  String get settingsTimezone;

  /// No description provided for @settingsPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私'**
  String get settingsPrivacy;

  /// No description provided for @settingsWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'撤回同意'**
  String get settingsWithdraw;

  /// No description provided for @settingsProductAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'产品改进统计'**
  String get settingsProductAnalytics;

  /// No description provided for @settingsProductAnalyticsDetail.
  ///
  /// In zh, this message translates to:
  /// **'页面访问、入口点击、加载耗时；不含菜谱内容、口味档案、过敏和健康信息，同意隐私政策后才采集'**
  String get settingsProductAnalyticsDetail;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'退出这台设备的登录？其他设备不受影响。'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'注销账号'**
  String get deleteAccount;

  /// No description provided for @openFullText.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器里看完整版'**
  String get openFullText;

  /// No description provided for @identityEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get identityEmail;

  /// No description provided for @identityApple.
  ///
  /// In zh, this message translates to:
  /// **'Apple'**
  String get identityApple;

  /// No description provided for @identityNotBound.
  ///
  /// In zh, this message translates to:
  /// **'未绑定'**
  String get identityNotBound;

  /// No description provided for @identitiesHint.
  ///
  /// In zh, this message translates to:
  /// **'多绑一种方式，原来的方式不能用时还能登录。以后加手机号、微信也不影响你的菜谱和记录。'**
  String get identitiesHint;

  /// No description provided for @bindEmail.
  ///
  /// In zh, this message translates to:
  /// **'绑定邮箱'**
  String get bindEmail;

  /// No description provided for @bindApple.
  ///
  /// In zh, this message translates to:
  /// **'绑定 Apple'**
  String get bindApple;

  /// No description provided for @bindDone.
  ///
  /// In zh, this message translates to:
  /// **'已绑定'**
  String get bindDone;

  /// No description provided for @withdrawBody.
  ///
  /// In zh, this message translates to:
  /// **'撤回后，味谱会立刻停止收集信息、关闭崩溃上报，并退出登录。'**
  String get withdrawBody;

  /// No description provided for @withdrawDataLabel.
  ///
  /// In zh, this message translates to:
  /// **'已存的数据'**
  String get withdrawDataLabel;

  /// No description provided for @withdrawDataBody.
  ///
  /// In zh, this message translates to:
  /// **'撤回不会删除已保存的菜谱和记录。想拿走数据，可以先导出（即将提供）；想彻底删除，请注销账号。'**
  String get withdrawDataBody;

  /// No description provided for @withdrawConfirm.
  ///
  /// In zh, this message translates to:
  /// **'撤回并退出'**
  String get withdrawConfirm;

  /// No description provided for @deleteStepVerify.
  ///
  /// In zh, this message translates to:
  /// **'先确认是你本人'**
  String get deleteStepVerify;

  /// No description provided for @deleteVerifyEmail.
  ///
  /// In zh, this message translates to:
  /// **'验证码会发到 {email}。'**
  String deleteVerifyEmail(String email);

  /// No description provided for @deleteVerifyApple.
  ///
  /// In zh, this message translates to:
  /// **'通过 Apple 重新验证'**
  String get deleteVerifyApple;

  /// No description provided for @deleteVerifyWindow.
  ///
  /// In zh, this message translates to:
  /// **'验证后 {minutes} 分钟内完成注销。'**
  String deleteVerifyWindow(int minutes);

  /// No description provided for @deleteWhatTitle.
  ///
  /// In zh, this message translates to:
  /// **'这些会被删除'**
  String get deleteWhatTitle;

  /// No description provided for @deleteWhat1.
  ///
  /// In zh, this message translates to:
  /// **'昵称和登录方式（邮箱、Apple）'**
  String get deleteWhat1;

  /// No description provided for @deleteWhat2.
  ///
  /// In zh, this message translates to:
  /// **'你的同意记录'**
  String get deleteWhat2;

  /// No description provided for @deleteWhat3.
  ///
  /// In zh, this message translates to:
  /// **'和 Apple 账号的授权关联会被解除'**
  String get deleteWhat3;

  /// No description provided for @deleteWhatTail.
  ///
  /// In zh, this message translates to:
  /// **'确认后立即退出，账号不能再登录；{days} 个工作日内删除完毕，无法恢复。'**
  String deleteWhatTail(int days);

  /// No description provided for @deleteCheck.
  ///
  /// In zh, this message translates to:
  /// **'我已了解，确认注销'**
  String get deleteCheck;

  /// No description provided for @deleteDone.
  ///
  /// In zh, this message translates to:
  /// **'已申请注销，账号不能再登录'**
  String get deleteDone;

  /// No description provided for @permissionNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要使用{label}'**
  String permissionNeeded(String label);

  /// No description provided for @permissionContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get permissionContinue;

  /// No description provided for @permissionNotNow.
  ///
  /// In zh, this message translates to:
  /// **'暂不'**
  String get permissionNotNow;

  /// No description provided for @permissionUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'{feature}不可用'**
  String permissionUnavailableTitle(String feature);

  /// No description provided for @permissionUnavailableBody.
  ///
  /// In zh, this message translates to:
  /// **'你没有允许使用{label}。其他功能不受影响。'**
  String permissionUnavailableBody(String label);

  /// No description provided for @permissionOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'去系统设置打开'**
  String get permissionOpenSettings;

  /// 上次更新时间
  ///
  /// In zh, this message translates to:
  /// **'上次更新于 {time}'**
  String compositionLastUpdatedAt(String time);

  /// No description provided for @myRecipes.
  ///
  /// In zh, this message translates to:
  /// **'我的菜谱'**
  String get myRecipes;

  /// No description provided for @myRecipesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理私有菜谱和版本历史'**
  String get myRecipesSubtitle;

  /// No description provided for @newRecipe.
  ///
  /// In zh, this message translates to:
  /// **'新建菜谱'**
  String get newRecipe;

  /// No description provided for @viewMyRecipes.
  ///
  /// In zh, this message translates to:
  /// **'查看我的菜谱'**
  String get viewMyRecipes;

  /// No description provided for @recipeEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有菜谱'**
  String get recipeEmptyTitle;

  /// No description provided for @recipeEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'把常做的一道菜写下来，之后可以继续改良。'**
  String get recipeEmptyBody;

  /// No description provided for @recipeLoadError.
  ///
  /// In zh, this message translates to:
  /// **'菜谱暂时加载不了'**
  String get recipeLoadError;

  /// No description provided for @recipeLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get recipeLoadMore;

  /// No description provided for @recipeLoadMoreRetry.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，重试'**
  String get recipeLoadMoreRetry;

  /// No description provided for @recipeRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get recipeRetry;

  /// No description provided for @recipeName.
  ///
  /// In zh, this message translates to:
  /// **'菜名'**
  String get recipeName;

  /// No description provided for @recipeContinueEdit.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑菜谱'**
  String get recipeContinueEdit;

  /// No description provided for @recipeFood.
  ///
  /// In zh, this message translates to:
  /// **'食材'**
  String get recipeFood;

  /// No description provided for @recipeSearchOrFill.
  ///
  /// In zh, this message translates to:
  /// **'搜索或填写食材'**
  String get recipeSearchOrFill;

  /// No description provided for @recipeQuantity.
  ///
  /// In zh, this message translates to:
  /// **'用量'**
  String get recipeQuantity;

  /// No description provided for @recipeUnit.
  ///
  /// In zh, this message translates to:
  /// **'单位（克、毫升、个、勺）'**
  String get recipeUnit;

  /// No description provided for @recipePreparationGroup.
  ///
  /// In zh, this message translates to:
  /// **'处理方式和分组'**
  String get recipePreparationGroup;

  /// No description provided for @recipeSteps.
  ///
  /// In zh, this message translates to:
  /// **'步骤'**
  String get recipeSteps;

  /// No description provided for @recipeInstruction.
  ///
  /// In zh, this message translates to:
  /// **'步骤说明'**
  String get recipeInstruction;

  /// No description provided for @recipeWhy.
  ///
  /// In zh, this message translates to:
  /// **'为什么这样做（可选）'**
  String get recipeWhy;

  /// No description provided for @recipeChangeNote.
  ///
  /// In zh, this message translates to:
  /// **'这次改了什么'**
  String get recipeChangeNote;

  /// No description provided for @recipeSaveVersion.
  ///
  /// In zh, this message translates to:
  /// **'保存为新版本'**
  String get recipeSaveVersion;

  /// No description provided for @recipeSaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get recipeSaving;

  /// No description provided for @recipeDiscardDraft.
  ///
  /// In zh, this message translates to:
  /// **'放弃草稿'**
  String get recipeDiscardDraft;

  /// No description provided for @recipeDishRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写菜名'**
  String get recipeDishRequired;

  /// No description provided for @recipeSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String recipeSaveFailed(String error);

  /// No description provided for @recipeRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复未保存修改？'**
  String get recipeRestoreTitle;

  /// No description provided for @recipeRestoreBody.
  ///
  /// In zh, this message translates to:
  /// **'上次编辑还有未保存内容。要恢复这份草稿吗？'**
  String get recipeRestoreBody;

  /// No description provided for @recipeDiscardDraftAction.
  ///
  /// In zh, this message translates to:
  /// **'放弃草稿'**
  String get recipeDiscardDraftAction;

  /// No description provided for @recipeRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get recipeRestore;

  /// No description provided for @recipeAuthorVersion.
  ///
  /// In zh, this message translates to:
  /// **'第 {version} 版 · {servings} 份'**
  String recipeAuthorVersion(int version, int servings);

  /// No description provided for @recipeDuration.
  ///
  /// In zh, this message translates to:
  /// **'总时长 {total} 分钟 · 动手 {active} 分钟'**
  String recipeDuration(int total, int active);

  /// No description provided for @recipeDurationServingNote.
  ///
  /// In zh, this message translates to:
  /// **'按 {servings} 份重新估算：步骤时长和火候不随份数变化，总时长和动手时长不变。'**
  String recipeDurationServingNote(int servings);

  /// No description provided for @recipeDurationBatchNote.
  ///
  /// In zh, this message translates to:
  /// **'份量变大后可能要分批下锅，实际用时会更长，以成熟判断为准。'**
  String get recipeDurationBatchNote;

  /// No description provided for @recipeDurationMoldNote.
  ///
  /// In zh, this message translates to:
  /// **'换模具后烘烤时间不按底面积比例放大，时长按原步骤估算，以成熟判断为准。'**
  String get recipeDurationMoldNote;

  /// No description provided for @recipeAllergens.
  ///
  /// In zh, this message translates to:
  /// **'过敏原：{items}{incomplete}'**
  String recipeAllergens(String items, String incomplete);

  /// No description provided for @recipeSafetyTitle.
  ///
  /// In zh, this message translates to:
  /// **'食品安全提醒'**
  String get recipeSafetyTitle;

  /// No description provided for @recipeSafetyCheck.
  ///
  /// In zh, this message translates to:
  /// **'检查食品安全'**
  String get recipeSafetyCheck;

  /// No description provided for @recipeSafetyChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检查……'**
  String get recipeSafetyChecking;

  /// No description provided for @recipeSafetySaveBlocked.
  ///
  /// In zh, this message translates to:
  /// **'食品安全检查未通过，请调整菜谱后再保存。'**
  String get recipeSafetySaveBlocked;

  /// No description provided for @recipeSafetyHighRisk.
  ///
  /// In zh, this message translates to:
  /// **'高风险：请谨慎处理，不能只依赖计时或颜色判断。'**
  String get recipeSafetyHighRisk;

  /// No description provided for @recipeSafetyWarning.
  ///
  /// In zh, this message translates to:
  /// **'食品安全警告'**
  String get recipeSafetyWarning;

  /// No description provided for @recipeSafetyInfo.
  ///
  /// In zh, this message translates to:
  /// **'食品安全提示'**
  String get recipeSafetyInfo;

  /// No description provided for @recipeSafetyNoFindings.
  ///
  /// In zh, this message translates to:
  /// **'暂未发现需要额外提醒的安全规则。'**
  String get recipeSafetyNoFindings;

  /// No description provided for @recipeSafetyLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在检查食品安全……'**
  String get recipeSafetyLoading;

  /// No description provided for @recipeSafetyAwaitingCheck.
  ///
  /// In zh, this message translates to:
  /// **'菜谱已修改，等待重新检查食品安全。保存前必须完成检查。'**
  String get recipeSafetyAwaitingCheck;

  /// No description provided for @recipeSafetyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这份旧版本没有保存安全检查结果，请结合食材和步骤谨慎判断。'**
  String get recipeSafetyUnavailable;

  /// No description provided for @recipeSafetyStale.
  ///
  /// In zh, this message translates to:
  /// **'安全规则已更新，以下结果可能已过期；请重新检查后再依赖它。'**
  String get recipeSafetyStale;

  /// No description provided for @recipeSafetyError.
  ///
  /// In zh, this message translates to:
  /// **'食品安全检查暂时失败：{error}'**
  String recipeSafetyError(String error);

  /// No description provided for @recipeSafetyRulesVersion.
  ///
  /// In zh, this message translates to:
  /// **'安全规则版本：{version}'**
  String recipeSafetyRulesVersion(String version);

  /// No description provided for @recipeSafetyThreshold.
  ///
  /// In zh, this message translates to:
  /// **'中心温度至少 {temperature}°C'**
  String recipeSafetyThreshold(String temperature);

  /// No description provided for @recipeSafetyRest.
  ///
  /// In zh, this message translates to:
  /// **'静置至少 {minutes} 分钟'**
  String recipeSafetyRest(int minutes);

  /// No description provided for @recipeSafetySteps.
  ///
  /// In zh, this message translates to:
  /// **'关联步骤：{steps}'**
  String recipeSafetySteps(String steps);

  /// No description provided for @recipeSafetyClaims.
  ///
  /// In zh, this message translates to:
  /// **'禁止用语：{claims}。{basis}'**
  String recipeSafetyClaims(String claims, String basis);

  /// No description provided for @recipeSafetyClaimRewrite.
  ///
  /// In zh, this message translates to:
  /// **'请改写为对做法的客观描述。'**
  String get recipeSafetyClaimRewrite;

  /// No description provided for @recipeAllergenTitle.
  ///
  /// In zh, this message translates to:
  /// **'过敏原提示'**
  String get recipeAllergenTitle;

  /// No description provided for @recipeAllergenNone.
  ///
  /// In zh, this message translates to:
  /// **'未检测到已知过敏原'**
  String get recipeAllergenNone;

  /// No description provided for @recipeAllergenIncompleteBasis.
  ///
  /// In zh, this message translates to:
  /// **'含有未收录食材，过敏原信息可能不完整。'**
  String get recipeAllergenIncompleteBasis;

  /// No description provided for @recipeReplacementAllergens.
  ///
  /// In zh, this message translates to:
  /// **'替代品“{name}”的过敏原：{allergens}{incomplete}'**
  String recipeReplacementAllergens(
    String name,
    String allergens,
    String incomplete,
  );

  /// No description provided for @recipeNutrition.
  ///
  /// In zh, this message translates to:
  /// **'每份营养：估算值{incomplete}'**
  String recipeNutrition(String incomplete);

  /// No description provided for @recipeIngredients.
  ///
  /// In zh, this message translates to:
  /// **'食材'**
  String get recipeIngredients;

  /// No description provided for @recipeStepsTitle.
  ///
  /// In zh, this message translates to:
  /// **'步骤'**
  String get recipeStepsTitle;

  /// No description provided for @recipeOptional.
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get recipeOptional;

  /// No description provided for @recipeAddPhoto.
  ///
  /// In zh, this message translates to:
  /// **'添加成品图'**
  String get recipeAddPhoto;

  /// No description provided for @recipeTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍一张成品图'**
  String get recipeTakePhoto;

  /// No description provided for @recipePhotoAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可以从相册选择成品图'**
  String get recipePhotoAvailable;

  /// No description provided for @recipePhotoDenied.
  ///
  /// In zh, this message translates to:
  /// **'相册权限未开启，菜谱编辑不受影响'**
  String get recipePhotoDenied;

  /// No description provided for @recipeCameraAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可以拍摄成品图'**
  String get recipeCameraAvailable;

  /// No description provided for @recipeCameraDenied.
  ///
  /// In zh, this message translates to:
  /// **'相机权限未开启，菜谱编辑不受影响'**
  String get recipeCameraDenied;

  /// No description provided for @recipeHistory.
  ///
  /// In zh, this message translates to:
  /// **'查看版本历史'**
  String get recipeHistory;

  /// No description provided for @recipeDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除这份私有菜谱'**
  String get recipeDelete;

  /// No description provided for @recipeNoHistory.
  ///
  /// In zh, this message translates to:
  /// **'还没有版本历史'**
  String get recipeNoHistory;

  /// No description provided for @recipeVersionTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {version} 版{ai}'**
  String recipeVersionTitle(int version, String ai);

  /// No description provided for @recipeNoChangeNote.
  ///
  /// In zh, this message translates to:
  /// **'未填写修改说明'**
  String get recipeNoChangeNote;

  /// No description provided for @recipeRationale.
  ///
  /// In zh, this message translates to:
  /// **'为什么这样做'**
  String get recipeRationale;

  /// No description provided for @recipeKeyPoint.
  ///
  /// In zh, this message translates to:
  /// **'要点'**
  String get recipeKeyPoint;

  /// No description provided for @recipeUnnamedIngredient.
  ///
  /// In zh, this message translates to:
  /// **'未收录食材'**
  String get recipeUnnamedIngredient;

  /// No description provided for @recipeCompleteStep.
  ///
  /// In zh, this message translates to:
  /// **'完成这一步'**
  String get recipeCompleteStep;

  /// No description provided for @recipeNotFound.
  ///
  /// In zh, this message translates to:
  /// **'菜谱不存在或你没有权限查看'**
  String get recipeNotFound;

  /// No description provided for @recipeMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String recipeMinutes(int minutes);

  /// No description provided for @recipeDraftSaved.
  ///
  /// In zh, this message translates to:
  /// **'草稿已保存'**
  String get recipeDraftSaved;

  /// No description provided for @recipeCameraPermission.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get recipeCameraPermission;

  /// No description provided for @recipePhotoPermission.
  ///
  /// In zh, this message translates to:
  /// **'从相册选图'**
  String get recipePhotoPermission;

  /// No description provided for @recipeComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'图片选择功能正在准备中'**
  String get recipeComingSoon;

  /// No description provided for @recipeIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'（可能不完整）'**
  String get recipeIncomplete;

  /// No description provided for @recipeSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String recipeSeconds(int seconds);

  /// No description provided for @recipeAi.
  ///
  /// In zh, this message translates to:
  /// **' · AI 协助'**
  String get recipeAi;

  /// No description provided for @recipeEditAction.
  ///
  /// In zh, this message translates to:
  /// **'我来改一版'**
  String get recipeEditAction;

  /// No description provided for @recipeBaseOnVersion.
  ///
  /// In zh, this message translates to:
  /// **'基于这一版继续编辑'**
  String get recipeBaseOnVersion;

  /// No description provided for @recipePhotoTitle.
  ///
  /// In zh, this message translates to:
  /// **'成品图'**
  String get recipePhotoTitle;

  /// No description provided for @recipePhotoStageHint.
  ///
  /// In zh, this message translates to:
  /// **'先选图，保存菜谱时会把它放进第 1 版。'**
  String get recipePhotoStageHint;

  /// No description provided for @recipePhotoVersionHint.
  ///
  /// In zh, this message translates to:
  /// **'照片会生成新的菜谱版本，不会改动旧版本。'**
  String get recipePhotoVersionHint;

  /// No description provided for @recipePhotoSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择的成品图'**
  String get recipePhotoSelected;

  /// No description provided for @recipePhotoSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已上传，图片会以短期私有地址读取。'**
  String get recipePhotoSuccess;

  /// No description provided for @recipePhotoPicking.
  ///
  /// In zh, this message translates to:
  /// **'正在打开照片选择器…'**
  String get recipePhotoPicking;

  /// No description provided for @recipePhotoProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在压缩并清除照片元数据…'**
  String get recipePhotoProcessing;

  /// No description provided for @recipePhotoUploading.
  ///
  /// In zh, this message translates to:
  /// **'正在安全上传…'**
  String get recipePhotoUploading;

  /// No description provided for @recipePhotoUploadError.
  ///
  /// In zh, this message translates to:
  /// **'图片上传失败，请稍后重试。'**
  String get recipePhotoUploadError;

  /// No description provided for @recipePhotoReadError.
  ///
  /// In zh, this message translates to:
  /// **'图片无法读取，请换一张图片。'**
  String get recipePhotoReadError;

  /// No description provided for @recipePhotoTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片尺寸过大，无法安全处理。'**
  String get recipePhotoTooLarge;

  /// No description provided for @recipePhotoUnsafe.
  ///
  /// In zh, this message translates to:
  /// **'图片无法安全处理，请换一张图片。'**
  String get recipePhotoUnsafe;

  /// No description provided for @recipeCameraButton.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get recipeCameraButton;

  /// No description provided for @recipeGalleryButton.
  ///
  /// In zh, this message translates to:
  /// **'从相册选图'**
  String get recipeGalleryButton;

  /// No description provided for @recipeSourceAuthorFilled.
  ///
  /// In zh, this message translates to:
  /// **'作者填写'**
  String get recipeSourceAuthorFilled;

  /// No description provided for @recipeEmptyRecipeHeader.
  ///
  /// In zh, this message translates to:
  /// **'没有菜谱头部'**
  String get recipeEmptyRecipeHeader;

  /// No description provided for @recipeEmptyIngredients.
  ///
  /// In zh, this message translates to:
  /// **'没有食材'**
  String get recipeEmptyIngredients;

  /// No description provided for @recipeEmptySteps.
  ///
  /// In zh, this message translates to:
  /// **'没有步骤'**
  String get recipeEmptySteps;

  /// No description provided for @recipeEmptyCard.
  ///
  /// In zh, this message translates to:
  /// **'没有菜谱卡'**
  String get recipeEmptyCard;

  /// No description provided for @recipeListSummary.
  ///
  /// In zh, this message translates to:
  /// **'第 {version} 版 · {servings} 份 · {minutes} 分钟'**
  String recipeListSummary(int version, int servings, int minutes);

  /// No description provided for @recipeAliases.
  ///
  /// In zh, this message translates to:
  /// **'别名（用逗号分隔）'**
  String get recipeAliases;

  /// No description provided for @recipeServings.
  ///
  /// In zh, this message translates to:
  /// **'份数'**
  String get recipeServings;

  /// No description provided for @recipeServingsAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整份数'**
  String get recipeServingsAdjust;

  /// No description provided for @recipeServingsDecrease.
  ///
  /// In zh, this message translates to:
  /// **'减少一份'**
  String get recipeServingsDecrease;

  /// No description provided for @recipeServingsIncrease.
  ///
  /// In zh, this message translates to:
  /// **'增加一份'**
  String get recipeServingsIncrease;

  /// No description provided for @recipeServingsUnit.
  ///
  /// In zh, this message translates to:
  /// **'份'**
  String get recipeServingsUnit;

  /// No description provided for @recipeServingsRange.
  ///
  /// In zh, this message translates to:
  /// **'可调范围：{min}–{max} 份'**
  String recipeServingsRange(int min, int max);

  /// No description provided for @recipeServingsReset.
  ///
  /// In zh, this message translates to:
  /// **'恢复原份数'**
  String get recipeServingsReset;

  /// No description provided for @recipeBatchWarning.
  ///
  /// In zh, this message translates to:
  /// **'注意分批下锅，时间以成熟判断为准。'**
  String get recipeBatchWarning;

  /// No description provided for @recipeRuleProportional.
  ///
  /// In zh, this message translates to:
  /// **'按比例换算'**
  String get recipeRuleProportional;

  /// No description provided for @recipeRuleUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'保持原值不变'**
  String get recipeRuleUnchanged;

  /// No description provided for @recipeRuleRound.
  ///
  /// In zh, this message translates to:
  /// **'按个取整'**
  String get recipeRuleRound;

  /// No description provided for @recipeRuleMoldRatio.
  ///
  /// In zh, this message translates to:
  /// **'模具比例'**
  String get recipeRuleMoldRatio;

  /// No description provided for @recipeRuleUnknown.
  ///
  /// In zh, this message translates to:
  /// **'换算规则未识别'**
  String get recipeRuleUnknown;

  /// No description provided for @recipeConversionRuleDetail.
  ///
  /// In zh, this message translates to:
  /// **'原值 {original}，{rule}'**
  String recipeConversionRuleDetail(String original, String rule);

  /// No description provided for @recipeModeServing.
  ///
  /// In zh, this message translates to:
  /// **'按份数'**
  String get recipeModeServing;

  /// No description provided for @recipeModeMold.
  ///
  /// In zh, this message translates to:
  /// **'按模具'**
  String get recipeModeMold;

  /// No description provided for @recipeMoldConversion.
  ///
  /// In zh, this message translates to:
  /// **'模具换算'**
  String get recipeMoldConversion;

  /// No description provided for @recipeMoldReset.
  ///
  /// In zh, this message translates to:
  /// **'恢复原模具'**
  String get recipeMoldReset;

  /// No description provided for @recipeMoldOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原模具：{mold} · 底面积比例 {ratio}'**
  String recipeMoldOriginal(String mold, String ratio);

  /// No description provided for @recipeMoldTargetShape.
  ///
  /// In zh, this message translates to:
  /// **'目标模具形状'**
  String get recipeMoldTargetShape;

  /// No description provided for @recipeMoldRound.
  ///
  /// In zh, this message translates to:
  /// **'圆模'**
  String get recipeMoldRound;

  /// No description provided for @recipeMoldSquare.
  ///
  /// In zh, this message translates to:
  /// **'方模'**
  String get recipeMoldSquare;

  /// No description provided for @recipeMoldRectangular.
  ///
  /// In zh, this message translates to:
  /// **'长方模'**
  String get recipeMoldRectangular;

  /// No description provided for @recipeMoldCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义尺寸'**
  String get recipeMoldCustom;

  /// No description provided for @recipeMoldDiameter.
  ///
  /// In zh, this message translates to:
  /// **'直径'**
  String get recipeMoldDiameter;

  /// No description provided for @recipeMoldTargetDiameter.
  ///
  /// In zh, this message translates to:
  /// **'目标直径'**
  String get recipeMoldTargetDiameter;

  /// No description provided for @recipeMoldUnit.
  ///
  /// In zh, this message translates to:
  /// **'单位'**
  String get recipeMoldUnit;

  /// No description provided for @recipeMoldInch.
  ///
  /// In zh, this message translates to:
  /// **'英寸'**
  String get recipeMoldInch;

  /// No description provided for @recipeMoldCm.
  ///
  /// In zh, this message translates to:
  /// **'厘米'**
  String get recipeMoldCm;

  /// No description provided for @recipeMoldSide.
  ///
  /// In zh, this message translates to:
  /// **'边长（厘米）'**
  String get recipeMoldSide;

  /// No description provided for @recipeMoldWidth.
  ///
  /// In zh, this message translates to:
  /// **'宽（厘米）'**
  String get recipeMoldWidth;

  /// No description provided for @recipeMoldLength.
  ///
  /// In zh, this message translates to:
  /// **'长（厘米）'**
  String get recipeMoldLength;

  /// No description provided for @recipeMoldTargetSide.
  ///
  /// In zh, this message translates to:
  /// **'目标边长（厘米）'**
  String get recipeMoldTargetSide;

  /// No description provided for @recipeMoldTargetWidth.
  ///
  /// In zh, this message translates to:
  /// **'目标宽（厘米）'**
  String get recipeMoldTargetWidth;

  /// No description provided for @recipeMoldTargetLength.
  ///
  /// In zh, this message translates to:
  /// **'目标长（厘米）'**
  String get recipeMoldTargetLength;

  /// No description provided for @recipeMoldBakingNote.
  ///
  /// In zh, this message translates to:
  /// **'温度保持不变；时间不按比例放大，以成熟判断为准。'**
  String get recipeMoldBakingNote;

  /// No description provided for @recipeMoldTimeAdvisory.
  ///
  /// In zh, this message translates to:
  /// **'时间不按模具比例放大，建议从原时间开始检查，以成熟判断为准。'**
  String get recipeMoldTimeAdvisory;

  /// No description provided for @recipeMoldDonenessWarning.
  ///
  /// In zh, this message translates to:
  /// **'请以成熟判断为准，不要只看计时。'**
  String get recipeMoldDonenessWarning;

  /// No description provided for @recipeMoldInvalid.
  ///
  /// In zh, this message translates to:
  /// **'目标模具尺寸无效，请填写大于 0 的尺寸后再换算。'**
  String get recipeMoldInvalid;

  /// No description provided for @recipeMoldUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这份菜谱没有记录基准模具，暂时只能按份数显示。'**
  String get recipeMoldUnavailable;

  /// No description provided for @recipeServingRoundWarning.
  ///
  /// In zh, this message translates to:
  /// **'{name}取整后与按比例结果相差较大，请按口味微调其他用量。'**
  String recipeServingRoundWarning(String name);

  /// No description provided for @recipeMoldRoundWarning.
  ///
  /// In zh, this message translates to:
  /// **'{name}取整后与模具比例结果相差较大，请按实际情况微调其他用量。'**
  String recipeMoldRoundWarning(String name);

  /// No description provided for @recipeMeasureStandardDisplayOnly.
  ///
  /// In zh, this message translates to:
  /// **'常用量具换算；菜谱基础值未改变'**
  String get recipeMeasureStandardDisplayOnly;

  /// No description provided for @recipeReplacementValue.
  ///
  /// In zh, this message translates to:
  /// **'{label}'**
  String recipeReplacementValue(String label);

  /// No description provided for @sourceAuthorFilled.
  ///
  /// In zh, this message translates to:
  /// **'作者填写'**
  String get sourceAuthorFilled;

  /// No description provided for @sourceTasteAdjusted.
  ///
  /// In zh, this message translates to:
  /// **'按你的口味换算'**
  String get sourceTasteAdjusted;

  /// No description provided for @sourceScenarioAdjusted.
  ///
  /// In zh, this message translates to:
  /// **'按场景调整'**
  String get sourceScenarioAdjusted;

  /// No description provided for @sourceAiEstimated.
  ///
  /// In zh, this message translates to:
  /// **'AI 估算'**
  String get sourceAiEstimated;

  /// No description provided for @sourceVerified.
  ///
  /// In zh, this message translates to:
  /// **'已验证'**
  String get sourceVerified;

  /// No description provided for @sourceUnknown.
  ///
  /// In zh, this message translates to:
  /// **'来源未标注'**
  String get sourceUnknown;

  /// No description provided for @sourceBasisUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无可显示的依据'**
  String get sourceBasisUnavailable;

  /// No description provided for @whyOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原来：{value}'**
  String whyOriginal(String value);

  /// No description provided for @whyCurrent.
  ///
  /// In zh, this message translates to:
  /// **'现在：{value}'**
  String whyCurrent(String value);

  /// No description provided for @whyRequired.
  ///
  /// In zh, this message translates to:
  /// **'这是必显内容，不能关掉'**
  String get whyRequired;

  /// No description provided for @whySkipThisTime.
  ///
  /// In zh, this message translates to:
  /// **'这次不用'**
  String get whySkipThisTime;

  /// No description provided for @whyDontDoAgain.
  ///
  /// In zh, this message translates to:
  /// **'以后别这样'**
  String get whyDontDoAgain;

  /// No description provided for @sourceSemantics.
  ///
  /// In zh, this message translates to:
  /// **'来源：{source}，点开查看为什么'**
  String sourceSemantics(String source);

  /// No description provided for @recipeDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'难度'**
  String get recipeDifficulty;

  /// No description provided for @recipeDishType.
  ///
  /// In zh, this message translates to:
  /// **'菜型'**
  String get recipeDishType;

  /// No description provided for @recipeTags.
  ///
  /// In zh, this message translates to:
  /// **'标签（用逗号分隔）'**
  String get recipeTags;

  /// No description provided for @recipeTotalTime.
  ///
  /// In zh, this message translates to:
  /// **'总时长（秒）'**
  String get recipeTotalTime;

  /// No description provided for @recipeActiveTime.
  ///
  /// In zh, this message translates to:
  /// **'动手时长（秒）'**
  String get recipeActiveTime;

  /// No description provided for @recipeIngredientAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加食材'**
  String get recipeIngredientAdd;

  /// No description provided for @recipeIngredientDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除食材'**
  String get recipeIngredientDelete;

  /// No description provided for @recipeIngredientMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'食材上移'**
  String get recipeIngredientMoveUp;

  /// No description provided for @recipeIngredientMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'食材下移'**
  String get recipeIngredientMoveDown;

  /// No description provided for @recipeSearchStandard.
  ///
  /// In zh, this message translates to:
  /// **'搜索标准食材'**
  String get recipeSearchStandard;

  /// No description provided for @recipeStandardIngredient.
  ///
  /// In zh, this message translates to:
  /// **'标准食材'**
  String get recipeStandardIngredient;

  /// No description provided for @recipeUnknownIngredient.
  ///
  /// In zh, this message translates to:
  /// **'未收录'**
  String get recipeUnknownIngredient;

  /// No description provided for @recipeBaseQuantity.
  ///
  /// In zh, this message translates to:
  /// **'基础用量'**
  String get recipeBaseQuantity;

  /// No description provided for @recipeBaseUnit.
  ///
  /// In zh, this message translates to:
  /// **'基础单位（克、毫升、个）'**
  String get recipeBaseUnit;

  /// No description provided for @recipeIngredientGroup.
  ///
  /// In zh, this message translates to:
  /// **'分组'**
  String get recipeIngredientGroup;

  /// No description provided for @recipeScalingMode.
  ///
  /// In zh, this message translates to:
  /// **'缩放方式'**
  String get recipeScalingMode;

  /// No description provided for @recipeScalingProportional.
  ///
  /// In zh, this message translates to:
  /// **'按比例'**
  String get recipeScalingProportional;

  /// No description provided for @recipeScalingUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'保持不变'**
  String get recipeScalingUnchanged;

  /// No description provided for @recipeScalingRound.
  ///
  /// In zh, this message translates to:
  /// **'按个取整'**
  String get recipeScalingRound;

  /// No description provided for @recipeScalingLibraryDefault.
  ///
  /// In zh, this message translates to:
  /// **'跟随食材库默认（{mode}）'**
  String recipeScalingLibraryDefault(String mode);

  /// No description provided for @recipeScalingLibraryDefaultUnknown.
  ///
  /// In zh, this message translates to:
  /// **'跟随食材库默认（没有默认值时按比例）'**
  String get recipeScalingLibraryDefaultUnknown;

  /// No description provided for @recipeOptionalToggle.
  ///
  /// In zh, this message translates to:
  /// **'可选食材'**
  String get recipeOptionalToggle;

  /// No description provided for @recipeFunctionalToggle.
  ///
  /// In zh, this message translates to:
  /// **'功能性用料'**
  String get recipeFunctionalToggle;

  /// No description provided for @recipeReplacement.
  ///
  /// In zh, this message translates to:
  /// **'替代品'**
  String get recipeReplacement;

  /// No description provided for @recipeReplacementSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索替代标准食材'**
  String get recipeReplacementSearch;

  /// No description provided for @recipeReplacementName.
  ///
  /// In zh, this message translates to:
  /// **'替代品名称'**
  String get recipeReplacementName;

  /// No description provided for @recipeReplacementRatio.
  ///
  /// In zh, this message translates to:
  /// **'替代比例'**
  String get recipeReplacementRatio;

  /// No description provided for @recipeReplacementNote.
  ///
  /// In zh, this message translates to:
  /// **'替代说明'**
  String get recipeReplacementNote;

  /// No description provided for @recipeStepAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加步骤'**
  String get recipeStepAdd;

  /// No description provided for @recipeStepDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除步骤'**
  String get recipeStepDelete;

  /// No description provided for @recipeStepMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'步骤上移'**
  String get recipeStepMoveUp;

  /// No description provided for @recipeStepMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'步骤下移'**
  String get recipeStepMoveDown;

  /// No description provided for @recipeStepAction.
  ///
  /// In zh, this message translates to:
  /// **'动作类型'**
  String get recipeStepAction;

  /// No description provided for @recipeStepIngredientRefs.
  ///
  /// In zh, this message translates to:
  /// **'引用食材'**
  String get recipeStepIngredientRefs;

  /// No description provided for @recipeStepDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长（秒）'**
  String get recipeStepDuration;

  /// No description provided for @recipeStepUnattended.
  ///
  /// In zh, this message translates to:
  /// **'可以走开'**
  String get recipeStepUnattended;

  /// No description provided for @recipeStepHeat.
  ///
  /// In zh, this message translates to:
  /// **'火候'**
  String get recipeStepHeat;

  /// No description provided for @recipeStepTemperature.
  ///
  /// In zh, this message translates to:
  /// **'温度（摄氏度）'**
  String get recipeStepTemperature;

  /// No description provided for @recipeStepCookware.
  ///
  /// In zh, this message translates to:
  /// **'厨具'**
  String get recipeStepCookware;

  /// No description provided for @recipeStepDoneness.
  ///
  /// In zh, this message translates to:
  /// **'成熟判断'**
  String get recipeStepDoneness;

  /// No description provided for @recipeStepDepends.
  ///
  /// In zh, this message translates to:
  /// **'依赖的前置步骤'**
  String get recipeStepDepends;

  /// No description provided for @recipeStepNotes.
  ///
  /// In zh, this message translates to:
  /// **'要点'**
  String get recipeStepNotes;

  /// No description provided for @recipeStepWhy.
  ///
  /// In zh, this message translates to:
  /// **'原理'**
  String get recipeStepWhy;

  /// No description provided for @recipeNoIngredients.
  ///
  /// In zh, this message translates to:
  /// **'还没有食材'**
  String get recipeNoIngredients;

  /// No description provided for @recipeNoSteps.
  ///
  /// In zh, this message translates to:
  /// **'还没有步骤'**
  String get recipeNoSteps;

  /// No description provided for @recipeNutritionValues.
  ///
  /// In zh, this message translates to:
  /// **'每份营养估算：能量 {energy} 千卡，蛋白质 {protein} 克，脂肪 {fat} 克，碳水 {carb} 克，钠 {sodium} 毫克{incomplete}'**
  String recipeNutritionValues(
    String energy,
    String protein,
    String fat,
    String carb,
    String sodium,
    String incomplete,
  );

  /// No description provided for @recipeNoNutrition.
  ///
  /// In zh, this message translates to:
  /// **'暂无营养估算'**
  String get recipeNoNutrition;

  /// No description provided for @recipeCookware.
  ///
  /// In zh, this message translates to:
  /// **'厨具：{items}'**
  String recipeCookware(Object items);

  /// No description provided for @recipeImagePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'成品图将在这里显示'**
  String get recipeImagePlaceholder;

  /// No description provided for @recipeNoTags.
  ///
  /// In zh, this message translates to:
  /// **'未设置标签'**
  String get recipeNoTags;

  /// No description provided for @recipeDifficultyValue.
  ///
  /// In zh, this message translates to:
  /// **'难度：{value}'**
  String recipeDifficultyValue(String value);

  /// No description provided for @recipeDishTypeValue.
  ///
  /// In zh, this message translates to:
  /// **'菜型：{value}'**
  String recipeDishTypeValue(String value);

  /// No description provided for @recipeVersionDate.
  ///
  /// In zh, this message translates to:
  /// **'保存于 {date}'**
  String recipeVersionDate(String date);

  /// No description provided for @recipeOperationCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条修改'**
  String recipeOperationCount(int count);

  /// No description provided for @recipeInvalidStepReference.
  ///
  /// In zh, this message translates to:
  /// **'步骤引用了不存在的食材或前置步骤'**
  String get recipeInvalidStepReference;

  /// No description provided for @recipeIngredientRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写食材名称'**
  String get recipeIngredientRequired;

  /// No description provided for @recipeInvalidNumber.
  ///
  /// In zh, this message translates to:
  /// **'请填写有效的非负数字'**
  String get recipeInvalidNumber;

  /// No description provided for @recipeDiscardConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'放弃未保存修改？'**
  String get recipeDiscardConfirmTitle;

  /// No description provided for @recipeDiscardConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'这会删除本机草稿，已保存的版本不会受影响。'**
  String get recipeDiscardConfirmBody;

  /// No description provided for @recipeKeepEditing.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get recipeKeepEditing;

  /// No description provided for @recipeDiscardConfirm.
  ///
  /// In zh, this message translates to:
  /// **'放弃修改'**
  String get recipeDiscardConfirm;

  /// No description provided for @recipeDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这份菜谱？'**
  String get recipeDeleteConfirmTitle;

  /// No description provided for @recipeDeleteConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'删除后不能恢复。'**
  String get recipeDeleteConfirmBody;

  /// No description provided for @recipeDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get recipeDeleteConfirm;

  /// No description provided for @recipeCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get recipeCancel;

  /// No description provided for @recipeSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已保存为新版本'**
  String get recipeSaveSuccess;

  /// No description provided for @recipeSearchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到标准食材，可以继续填写未收录食材'**
  String get recipeSearchNoResults;

  /// No description provided for @recipeAiAssisted.
  ///
  /// In zh, this message translates to:
  /// **'AI 协助'**
  String get recipeAiAssisted;

  /// No description provided for @tasteCategory.
  ///
  /// In zh, this message translates to:
  /// **'或选择食材分类'**
  String get tasteCategory;

  /// No description provided for @tastePreference.
  ///
  /// In zh, this message translates to:
  /// **'偏好'**
  String get tastePreference;

  /// No description provided for @tastePreferenceDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除偏好'**
  String get tastePreferenceDelete;

  /// No description provided for @tastePreferenceDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'只删除这项明确选择，不改动其他口味和过敏设置；修改历史保留。'**
  String get tastePreferenceDeleteBody;

  /// No description provided for @tasteIngredients.
  ///
  /// In zh, this message translates to:
  /// **'食材偏好'**
  String get tasteIngredients;

  /// No description provided for @tasteIngredientsIntro.
  ///
  /// In zh, this message translates to:
  /// **'喜欢、不喜欢和忌口由你明确选择，不等于过敏。'**
  String get tasteIngredientsIntro;

  /// No description provided for @tasteIngredientsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有食材偏好'**
  String get tasteIngredientsEmpty;

  /// No description provided for @tastePreferenceAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加食材偏好'**
  String get tastePreferenceAdd;

  /// No description provided for @tasteIngredientSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索标准食材'**
  String get tasteIngredientSearch;

  /// No description provided for @tasteSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get tasteSearch;

  /// No description provided for @tasteSearchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有找到标准食材，请换一个名称搜索；不能保存自由文字。'**
  String get tasteSearchEmpty;

  /// No description provided for @tasteLiked.
  ///
  /// In zh, this message translates to:
  /// **'喜欢'**
  String get tasteLiked;

  /// No description provided for @tasteDisliked.
  ///
  /// In zh, this message translates to:
  /// **'不喜欢'**
  String get tasteDisliked;

  /// No description provided for @tasteAvoided.
  ///
  /// In zh, this message translates to:
  /// **'忌口'**
  String get tasteAvoided;

  /// No description provided for @tasteUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get tasteUnset;

  /// No description provided for @tasteTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的口味'**
  String get tasteTitle;

  /// No description provided for @tasteIntro.
  ///
  /// In zh, this message translates to:
  /// **'只代表你明确设置的七项口味，不会从行为猜测你的偏好。'**
  String get tasteIntro;

  /// No description provided for @tasteReset.
  ///
  /// In zh, this message translates to:
  /// **'恢复标准默认'**
  String get tasteReset;

  /// No description provided for @tasteResetBody.
  ///
  /// In zh, this message translates to:
  /// **'七项口味恢复为标准，重新标记为把握低；修改记录保留。'**
  String get tasteResetBody;

  /// No description provided for @tasteManual.
  ///
  /// In zh, this message translates to:
  /// **'你手动填写'**
  String get tasteManual;

  /// No description provided for @tasteDefault.
  ///
  /// In zh, this message translates to:
  /// **'标准默认'**
  String get tasteDefault;

  /// No description provided for @tasteWhy.
  ///
  /// In zh, this message translates to:
  /// **'为什么'**
  String get tasteWhy;

  /// No description provided for @tasteHistory.
  ///
  /// In zh, this message translates to:
  /// **'修改历史'**
  String get tasteHistory;

  /// No description provided for @tasteHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有修改记录'**
  String get tasteHistoryEmpty;

  /// No description provided for @tasteHistoryReadonly.
  ///
  /// In zh, this message translates to:
  /// **'只读查看原因和历史，暂不提供撤销或锁定。'**
  String get tasteHistoryReadonly;

  /// No description provided for @tasteLocal.
  ///
  /// In zh, this message translates to:
  /// **'菜系局部偏好'**
  String get tasteLocal;

  /// No description provided for @tasteLocalEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有菜系局部偏好'**
  String get tasteLocalEmpty;

  /// No description provided for @tasteLocalReadonly.
  ///
  /// In zh, this message translates to:
  /// **'菜系对应的味型调整只读显示，暂不提供学习或编辑。'**
  String get tasteLocalReadonly;

  /// No description provided for @tasteActive.
  ///
  /// In zh, this message translates to:
  /// **'生效'**
  String get tasteActive;

  /// No description provided for @tasteReverted.
  ///
  /// In zh, this message translates to:
  /// **'已撤销'**
  String get tasteReverted;

  /// No description provided for @tasteSalty.
  ///
  /// In zh, this message translates to:
  /// **'咸'**
  String get tasteSalty;

  /// No description provided for @tasteSweet.
  ///
  /// In zh, this message translates to:
  /// **'甜'**
  String get tasteSweet;

  /// No description provided for @tasteSour.
  ///
  /// In zh, this message translates to:
  /// **'酸'**
  String get tasteSour;

  /// No description provided for @tasteSpicy.
  ///
  /// In zh, this message translates to:
  /// **'辣'**
  String get tasteSpicy;

  /// No description provided for @tasteNumbing.
  ///
  /// In zh, this message translates to:
  /// **'麻'**
  String get tasteNumbing;

  /// No description provided for @tasteUmami.
  ///
  /// In zh, this message translates to:
  /// **'鲜'**
  String get tasteUmami;

  /// No description provided for @tasteOily.
  ///
  /// In zh, this message translates to:
  /// **'油'**
  String get tasteOily;

  /// No description provided for @personalMeasuresTitle.
  ///
  /// In zh, this message translates to:
  /// **'自家量具'**
  String get personalMeasuresTitle;

  /// No description provided for @personalMeasuresIntro.
  ///
  /// In zh, this message translates to:
  /// **'把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。只影响显示，不会修改菜谱。'**
  String get personalMeasuresIntro;

  /// No description provided for @personalMeasuresOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线：正在使用已缓存的量具；登记、修改和删除需要联网。'**
  String get personalMeasuresOffline;

  /// No description provided for @personalMeasuresAdd.
  ///
  /// In zh, this message translates to:
  /// **'登记量具'**
  String get personalMeasuresAdd;

  /// No description provided for @personalMeasuresEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有登记量具'**
  String get personalMeasuresEmpty;

  /// No description provided for @personalMeasuresDeleteTooltip.
  ///
  /// In zh, this message translates to:
  /// **'删除量具'**
  String get personalMeasuresDeleteTooltip;

  /// No description provided for @personalMeasuresDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除量具？'**
  String get personalMeasuresDeleteTitle;

  /// No description provided for @personalMeasuresDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'删除“{name}”不会改动菜谱。'**
  String personalMeasuresDeleteBody(Object name);

  /// No description provided for @personalMeasuresEdit.
  ///
  /// In zh, this message translates to:
  /// **'修改量具'**
  String get personalMeasuresEdit;

  /// No description provided for @personalMeasuresRegister.
  ///
  /// In zh, this message translates to:
  /// **'登记量具'**
  String get personalMeasuresRegister;

  /// No description provided for @personalMeasuresName.
  ///
  /// In zh, this message translates to:
  /// **'量具名称'**
  String get personalMeasuresName;

  /// No description provided for @personalMeasuresKind.
  ///
  /// In zh, this message translates to:
  /// **'种类'**
  String get personalMeasuresKind;

  /// No description provided for @personalMeasuresCapacity.
  ///
  /// In zh, this message translates to:
  /// **'满水容量（毫升）'**
  String get personalMeasuresCapacity;

  /// No description provided for @personalMeasuresCapacityValue.
  ///
  /// In zh, this message translates to:
  /// **'{value} 毫升'**
  String personalMeasuresCapacityValue(Object value);

  /// No description provided for @personalMeasuresValidation.
  ///
  /// In zh, this message translates to:
  /// **'名称需为 1–64 个字，容量需大于 0 且不超过 10000 毫升'**
  String get personalMeasuresValidation;

  /// No description provided for @personalMeasuresSpoon.
  ///
  /// In zh, this message translates to:
  /// **'勺'**
  String get personalMeasuresSpoon;

  /// No description provided for @personalMeasuresBowl.
  ///
  /// In zh, this message translates to:
  /// **'碗'**
  String get personalMeasuresBowl;

  /// No description provided for @personalMeasuresCup.
  ///
  /// In zh, this message translates to:
  /// **'杯'**
  String get personalMeasuresCup;

  /// No description provided for @recipeMeasureModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'用量显示方式'**
  String get recipeMeasureModeTitle;

  /// No description provided for @recipeMeasureModeBase.
  ///
  /// In zh, this message translates to:
  /// **'克/毫升'**
  String get recipeMeasureModeBase;

  /// No description provided for @recipeMeasureModeStandard.
  ///
  /// In zh, this message translates to:
  /// **'汤匙/茶匙'**
  String get recipeMeasureModeStandard;

  /// No description provided for @recipeMeasureModeHome.
  ///
  /// In zh, this message translates to:
  /// **'自家量具'**
  String get recipeMeasureModeHome;

  /// No description provided for @recipeMeasureChoose.
  ///
  /// In zh, this message translates to:
  /// **'选择量具'**
  String get recipeMeasureChoose;

  /// No description provided for @recipeMeasureRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新我的量具'**
  String get recipeMeasureRefresh;

  /// No description provided for @recipeMeasureManage.
  ///
  /// In zh, this message translates to:
  /// **'登记自家量具'**
  String get recipeMeasureManage;

  /// No description provided for @recipeMeasureModeNoHome.
  ///
  /// In zh, this message translates to:
  /// **'还没有登记自家量具，请先到“我的”登记。'**
  String get recipeMeasureModeNoHome;

  /// No description provided for @recipeMeasureDisplayOnly.
  ///
  /// In zh, this message translates to:
  /// **'个人量具只改变显示，菜谱基础值未改变'**
  String get recipeMeasureDisplayOnly;

  /// No description provided for @recipeMeasureDisplaySource.
  ///
  /// In zh, this message translates to:
  /// **'量具表达'**
  String get recipeMeasureDisplaySource;

  /// No description provided for @recipeMeasureNoDensity.
  ///
  /// In zh, this message translates to:
  /// **'没有密度数据，保留{unit}'**
  String recipeMeasureNoDensity(String unit);

  /// No description provided for @recipeMeasureGram.
  ///
  /// In zh, this message translates to:
  /// **'克'**
  String get recipeMeasureGram;

  /// No description provided for @recipeMeasureMillilitre.
  ///
  /// In zh, this message translates to:
  /// **'毫升'**
  String get recipeMeasureMillilitre;

  /// No description provided for @recipeMeasureTablespoon.
  ///
  /// In zh, this message translates to:
  /// **'汤匙'**
  String get recipeMeasureTablespoon;

  /// No description provided for @recipeMeasureTeaspoon.
  ///
  /// In zh, this message translates to:
  /// **'茶匙'**
  String get recipeMeasureTeaspoon;

  /// No description provided for @recipeMeasureApproximate.
  ///
  /// In zh, this message translates to:
  /// **'约'**
  String get recipeMeasureApproximate;

  /// No description provided for @cookingConstraintsTitle.
  ///
  /// In zh, this message translates to:
  /// **'做菜约束'**
  String get cookingConstraintsTitle;

  /// No description provided for @cookingConstraintsUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get cookingConstraintsUnset;

  /// No description provided for @cookingConstraintsLoadError.
  ///
  /// In zh, this message translates to:
  /// **'做菜约束暂时无法读取'**
  String get cookingConstraintsLoadError;

  /// No description provided for @cookingConstraintsIntro.
  ///
  /// In zh, this message translates to:
  /// **'做菜约束 · 仅作为家庭默认，不修改作者菜谱'**
  String get cookingConstraintsIntro;

  /// No description provided for @cookingConstraintsSourceValue.
  ///
  /// In zh, this message translates to:
  /// **'家庭做菜约束'**
  String get cookingConstraintsSourceValue;

  /// No description provided for @cookingConstraintsBasis.
  ///
  /// In zh, this message translates to:
  /// **'来自你手动填写；未设置的项目为空。人数只用于新一次查看的默认份数，本次手动选择优先，作者配方和原始版本不变。厨具、时间与餐型仅保存，不在这里推荐或改写菜谱。'**
  String get cookingConstraintsBasis;

  /// No description provided for @cookingConstraintsManual.
  ///
  /// In zh, this message translates to:
  /// **'你手动设置'**
  String get cookingConstraintsManual;

  /// No description provided for @cookingConstraintsEdit.
  ///
  /// In zh, this message translates to:
  /// **'设置做菜约束'**
  String get cookingConstraintsEdit;

  /// No description provided for @cookingConstraintsClear.
  ///
  /// In zh, this message translates to:
  /// **'清除做菜约束'**
  String get cookingConstraintsClear;

  /// No description provided for @cookingConstraintsClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除做菜约束？'**
  String get cookingConstraintsClearTitle;

  /// No description provided for @cookingConstraintsClearBody.
  ///
  /// In zh, this message translates to:
  /// **'人数、厨具、时间和餐型恢复为空。菜谱原始版本不会改变。'**
  String get cookingConstraintsClearBody;

  /// No description provided for @cookingConstraintsClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get cookingConstraintsClearConfirm;

  /// No description provided for @cookingHouseholdEmpty.
  ///
  /// In zh, this message translates to:
  /// **'人数未设置，菜谱沿用作者份数'**
  String get cookingHouseholdEmpty;

  /// No description provided for @cookingHouseholdDefault.
  ///
  /// In zh, this message translates to:
  /// **'家庭默认：{count} 人'**
  String cookingHouseholdDefault(String count);

  /// No description provided for @cookingHouseholdHistory.
  ///
  /// In zh, this message translates to:
  /// **'{count} 人'**
  String cookingHouseholdHistory(String count);

  /// No description provided for @cookingHouseholdInput.
  ///
  /// In zh, this message translates to:
  /// **'家庭人数（留空沿用作者份数）'**
  String get cookingHouseholdInput;

  /// No description provided for @cookingEquipmentInput.
  ///
  /// In zh, this message translates to:
  /// **'家里有哪些厨具'**
  String get cookingEquipmentInput;

  /// No description provided for @cookingEquipmentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'厨具未设置'**
  String get cookingEquipmentEmpty;

  /// No description provided for @cookingEquipmentSummary.
  ///
  /// In zh, this message translates to:
  /// **'厨具：{names}'**
  String cookingEquipmentSummary(String names);

  /// No description provided for @cookingMealTimesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'各餐可用时间未设置'**
  String get cookingMealTimesEmpty;

  /// No description provided for @cookingMealTemplatesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'餐型未设置'**
  String get cookingMealTemplatesEmpty;

  /// No description provided for @cookingMealInput.
  ///
  /// In zh, this message translates to:
  /// **'每餐时间与餐型（留空清除）'**
  String get cookingMealInput;

  /// No description provided for @cookingMealTemplateHint.
  ///
  /// In zh, this message translates to:
  /// **'菜型用逗号分隔：{types}。每项代表一道，可重复。'**
  String cookingMealTemplateHint(String types);

  /// No description provided for @cookingMealMinutesInput.
  ///
  /// In zh, this message translates to:
  /// **'可用分钟'**
  String get cookingMealMinutesInput;

  /// No description provided for @cookingMealTemplateInput.
  ///
  /// In zh, this message translates to:
  /// **'菜型组合，例如 {example}'**
  String cookingMealTemplateInput(String example);

  /// No description provided for @cookingIntegerValidation.
  ///
  /// In zh, this message translates to:
  /// **'请输入 {minimum}～{maximum} 的整数；留空清除'**
  String cookingIntegerValidation(int minimum, int maximum);

  /// No description provided for @cookingTemplateValidation.
  ///
  /// In zh, this message translates to:
  /// **'请用上述菜型组合，最多 {maximum} 道'**
  String cookingTemplateValidation(int maximum);

  /// No description provided for @cookingWeekday.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get cookingWeekday;

  /// No description provided for @cookingWeekend.
  ///
  /// In zh, this message translates to:
  /// **'周末'**
  String get cookingWeekend;

  /// No description provided for @cookingBreakfast.
  ///
  /// In zh, this message translates to:
  /// **'早餐'**
  String get cookingBreakfast;

  /// No description provided for @cookingLunch.
  ///
  /// In zh, this message translates to:
  /// **'午餐'**
  String get cookingLunch;

  /// No description provided for @cookingDinner.
  ///
  /// In zh, this message translates to:
  /// **'晚餐'**
  String get cookingDinner;

  /// No description provided for @cookingDishMeat.
  ///
  /// In zh, this message translates to:
  /// **'荤菜'**
  String get cookingDishMeat;

  /// No description provided for @cookingDishVegetable.
  ///
  /// In zh, this message translates to:
  /// **'素菜'**
  String get cookingDishVegetable;

  /// No description provided for @cookingDishSoup.
  ///
  /// In zh, this message translates to:
  /// **'汤'**
  String get cookingDishSoup;

  /// No description provided for @cookingDishStaple.
  ///
  /// In zh, this message translates to:
  /// **'主食'**
  String get cookingDishStaple;

  /// No description provided for @cookingDishOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get cookingDishOther;

  /// No description provided for @cookingListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get cookingListSeparator;

  /// No description provided for @cookingMealSlot.
  ///
  /// In zh, this message translates to:
  /// **'{day}{meal}'**
  String cookingMealSlot(String day, String meal);

  /// No description provided for @cookingMealTimeSummary.
  ///
  /// In zh, this message translates to:
  /// **'{slot}：{minutes} 分钟'**
  String cookingMealTimeSummary(String slot, String minutes);

  /// No description provided for @cookingMealTemplateSummary.
  ///
  /// In zh, this message translates to:
  /// **'{slot}：{count} 道（{composition}）'**
  String cookingMealTemplateSummary(
    String slot,
    String count,
    String composition,
  );

  /// No description provided for @personalMeasuresSummaryIntro.
  ///
  /// In zh, this message translates to:
  /// **'你登记的量具，仅用于显示，不改变配方。'**
  String get personalMeasuresSummaryIntro;

  /// No description provided for @personalMeasuresManage.
  ///
  /// In zh, this message translates to:
  /// **'管理个人量具'**
  String get personalMeasuresManage;

  /// No description provided for @personalMeasuresSummaryValue.
  ///
  /// In zh, this message translates to:
  /// **'{name} · {capacity} 毫升'**
  String personalMeasuresSummaryValue(String name, String capacity);

  /// No description provided for @allergyTitle.
  ///
  /// In zh, this message translates to:
  /// **'本人过敏'**
  String get allergyTitle;

  /// No description provided for @allergyIntro.
  ///
  /// In zh, this message translates to:
  /// **'仅本人手动填写 · 单独同意 · 加密保存。拒绝不影响普通口味。'**
  String get allergyIntro;

  /// No description provided for @allergyNotFilled.
  ///
  /// In zh, this message translates to:
  /// **'未填写'**
  String get allergyNotFilled;

  /// No description provided for @allergyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'尚未填写本人过敏'**
  String get allergyEmpty;

  /// No description provided for @allergyEdit.
  ///
  /// In zh, this message translates to:
  /// **'设置本人过敏'**
  String get allergyEdit;

  /// No description provided for @allergyConsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'过敏信息单独同意'**
  String get allergyConsentTitle;

  /// No description provided for @allergyConsentBody.
  ///
  /// In zh, this message translates to:
  /// **'只收集你手动选择的八类过敏原和标准食材，用于保存本人过敏设置及修改历史。当前值和历史加密保存，仅本人可见，不从行为或模型推断。可在设置的隐私入口撤回，删除当前值、私密历史及关联副本；重新同意从空状态开始。拒绝不影响普通口味，不代表同意外部 AI 共享。'**
  String get allergyConsentBody;

  /// No description provided for @allergyRefuse.
  ///
  /// In zh, this message translates to:
  /// **'暂不同意'**
  String get allergyRefuse;

  /// No description provided for @allergyAgree.
  ///
  /// In zh, this message translates to:
  /// **'单独同意'**
  String get allergyAgree;

  /// No description provided for @allergyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'过敏设置暂不可用，授权或保存未确认，请重试'**
  String get allergyUnavailable;

  /// No description provided for @allergyPrivateUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'私密信息暂不可用；仍可在设置撤回同意'**
  String get allergyPrivateUnavailable;

  /// No description provided for @allergyHidden.
  ///
  /// In zh, this message translates to:
  /// **'本机私密信息已隐藏，撤回尚未确认时请在设置重试'**
  String get allergyHidden;

  /// No description provided for @allergyHistory.
  ///
  /// In zh, this message translates to:
  /// **'私密修改历史'**
  String get allergyHistory;

  /// No description provided for @allergyHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有私密修改历史'**
  String get allergyHistoryEmpty;

  /// No description provided for @allergyHistoryUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'私密历史暂不可用'**
  String get allergyHistoryUnavailable;

  /// No description provided for @allergyWhy.
  ///
  /// In zh, this message translates to:
  /// **'为什么'**
  String get allergyWhy;

  /// No description provided for @allergyManual.
  ///
  /// In zh, this message translates to:
  /// **'本人手动填写'**
  String get allergyManual;

  /// No description provided for @allergyEditorTitle.
  ///
  /// In zh, this message translates to:
  /// **'手动设置本人过敏'**
  String get allergyEditorTitle;

  /// No description provided for @allergyDeleteIngredient.
  ///
  /// In zh, this message translates to:
  /// **'删除食材'**
  String get allergyDeleteIngredient;

  /// No description provided for @allergySearchLabel.
  ///
  /// In zh, this message translates to:
  /// **'搜索标准食材（不保存自由文字）'**
  String get allergySearchLabel;

  /// No description provided for @allergySearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索食材'**
  String get allergySearch;

  /// No description provided for @allergySearchUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'食材搜索暂不可用，请重试'**
  String get allergySearchUnavailable;

  /// No description provided for @allergySave.
  ///
  /// In zh, this message translates to:
  /// **'保存过敏设置'**
  String get allergySave;

  /// No description provided for @allergySaveUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'保存未确认，请重新打开过敏设置后重试'**
  String get allergySaveUnconfirmed;

  /// No description provided for @allergyWithdrawEntry.
  ///
  /// In zh, this message translates to:
  /// **'撤回敏感信息同意'**
  String get allergyWithdrawEntry;

  /// No description provided for @allergyWithdrawDetail.
  ///
  /// In zh, this message translates to:
  /// **'仅删除本人过敏和私密历史，不退出普通口味'**
  String get allergyWithdrawDetail;

  /// No description provided for @allergyWithdrawTitle.
  ///
  /// In zh, this message translates to:
  /// **'撤回敏感信息同意？'**
  String get allergyWithdrawTitle;

  /// No description provided for @allergyWithdrawBody.
  ///
  /// In zh, this message translates to:
  /// **'删除本人过敏、私密修改历史及关联副本。普通口味、食材偏好和做菜约束保留；重新同意后从空状态开始。'**
  String get allergyWithdrawBody;

  /// No description provided for @allergyWithdrawConfirm.
  ///
  /// In zh, this message translates to:
  /// **'撤回并删除'**
  String get allergyWithdrawConfirm;

  /// No description provided for @allergyWithdrawing.
  ///
  /// In zh, this message translates to:
  /// **'撤回处理中，本机私密信息已隐藏'**
  String get allergyWithdrawing;

  /// No description provided for @allergyWithdrawn.
  ///
  /// In zh, this message translates to:
  /// **'敏感同意已撤回，过敏及私密历史已删除'**
  String get allergyWithdrawn;

  /// No description provided for @allergyWithdrawUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'撤回尚未确认，请联网后重试；普通口味不受影响'**
  String get allergyWithdrawUnconfirmed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
