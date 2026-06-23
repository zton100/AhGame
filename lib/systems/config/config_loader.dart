import 'package:flutter/services.dart';

class ConfigLoader {
  const ConfigLoader({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  Future<String> loadRaw(String assetPath) {
    final bundle = _bundle ?? rootBundle;
    return bundle.loadString(assetPath);
  }
}
