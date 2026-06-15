import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/image_service_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/profile_photo_upload.dart';

class ProfilePhotoService {
  static const int maximumPhotoBytes = 2 * 1024 * 1024;

  final http.Client _client;

  ProfilePhotoService({http.Client? client})
    : _client = client ?? http.Client();

  Future<ProfilePhotoUpload> uploadProfilePhoto({
    required String idToken,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!ImageServiceConfig.isConfigured) {
      throw const ProfilePhotoException(
        'The image service is not configured for this app.',
      );
    }
    if (bytes.lengthInBytes > maximumPhotoBytes) {
      throw const ProfilePhotoException(
        'Choose a profile photo smaller than 2 MB.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ImageServiceConfig.baseUrl}/v1/profile-photo'),
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
      'ProfilePhotoService',
      'Uploading profile photo (${bytes.lengthInBytes} bytes, '
          '${_imageContentType(filename)}).',
    );

    late http.StreamedResponse response;
    String responseBody = '';
    try {
      response = await _client.send(request);
      responseBody = await response.stream.bytesToString();
    } catch (error, stackTrace) {
      AppLogger.error(
        'ProfilePhotoService.upload',
        error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    final data = _decodeResponse(responseBody);
    AppLogger.info(
      'ProfilePhotoService',
      'Upload response status: ${response.statusCode}.',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final nestedMessage = error is Map<String, dynamic>
          ? error['message'] as String?
          : null;
      throw ProfilePhotoException(
        data['message'] as String? ??
            nestedMessage ??
            'Unable to upload profile photo.',
      );
    }

    final url = data['secure_url'] as String?;
    final publicId = data['public_id'] as String?;
    if (url == null || publicId == null) {
      throw const ProfilePhotoException(
        'Cloudinary returned an invalid upload response.',
      );
    }

    return ProfilePhotoUpload(url: url, publicId: publicId);
  }

  Future<void> deleteProfilePhoto({required String idToken}) async {
    if (!ImageServiceConfig.isConfigured) {
      throw const ProfilePhotoException(
        'The image service is not configured for this app.',
      );
    }

    AppLogger.info('ProfilePhotoService', 'Deleting profile photo.');

    late http.Response response;
    try {
      response = await _client.delete(
        Uri.parse('${ImageServiceConfig.baseUrl}/v1/profile-photo'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'ProfilePhotoService.delete',
        error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    AppLogger.info(
      'ProfilePhotoService',
      'Delete response status: ${response.statusCode}.',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeResponse(response.body);
      throw ProfilePhotoException(
        data['message'] as String? ?? 'Unable to delete profile photo.',
      );
    }
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

class ProfilePhotoException implements Exception {
  final String message;

  const ProfilePhotoException(this.message);
}
