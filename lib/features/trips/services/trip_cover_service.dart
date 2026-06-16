import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/image_service_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/trip_cover_upload.dart';

class TripCoverService {
  static const int maximumCoverBytes = 5 * 1024 * 1024;

  final http.Client _client;

  TripCoverService({http.Client? client}) : _client = client ?? http.Client();

  Future<TripCoverUpload> uploadTripCover({
    required String idToken,
    required String tripId,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!ImageServiceConfig.isConfigured) {
      throw const TripCoverException(
        'The image service is not configured for this app.',
      );
    }
    if (bytes.lengthInBytes > maximumCoverBytes) {
      throw const TripCoverException('Choose a cover image smaller than 5 MB.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              '${ImageServiceConfig.baseUrl}/v1/trips/$tripId/cover-photo',
            ),
          )
          ..headers['Authorization'] = 'Bearer $idToken'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: filename,
              contentType: _imageContentType(filename),
            ),
          );

    AppLogger.info(
      'TripCoverService',
      'Uploading trip cover photo (${bytes.lengthInBytes} bytes).',
    );

    late http.StreamedResponse response;
    String responseBody = '';
    try {
      response = await _client.send(request);
      responseBody = await response.stream.bytesToString();
    } catch (error, stackTrace) {
      AppLogger.error('TripCoverService.upload', error, stackTrace: stackTrace);
      rethrow;
    }

    final data = _decodeResponse(responseBody);
    AppLogger.info(
      'TripCoverService',
      'Upload response status: ${response.statusCode}.',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TripCoverException(
        data['message'] as String? ?? 'Unable to upload trip cover image.',
      );
    }

    final url = data['secure_url'] as String?;
    final publicId = data['public_id'] as String?;
    if (url == null || publicId == null) {
      throw const TripCoverException(
        'Cloudinary returned an invalid upload response.',
      );
    }

    return TripCoverUpload(url: url, publicId: publicId);
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map<String, dynamic> ? data : const {};
    } catch (_) {
      return const {};
    }
  }

  static MediaType _imageContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;

    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      'heic' || 'heif' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}

class TripCoverException implements Exception {
  final String message;

  const TripCoverException(this.message);
}
