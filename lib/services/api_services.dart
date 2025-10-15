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

  // Debug fields: store last response for /challan-types to help diagnose parsing/auth issues.
  String? _lastGetChallanTypesRawBody;
  int? _lastGetChallanTypesStatus;

  /// Public getters for debug fields (read-only)
  int? get lastGetChallanTypesStatus => _lastGetChallanTypesStatus;

  String? get lastGetChallanTypesRawBody => _lastGetChallanTypesRawBody;

  /// Backwards-compatible methods to return last challan-types status and raw body
  /// (useful for callers that prefer method access)
  int? getLastChallanTypesStatus() => _lastGetChallanTypesStatus;

  String? getLastChallanTypesRawBody() => _lastGetChallanTypesRawBody;

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
  Future<List<String>> uploadChallanImages(
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
      if (path.endsWith('.png')) {
        mimeSub = 'png';
      } else if (path.endsWith('.jpg') || path.endsWith('.jpeg'))
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
        return List.from(
          decoded['data']['uploaded_files'],
        ).map<String>((upload) => upload['path']).toList();
      } else {
        throw Exception(decoded['message'] ?? 'Unexpected upload response');
      }
    } else {
      String msg = 'Image upload failed with status ${resp.statusCode}';
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
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
    // Store raw response for diagnostics
    _lastGetChallanTypesStatus = response.statusCode;
    _lastGetChallanTypesRawBody = response.body;

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
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Fetch challans from the server.
  /// If [id] is provided this will call GET /challans/<id> and return a list
  /// containing one mapped challan. Otherwise it will call GET /challans and
  /// attempt to map all returned challans.
  Future<List<ChallanResponse>> getChallans({int? id}) async {
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
        final List<ChallanResponse> out = [];

        // Handle the new API response structure
        if (data is Map && data['challans'] is List) {
          // Multiple challans in 'challans' array
          for (final item in (data['challans'] as List)) {
            if (item is Map<String, dynamic>) {
              // Convert relative image URLs to full URLs
              final challanData = Map<String, dynamic>.from(item);
              if (challanData['image_urls'] is List) {
                final imageUrls = (challanData['image_urls'] as List)
                    .map((url) => _convertToFullImageUrl(url.toString()))
                    .toList();
                challanData['image_urls'] = imageUrls;
              }
              out.add(ChallanResponse.fromJson(challanData));
            }
          }
        } else if (data is Map && data['challan'] != null) {
          // Single challan returned under 'challan'
          final challanData = Map<String, dynamic>.from(data['challan']);
          if (challanData['image_urls'] is List) {
            final imageUrls = (challanData['image_urls'] as List)
                .map((url) => _convertToFullImageUrl(url.toString()))
                .toList();
            challanData['image_urls'] = imageUrls;
          }
          out.add(ChallanResponse.fromJson(challanData));
        } else {
          // Unexpected shape - try to handle legacy format
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
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
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
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Fetch images for a specific challan id and return objects containing id and url.
  /// This is useful when the client needs the server image id for operations like delete.
  Future<List<String>> getChallanImageObjects(int challanId) async {
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
          return images.map<String>((e) {
            return "${Constants.apiBaseUrl}/${e['image_path']}";
          }).toList();
        }
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
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Fetch transactions for a specific challan id.
  /// Returns the `data` map from the API (may contain `transactions`, `transaction_count`, `total_amount`, etc.).
  Future<Map<String, dynamic>> getChallanTransactions(int challanId) async {
    final url = Uri.parse('$baseUrl/challans/$challanId/transactions');
    final headers = await getAuthHeaders();
    final response = await http.get(url, headers: headers);

    print('[ApiService] GET $url -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['status'] == 'success') {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        // If data is missing but response is success, return an empty map.
        return <String, dynamic>{};
      } else {
        final message = (decoded is Map && decoded['message'] != null)
            ? decoded['message']
            : 'Unexpected response';
        throw Exception(message);
      }
    } else {
      String msg =
          'Failed to fetch transactions (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Delete a challan image identified by challanId and imageId.
  /// Throws on non-success responses.
  Future<void> deleteChallanImage(int challanId, int imageId) async {
    final url = Uri.parse('$baseUrl/challans/$challanId/images/$imageId');
    final headers = await getAuthHeaders();
    final response = await http.delete(url, headers: headers);

    print('[ApiService] DELETE $url -> ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      // success
      return;
    } else {
      String msg = 'Failed to delete image (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Delete a challan by id. Throws on non-success responses.
  Future<void> deleteChallan(int challanId) async {
    final url = Uri.parse('$baseUrl/challans/$challanId');
    final headers = await getAuthHeaders();
    final response = await http.delete(url, headers: headers);

    print('[ApiService] DELETE $url -> ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      // success
      return;
    } else {
      String msg = 'Failed to delete challan (status ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Create a transaction for a challan payment
  /// Throws on non-success responses.
  Future<Map<String, dynamic>> createTransaction({
    required int challanId,
    required String orderStatus,
    String? orderId,
    int? employeeId,
    String? paymentMethod,
    String? paymentReference,
    required double amount,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/transactions');
    final headers = await getAuthHeaders();
    final body = jsonEncode({
      'challan_id': challanId,
      'order_status': orderStatus,
      'order_id': orderId,
      'employee_id': employeeId,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'amount': amount,
      'notes': notes,
    });

    final response = await http.post(url, headers: headers, body: body);

    print('[ApiService] POST $url -> ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['status'] == 'success' &&
          decoded['data'] != null) {
        return Map<String, dynamic>.from(decoded['data']);
      } else {
        final message = decoded['message'] ?? 'Unexpected response from server';
        throw Exception(message);
      }
    } else {
      String msg =
          'Create transaction failed with status ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Convert relative image URL to full URL
  String _convertToFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Handle relative URLs that start with /
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    // Handle relative URLs without leading /
    return '$baseUrl/$imageUrl';
  }
}
