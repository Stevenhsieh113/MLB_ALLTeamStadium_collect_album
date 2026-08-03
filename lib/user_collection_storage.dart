import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// 讀寫使用者收藏 JSON（勾選與照片路徑）。
/// 範本：`assets/user_collection.json`；執行時寫入本機快取（勾選即更新）。
class UserCollectionStorage {
  static const assetTemplatePath = 'assets/user_collection.json';
  static const prefKey = 'user_collection_json';

  static String stadiumIdFromImagePath(String stadiumImagePath) {
    final fileName = p.basename(stadiumImagePath);
    return p.basenameWithoutExtension(fileName);
  }

  static Map<String, dynamic> entryFromStadium({
    required bool hasTicket,
    required bool hasCap,
    required bool hasBobblehead,
    required String? ticketPhotoPath,
    required String? capPhotoPath,
    required String? bobbleheadPhotoPath,
  }) {
    return {
      'hasTicket': hasTicket,
      'hasCap': hasCap,
      'hasBobblehead': hasBobblehead,
      'ticketPhotoPath': ticketPhotoPath,
      'capPhotoPath': capPhotoPath,
      'bobbleheadPhotoPath': bobbleheadPhotoPath,
    };
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(prefKey);
    if (cached != null && cached.trim().isNotEmpty) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }

    final template = await rootBundle.loadString(assetTemplatePath);
    final data = jsonDecode(template) as Map<String, dynamic>;
    await saveDocument(data);
    return data;
  }

  static Future<void> saveDocument(Map<String, dynamic> data) async {
    final text = const JsonEncoder.withIndent('  ').convert(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, text);
  }
}
