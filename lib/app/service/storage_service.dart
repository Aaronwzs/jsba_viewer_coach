import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:jsba_app/app/assets/constants/environment_config.dart';

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => message;
}

/// Uploads images directly to ImageKit from the client using the server-side
/// private key.
///
/// ⚠️ Security warning: the ImageKit private key is compiled into the app
/// binary. This matches the previous imgBB integration's trust model, but for
/// production apps that need to protect the key, move the upload call to a
/// backend endpoint (e.g., Firebase Cloud Function) that holds the private key
/// and returns only the public URL to the client.
class StorageService {
  static const String _imageKitUploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';
  static const String _defaultFileName = 'upload.jpg';
  final http.Client? _client;
  final String _privateKey;

  StorageService({http.Client? client, String? privateKey})
    : _client = client,
      _privateKey = privateKey ?? EnvValues.imageKitPrivateKey;

  /// Uploads image bytes to ImageKit using multipart POST.
  ///
  /// Accepts raw [bytes] of the file and an optional [fileName] (defaults to
  /// 'upload.jpg'). On success returns the public URL of the uploaded image.
  /// Throws [StorageException] with a descriptive message on failure.
  ///
  /// This version accepts [Uint8List] instead of [File] so it works on web
  /// (where `dart:io.File` is unavailable) and on native platforms.
  Future<String> uploadImage(Uint8List bytes, {String? fileName}) async {
    if (_privateKey.isEmpty) {
      throw const StorageException(
        'ImageKit private key missing (IMAGEKIT_PRIVATE_KEY)',
      );
    }

    final uri = Uri.parse(_imageKitUploadUrl);

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] =
        'Basic ${base64Encode(utf8.encode('$_privateKey:'))}';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName ?? _defaultFileName,
      ),
    );
    request.fields['fileName'] = fileName ?? _defaultFileName;

    final client = _client ?? http.Client();
    try {
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return url;
        }
        final errorMsg = data['message'] as String? ?? 'Unknown upload error';
        throw StorageException(errorMsg);
      }

      // Try to parse error body for a better message; fall back to raw body
      // so debugging failed uploads is easier.
      try {
        final errorData = json.decode(response.body);
        final errorMsg =
            errorData['message'] as String? ?? errorData['error'] as String?;
        if (errorMsg != null) {
          throw StorageException(errorMsg);
        }
      } catch (e) {
        if (e is! StorageException) {
          throw StorageException(
            'Upload failed (HTTP ${response.statusCode}): ${response.body}',
          );
        }
      }

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
    // ImageKit file deletion requires the fileId returned at upload time.
    // Because uploadImage only returns the public URL, deletion is not
    // currently implemented. Extend uploadImage to return fileId if needed.
    throw UnimplementedError(
      'deleteImage is not implemented because uploadImage does not return a fileId',
    );
  }

}

