import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/session.dart';
import '../../auth/auth_controller.dart';
import '../../config/app_config.dart';
import '../../platform/export_file_share.dart';
import '../../platform/link_opener.dart';
import '../../widgets/page_frame.dart';
import 'export_data.dart';
import 'identity_verification.dart';

class ExportDataPage extends ConsumerStatefulWidget {
  const ExportDataPage({super.key});

  @override
  ConsumerState<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends ConsumerState<ExportDataPage> {
  SessionIdentity? _verifiedIdentity;
  SessionIdentity? _operationIdentity;
  bool get _verified =>
      _verifiedIdentity != null &&
      ref.read(sessionStoreProvider).matches(_verifiedIdentity!);
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    _operationIdentity = identity;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted && session.matches(identity)) {
        final failure = ApiFailure.from(error);
        setState(() {
          _error = failure.message;
          if (failure.code == 'reauth_required') _verifiedIdentity = null;
        });
      }
    } finally {
      if (mounted && session.matches(identity)) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, _) {
      final identity = _operationIdentity ?? _verifiedIdentity;
      if (identity != null &&
          !ref.read(sessionStoreProvider).matches(identity)) {
        setState(() {
          _verifiedIdentity = null;
          _operationIdentity = null;
          _busy = false;
          _error = null;
        });
      }
    });
    ref.watch(authProvider);
    final session = ref.read(sessionStoreProvider);
    final jobs = ref.watch(exportJobsProvider);
    final notifier = ref.read(exportJobsProvider.notifier);
    return PageFrame(
      title: '导出我的数据',
      content: [
        const PageTitle('把自己的味谱带走'),
        const InfoCard(
          label: '只包含你的数据',
          lines: [
            '服务端已保存的菜谱与全部版本、做菜记录、普通口味与量具、登记的本人事件及菜谱照片。',
            'JSON 带格式版本号，AI 生成与建议保留标记；不包含他人内容、内部分数和风控日志。',
          ],
        ),
        const BodyText(
          '仅保存在本机、尚未同步的草稿和操作不会进入服务端 ZIP。当前版本尚未支持库存、采购、规划、公开反馈等前置功能。家庭成员与过敏资料仍受现有敏感信息边界保护，不导出；ZIP 清单会明确列出未支持内容。',
          muted: true,
        ),
        if (!_verified)
          IdentityVerification(
            key: ValueKey(session.identityEpoch),
            onVerified: () =>
                setState(() => _verifiedIdentity = session.identity),
          )
        else
          const BodyText('已重新验证身份。后台打包，不必停留在本页。'),
        if (jobs.isLoading)
          const CircularProgressIndicator()
        else if (jobs.hasError) ...[
          ErrorText(ApiFailure.from(jobs.error!).message),
          SecondaryButton(
            label: '重试',
            onPressed: () => ref.invalidate(exportJobsProvider),
          ),
        ] else
          for (final job in jobs.value ?? const <ExportJobView>[]) _job(job),
        if (_error != null) ErrorText(_error!),
      ],
      actions: [
        PrimaryButton(
          key: const ValueKey('export-start'),
          label: '发起导出',
          busy: _busy,
          onPressed: _verified ? () => _run(notifier.start) : null,
        ),
        SecondaryButton(
          label: '刷新导出状态',
          onPressed: _busy ? null : () => _run(notifier.refresh),
        ),
        SecondaryButton(
          label: '查看导出格式说明',
          onPressed: () => ref
              .read(linkOpenerProvider)
              .open(
                Uri.parse(ref.read(appConfigProvider).apiBaseUrl)
                    .resolve('/data-export-format'),
              ),
        ),
      ],
    );
  }

  Widget _job(ExportJobView job) {
    final status = job.status.value;
    return InfoCard(
      label: switch (status) {
        'completed' => '导出已完成',
        'failed' => '导出未完成，可以重试',
        'expired' => '导出已过期，请重新发起',
        _ => '正在后台打包',
      },
      lines: [
        if (job.expiresAt != null) '有效期至 ${job.expiresAt}；到期自动删除。',
        if (status == 'completed')
          '下载仍需登录同一账号。用系统分享面板保存到文件或网盘。'
        else if (status == 'failed')
          '重试同一任务，不重复占用每日导出额度。'
        else if (status != 'expired')
          '完成后会在 App 内提醒。',
      ],
    ).withActions([
      if (status == 'completed' && job.downloadUrl != null)
        SecondaryButton(
          key: ValueKey('export-download-${job.id}'),
          label: '下载并保存 ZIP',
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final shared = await ref
                      .read(exportJobsProvider.notifier)
                      .download(job);
                  if (!mounted || !shared) return;
                  final web = ref.read(exportFileShareProvider).isWebSubstitute;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        web ? 'ZIP 已下载（网页测试替身，不保存到磁盘）' : '已打开系统分享面板',
                      ),
                    ),
                  );
                }),
        ),
      if (status == 'failed')
        SecondaryButton(
          label: '重试导出',
          onPressed: _busy || !_verified
              ? null
              : () => _run(
                  () => ref.read(exportJobsProvider.notifier).retry(job.id),
                ),
        ),
    ]);
  }
}

extension on InfoCard {
  Widget withActions(List<Widget> actions) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [this, ...actions],
  );
}
