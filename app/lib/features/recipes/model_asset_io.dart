import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> materializeModelAsset({
  required String? assetKey,
  String? nativeFileName,
}) async {
  if (assetKey == null || !assetKey.startsWith('assets/')) return assetKey;
  final directory = await getTemporaryDirectory();
  final modelDirectory = Directory('${directory.path}/gramtree_models');
  await modelDirectory.create(recursive: true);
  final fileName = nativeFileName ?? assetKey.split('/').last;
  final file = File('${modelDirectory.path}/$fileName');
  final bytes = await rootBundle.load(assetKey);
  if (!await file.exists() || await file.length() != bytes.lengthInBytes) {
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }
  if (!await file.exists() || await file.length() != bytes.lengthInBytes) {
    throw StateError('无法将模型资源写入原生可读路径：$assetKey');
  }
  return file.path;
}
