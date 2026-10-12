import 'package:flutter/services.dart';

Future<String?> materializeModelAsset({
  required String? assetKey,
  String? nativeFileName,
}) async => assetKey;

Future<ByteData> loadModelAsset(String path) => rootBundle.load(path);
