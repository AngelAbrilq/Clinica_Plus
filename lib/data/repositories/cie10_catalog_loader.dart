import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/cie10_entry.dart';

/// Lee el catálogo CIE-10 empaquetado en assets.
abstract final class Cie10CatalogLoader {
  static const String assetPath = 'assets/data/cie10_inicial.json';

  static Future<List<Cie10Entry>> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['codes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Cie10Entry.fromJson)
        .toList();
  }
}
