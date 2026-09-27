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
  String get meEmptyBody => '账号、口味偏好和设置会放在这里。';
}
