import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  String? _token;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('admin_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('admin_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('admin_token');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Map<String, String> _headers([Map<String, String>? extra]) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse(api(path));
    final full = query != null && query.isNotEmpty ? uri.replace(queryParameters: query) : uri;
    final res = await http.get(full, headers: _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(Uri.parse(api(path)), headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(Uri.parse(api(path)), headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final json = jsonDecode(body);
    if (res.statusCode >= 400) {
      final msg = json is Map ? (json['error'] as String? ?? 'حدث خطأ') : 'حدث خطأ';
      throw ApiException(msg, res.statusCode, json is Map ? json['code'] as String? : null);
    }
    return json;
  }
}

class ApiException implements Exception {
  final String message;
  final int status;
  final String? code;
  ApiException(this.message, this.status, [this.code]);
  @override
  String toString() => message;
}
