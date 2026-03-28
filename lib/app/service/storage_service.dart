import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class StorageService {
  static const String _imgbbApiKey = '9d1bc7b8e1546cf6900f9ec114d78434';
  static const String _imgbbUrl = 'https://api.imgbb.com/1/upload';

  Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_imgbbUrl?key=$_imgbbApiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'] as String;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String url) async {
    // Imgbb doesn't provide delete API for free tier
  }
}
