import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/challan_response.dart';
import '../models/challan_type.dart';
import '../models/login_response.dart';
import '../models/register_response.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = Constants.apiBaseUrl;

  /// Return headers including Authorization if access_token present
  Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Upload images for a challan (multipart/form-data). Returns parsed JSON data on success.
  Future<Map<String, dynamic>> uploadChallanImages(
    int challanId,
    List<File> files,
  ) async {
    final url = Uri.parse('$baseUrl/challans/$challanId/upload-images');

    // Prepare multipart request
    final request = http.MultipartRequest('POST', url);
    final headers = await getAuthHeaders();
    // MultipartRequest will set its own Content-Type
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    for (final file in files) {
      final path = file.path.toLowerCase();
      String mimeMain = 'image';
      String mimeSub = 'jpeg';
      if (path.endsWith('.png'))
        mimeSub = 'png';
      else if (path.endsWith('.jpg') || path.endsWith('.jpeg'))
        mimeSub = 'jpeg';
      else if (path.endsWith('.webp'))
        mimeSub = 'webp';

      final multipartFile = await http.MultipartFile.fromPath(
        'files',
        file.path,
        contentType: MediaType(mimeMain, mimeSub),
      );
      request.files.add(multipartFile);
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        return decoded['data'] as Map<String, dynamic>;
      } else {
        throw Exception(decoded['message'] ?? 'Unexpected upload response');
      }
    } else {
      String msg = 'Image upload failed with status ${resp.statusCode}';
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['message'] != null)
          msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Fetch challan types from the server. Returns empty list on non-fatal errors.
  Future<List<ChallanType>> getChallanTypes() async {
    final url = Uri.parse('$baseUrl/challan-types');
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);

    // Keep helpful debug logging for developers
    print('[ApiService] GET $url -> ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        // Log raw body for debugging parsing issues
        print('[ApiService] getChallanTypes raw body: ${response.body}');
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          // Prefer explicit success flag from API
          final status = decoded['status']?.toString();
          if (status != null && status.toLowerCase() != 'success') {
            final msg = decoded['message'] ?? 'Failed to load challan types';
            print('[ApiService] getChallanTypes: status != success -> $msg');
            return [];
          }

          final data = decoded['data'];
          if (data == null) return [];

          // API may return the list under `challan_types` or return the list directly.
          List<dynamic> list = [];
          if (data is Map && data['challan_types'] is List) {
            list = data['challan_types'] as List<dynamic>;
          } else if (data is List) {
            list = data;
          } else {
            // unexpected shape
            print(
              '[ApiService] getChallanTypes: unexpected data shape: ${data.runtimeType}',
            );
            return [];
          }

          // Debug each raw item before mapping
          for (var i = 0; i < list.length; i++) {
            final item = list[i];
            print('[ApiService] challan_types[$i] raw: $item');
            if (item is Map && item.containsKey('fine_amount')) {
              print(
                '[ApiService] challan_types[$i].fine_amount = ${item['fine_amount']} (type=${item['fine_amount']?.runtimeType})',
              );
            }
          }

          return list
              .where((e) => e != null)
              .map((e) => ChallanType.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          print('[ApiService] getChallanTypes: decoded response not a Map');
          return [];
        }
      } catch (e) {
        print(
          '[ApiService] Failed to parse challan-types response: ${e.toString()}',
        );
        return [];
      }
    } else {
      // Surface HTTP errors so callers (UI) can show a proper message.
      String msg =
          'Failed to fetch challan types (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      print('[ApiService] getChallanTypes error: $msg');
      throw Exception(msg);
    }
  }

  Future<RegisterResponse> registerOfficer({
    required String username,
    required String mobile,
    required String email,
    required String loginId,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'mobile': mobile,
        'email': email,
        'login_id': loginId,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        return RegisterResponse.fromJson(decoded['data']);
      } else {
        final message = decoded['message'] ?? 'Unexpected response from server';
        throw Exception(message);
      }
    } else {
      String msg = 'Registration failed with status ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // Keep old OTP flow for backward compatibility
  Future<void> loginOfficer(String mobileNumber) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobileNumber': mobileNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  // New method: login with login_id and password
  Future<LoginResponse> loginWithCredentials(
    String loginId,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        return LoginResponse.fromJson(decoded['data']);
      } else {
        final message = decoded['message'] ?? 'Unexpected response from server';
        throw Exception(message);
      }
    } else {
      String msg = 'Login failed with status ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<ChallanResponse> createChallan({
    required String fullName,
    required String contactNumber,
    required int challanTypeId,
    required String challanName,
    required int fineAmount,
    required String description,
    required String wardNumber,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/challans');
    final headers = await getAuthHeaders();
    final body = jsonEncode({
      'full_name': fullName,
      'contact_number': contactNumber,
      'challan_type_id': challanTypeId,
      'challan_name': challanName,
      'fine_amount': fineAmount,
      'description': description,
      'ward_number': wardNumber,
      'latitude': latitude,
      'longitude': longitude,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        return ChallanResponse.fromJson(decoded['data']);
      } else {
        final message = decoded['message'] ?? 'Unexpected response from server';
        throw Exception(message);
      }
    } else {
      String msg = 'Create challan failed with status ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null)
          msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Create a challan and (optionally) upload images associated with it.
  ///
  /// This method will:
  /// 1. Create the challan by calling `createChallan`.
  /// 2. If `files` is non-empty, upload them using the challan id returned by the server.
  /// 3. Return the updated `ChallanResponse` (if upload returns updated challan data) or
  ///    the original created `ChallanResponse`.
  Future<ChallanResponse> createChallanWithImages({
    required String fullName,
    required String contactNumber,
    required int challanTypeId,
    required String challanName,
    required int fineAmount,
    required String description,
    required String wardNumber,
    required double latitude,
    required double longitude,
    List<File> files = const [],
  }) async {
    // 1) Create challan
    final created = await createChallan(
      fullName: fullName,
      contactNumber: contactNumber,
      challanTypeId: challanTypeId,
      challanName: challanName,
      fineAmount: fineAmount,
      description: description,
      wardNumber: wardNumber,
      latitude: latitude,
      longitude: longitude,
    );

    // If there are no files to upload, return the created challan immediately.
    if (files.isEmpty) return created;

    // Determine which id to use for uploading. Prefer challanId (server-facing), fall back to internal id.
    final int uploadId = (created.challanId != 0)
        ? created.challanId
        : created.id;

    try {
      final uploadData = await uploadChallanImages(uploadId, files);
      // uploadChallanImages returns decoded['data'] as Map<String, dynamic>.
      // Try to parse it into a ChallanResponse if it looks like one.
      if (uploadData.isNotEmpty) {
        try {
          return ChallanResponse.fromJson(uploadData);
        } catch (_) {
          // If parsing fails, just return the originally created challan.
          return created;
        }
      } else {
        return created;
      }
    } catch (e) {
      // If upload fails, surface a descriptive error including challan id.
      throw Exception(
        'Challan created (id=$uploadId) but image upload failed: ${e.toString()}',
      );
    }
  }

  /// Fetch challans from the server.
  /// If [id] is provided this will call GET /challans/<id> and return a list
  /// containing one mapped challan. Otherwise it will call GET /challans and
  /// attempt to map all returned challans.
  Future<List<Map<String, dynamic>>> getChallans({int? id}) async {
    final url = Uri.parse(
      id == null ? '$baseUrl/challans' : '$baseUrl/challans/$id',
    );
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);

    print('[ApiService] GET $url -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        final data = decoded['data'];
        final List<Map<String, dynamic>> out = [];

        // Single challan returned under `challan`
        if (data is Map && data['challan'] != null) {
          final c = data['challan'] as Map<String, dynamic>;
          out.add(_mapServerChallanToLocal(c));
        } else if (data is Map && data['challans'] is List) {
          for (final item in (data['challans'] as List)) {
            if (item is Map<String, dynamic>)
              out.add(_mapServerChallanToLocal(item));
          }
        } else if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>)
              out.add(_mapServerChallanToLocal(item));
          }
        } else {
          // Unexpected shape - try to coerce if possible
          print(
            '[ApiService] getChallans: unexpected data shape ${data.runtimeType}',
          );
        }

        return out;
      } else {
        final message = (decoded is Map && decoded['message'] != null)
            ? decoded['message']
            : 'Unexpected response';
        throw Exception(message);
      }
    } else {
      String msg = 'Failed to fetch challans (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null)
          msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Fetch images for a specific challan id.
  /// Returns a list of full image URLs.
  Future<List<String>> getChallanImages(int challanId) async {
    final url = Uri.parse('$baseUrl/challans/$challanId/images');
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);

    print('[ApiService] GET $url -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        final data = decoded['data'];
        if (data is Map && data['images'] is List) {
          final List images = data['images'] as List;

          String toFullUrl(String? p) {
            if (p == null) return '';
            // Normalize backslashes and leading slashes
            final normalized = p.replaceAll('\\', '/').replaceAll('//', '/');
            if (normalized.startsWith('/')) return '$baseUrl$normalized';
            return '$baseUrl/$normalized';
          }

          return images
              .where(
                (e) => e is Map && (e['image_path'] ?? e['image_name']) != null,
              )
              .map<String>((e) {
                final map = e as Map<String, dynamic>;
                final path =
                    (map['image_path'] ?? map['image_name'])?.toString() ?? '';
                return toFullUrl(path);
              })
              .toList();
        }
        // If data shape unexpected, return empty list
        return [];
      } else {
        final message = (decoded is Map && decoded['message'] != null)
            ? decoded['message']
            : 'Unexpected response';
        throw Exception(message);
      }
    } else {
      String msg =
          'Failed to fetch challan images (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null)
          msg = decoded['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Map a server challan JSON object to the app's local challan Map shape
  Map<String, dynamic> _mapServerChallanToLocal(Map<String, dynamic> src) {
    // Helper to build full URL for image paths that may be relative
    String toFullUrl(String? u) {
      if (u == null) return '';
      if (u.startsWith('http://') || u.startsWith('https://')) return u;
      if (u.startsWith('/')) return '$baseUrl$u';
      return '$baseUrl/$u';
    }

    final imageUrlsRaw =
        (src['image_urls'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final imageUrls = imageUrlsRaw.map((s) => toFullUrl(s)).toList();

    return {
      'id': src['id'] ?? 0,
      // server may expose a separate challan_id; if present include it
      'challan_id': src['challan_id'] ?? src['id'] ?? 0,
      'name': src['full_name'] ?? src['challan_name'] ?? 'Unknown',
      'mobile': src['contact_number'] ?? '',
      'latitude': (src['latitude'] is num)
          ? (src['latitude'] as num).toDouble()
          : 0.0,
      'longitude': (src['longitude'] is num)
          ? (src['longitude'] as num).toDouble()
          : 0.0,
      'rule': src['challan_name'] ?? src['rule'] ?? '',
      // keep amount as string to be compatible with existing usages
      'amount':
          src['fine_amount']?.toString() ?? (src['amount']?.toString() ?? '0'),
      'notes': src['description'] ?? src['notes'] ?? '-',
      'image_urls': imageUrls,
      'image_count': src['image_count'] ?? imageUrls.length,
      'status': src['status'] ?? 'Unpaid',
      'created_at': src['created_at'] ?? src['createdAt'] ?? '',
      // Keep a list of local File objects empty for server-fetched challans
      'images': <dynamic>[],
    };
  }
}
