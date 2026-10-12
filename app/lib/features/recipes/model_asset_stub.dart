import 'package:flutter/services.dart';

Future<String?> materializeModelAsset(String? path) async => path;

Future<ByteData> loadModelAsset(String path) => rootBundle.load(path);
