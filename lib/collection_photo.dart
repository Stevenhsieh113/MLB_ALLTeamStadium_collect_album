import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// 使用者上傳照片：壓縮後存成 data URL，方便 Web / 本機共用 SharedPreferences。
class CollectionPhoto {
  static const dataUrlPrefix = 'data:image/jpeg;base64,';
  static const maxWidth = 800;
  static const jpegQuality = 70;

  static bool isStoredPhoto(String? value) =>
      value != null && value.startsWith('data:image');

  /// 從相簿／本機選圖，回傳可寫入 JSON 的 data URL；取消則回 null。
  static Future<String?> pickAndEncode() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      // Web 上 maxWidth 也有幫助，再搭配下方二次壓縮
      maxWidth: maxWidth.toDouble(),
      imageQuality: jpegQuality,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return encodeBytes(bytes);
  }

  static String encodeBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('無法解析這張圖片，請換一張再試');
    }

    var image = decoded;
    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }

    final jpg = img.encodeJpg(image, quality: jpegQuality);
    return '$dataUrlPrefix${base64Encode(jpg)}';
  }

  static Uint8List? decodeBytes(String? stored) {
    if (!isStoredPhoto(stored)) return null;
    final comma = stored!.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(stored.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  /// 顯示已上傳照片；無法解碼時顯示錯誤佔位。
  static Widget preview(String? stored, {double height = 120}) {
    final bytes = decodeBytes(stored);
    if (bytes == null) {
      return _placeholder(
        height: height,
        child: const Text(
          '📷 點此上傳照片',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  static Widget _placeholder({required double height, required Widget child}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(child: child),
    );
  }
}
