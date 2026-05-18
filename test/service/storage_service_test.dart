import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/service/storage_service.dart';

class MockClient extends Mock implements http.Client {}

class UriFake extends Fake implements Uri {}

void main() {
  group('StorageService', () {
    setUpAll(() {
      registerFallbackValue(UriFake());
    });

    test('uploadImage returns URL on success', () async {
      final client = MockClient();
      when(() => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(
        '{"success": true, "data": {"url": "https://example.com/img.jpg"}}',
        200,
      ));

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test.png');
      await file.writeAsBytes([1, 2, 3]);
      final result = await service.uploadImage(file);
      await file.delete();
      expect(result, 'https://example.com/img.jpg');
    });

    test('uploadImage returns null on failure response', () async {
      final client = MockClient();
      when(() => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(
        '{"success": false}',
        200,
      ));

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test2.png');
      await file.writeAsBytes([1, 2, 3]);
      final result = await service.uploadImage(file);
      await file.delete();
      expect(result, isNull);
    });

    test('uploadImage returns null on exception', () async {
      final client = MockClient();
      when(() => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenThrow(Exception('Network error'));

      final service = StorageService(client: client);
      final file = File('${Directory.systemTemp.path}/test3.png');
      await file.writeAsBytes([1, 2, 3]);
      final result = await service.uploadImage(file);
      await file.delete();
      expect(result, isNull);
    });

    test('deleteImage does nothing', () async {
      final service = StorageService();
      await service.deleteImage('http://example.com/img.jpg');
    });
  });
}
