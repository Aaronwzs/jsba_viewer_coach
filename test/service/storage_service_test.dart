import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/service/storage_service.dart';

class MockClient extends Mock implements http.Client {}

class UriFake extends Fake implements Uri {}

/// Wraps a JSON response string into a [http.StreamedResponse] for mocking.
http.StreamedResponse _streamedResponse(String body, int statusCode) {
  final stream = http.ByteStream.fromBytes(utf8.encode(body));
  return http.StreamedResponse(stream, statusCode);
}

void main() {
  group('StorageService', () {
    setUpAll(() {
      registerFallbackValue(UriFake());
      registerFallbackValue(http.MultipartRequest('POST', Uri.parse('https://example.com')));
    });

    test('uploadImage returns URL on success', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse(
          '{"success": true, "data": {"url": "https://example.com/img.jpg"}}',
          200,
        ),
      );

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test.png');
      await file.writeAsBytes([1, 2, 3]);
      final result = await service.uploadImage(file);
      await file.delete();
      expect(result, 'https://example.com/img.jpg');
    });

    test('uploadImage throws StorageException on failure response', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse(
          '{"success": false, "error": {"message": "Invalid image"}}',
          200,
        ),
      );

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test2.png');
      await file.writeAsBytes([1, 2, 3]);
      expect(
        () => service.uploadImage(file),
        throwsA(isA<StorageException>()),
      );
      await file.delete();
    });

    test('uploadImage throws StorageException on HTTP error', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse(
          '{"error": {"message": "Invalid API key"}}',
          400,
        ),
      );

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test3.png');
      await file.writeAsBytes([1, 2, 3]);
      expect(
        () => service.uploadImage(file),
        throwsA(isA<StorageException>()),
      );
      await file.delete();
    });

    test('uploadImage throws StorageException on network exception', () async {
      final client = MockClient();
      when(() => client.send(any())).thenThrow(Exception('Connection refused'));

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test4.png');
      await file.writeAsBytes([1, 2, 3]);
      expect(
        () => service.uploadImage(file),
        throwsA(isA<StorageException>()),
      );
      await file.delete();
    });

    test('deleteImage does nothing', () async {
      final service = StorageService();
      await service.deleteImage('http://example.com/img.jpg');
    });
  });
}
