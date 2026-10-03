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

  /// No description provided for @recipeMeasureNoDensity.
  ///
  /// In zh, this message translates to:
  /// **'没有密度数据，保留克数'**
  String get recipeMeasureNoDensity;

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
