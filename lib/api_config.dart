import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static const String _prodDomain = String.fromEnvironment('API_DOMAIN');

  static String get baseUrl {
    if (_prodDomain.isNotEmpty) {
      return _prodDomain;
    }

    if (kIsWeb) {
      return "http://localhost:8000/api";
    }

    if (Platform.isAndroid) {
      return "http://192.168.10.77:8000/api";
    }

    if (Platform.isWindows) {
      return "http://127.0.0.1:8000/api";
    }

    // fallback
    return "http://localhost:8000/api";
  }
}
