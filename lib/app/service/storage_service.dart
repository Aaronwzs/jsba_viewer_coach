import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jsba_app/app/assets/constants/environment_config.dart';

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => message;
}

class StorageService {
  static const String _imgbbUrl = 'https://api.imgbb.com/1/upload';
  final http.Client? _client;
  final String _imgbbApiKey;

  StorageService({http.Client? client})
      : _client = client,
        _imgbbApiKey = EnvValues.imgbbApiKey;

  /// Uploads an image file to imgbb using multipart POST.
  ///
  /// Returns the URL of the uploaded image on success.
  /// Throws [StorageException] with a descriptive message on failure.
  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('$_imgbbUrl?key=$_imgbbApiKey');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final client = _client ?? http.Client();
    try {
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
        final errorMsg = data['error']['message'] as String? ?? 'Unknown upload error';
        throw StorageException(errorMsg);
      }

      // Try to parse error body for a better message
      try {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['error']['message'] as String? ?? errorData['status_txt'] as String?;
        if (errorMsg != null) {
          throw StorageException(errorMsg);
        }
      } catch (_) {}

      throw StorageException('Upload failed (HTTP ${response.statusCode})');
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Upload error: ${e.toString()}');
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<void> deleteImage(String url) async {
    // Imgbb doesn't provide delete API for free tier
  }
}
