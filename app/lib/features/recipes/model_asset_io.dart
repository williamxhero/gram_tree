import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> materializeModelAsset(String? path) async {
  if (path == null || !path.startsWith('assets/')) return path;
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${path.split('/').last}');
  final bytes = await rootBundle.load(path);
  if (!await file.exists() || await file.length() != bytes.lengthInBytes) {
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }
  return file.path;
}
