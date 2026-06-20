import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/service/storage_service.dart';

class MockClient extends Mock implements http.Client {}

class UriFake extends Fake implements Uri {}

class MultipartRequestFake extends Fake implements http.MultipartRequest {}

/// Wraps a JSON response string into a [http.StreamedResponse] for mocking.
http.StreamedResponse _streamedResponse(String body, int statusCode) {
  final stream = http.ByteStream.fromBytes(utf8.encode(body));
  return http.StreamedResponse(stream, statusCode);
}

void main() {
  group('StorageService', () {
    setUpAll(() {
      registerFallbackValue(UriFake());
      registerFallbackValue(
        http.MultipartRequest('POST', Uri.parse('https://example.com')),
      );
    });

    test('uploadImage returns URL on success', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse(
          '{"fileId": "abc123", "url": "https://ik.imagekit.io/example/img.jpg"}',
          200,
        ),
      );

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await service.uploadImage(bytes, fileName: 'test.png');
      expect(result, 'https://ik.imagekit.io/example/img.jpg');
    });

    test(
      'uploadImage throws StorageException when private key is missing',
      () async {
        final service = StorageService();
        final bytes = Uint8List.fromList([1, 2, 3]);
        expect(service.uploadImage(bytes), throwsA(isA<StorageException>()));
      },
    );

    test('uploadImage sends correct request', () async {
      final client = MockClient();
      http.MultipartRequest? capturedRequest;
      when(() => client.send(any())).thenAnswer((invocation) async {
        capturedRequest =
            invocation.positionalArguments.first as http.MultipartRequest;
        return _streamedResponse(
          '{"fileId": "abc123", "url": "https://ik.imagekit.io/example/img.jpg"}',
          200,
        );
      });

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3]);
      await service.uploadImage(bytes, fileName: 'test_request.png');

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('test_key:'))}',
      );
      expect(capturedRequest!.fields['fileName'], 'test_request.png');
      expect(capturedRequest!.files.length, 1);
      expect(capturedRequest!.files.first.field, 'file');
    });

    test('uploadImage throws StorageException on failure response', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse('{"message": "Invalid file"}', 200),
      );

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(service.uploadImage(bytes), throwsA(isA<StorageException>()));
    });

    test('uploadImage throws StorageException on HTTP error', () async {
      final client = MockClient();
      when(() => client.send(any())).thenAnswer(
        (_) async => _streamedResponse('{"message": "Invalid API key"}', 400),
      );

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(service.uploadImage(bytes), throwsA(isA<StorageException>()));
    });

    test(
      'uploadImage throws StorageException with raw body on malformed error',
      () async {
        final client = MockClient();
        when(
          () => client.send(any()),
        ).thenAnswer((_) async => _streamedResponse('not json', 500));

        final service = StorageService(client: client, privateKey: 'test_key');
        final bytes = Uint8List.fromList([1, 2, 3]);
        expect(
          service.uploadImage(bytes),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('not json'),
            ),
          ),
        );
      },
    );

    test('uploadImage throws StorageException on network exception', () async {
      final client = MockClient();
      when(() => client.send(any())).thenThrow(Exception('Connection refused'));

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(service.uploadImage(bytes), throwsA(isA<StorageException>()));
    });

    test('deleteImage throws UnimplementedError', () async {
      final service = StorageService();
      expect(
        service.deleteImage('http://example.com/img.jpg'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
