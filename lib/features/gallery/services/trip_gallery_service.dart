import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/image_service_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/trip_gallery_photo.dart';

class TripGalleryService {
  static const int maximumPhotoBytes = 10 * 1024 * 1024;

  final FirebaseAuth _auth;
  final http.Client _client;

  TripGalleryService({FirebaseAuth? auth, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client();

  Future<TripGalleryResult> loadPhotos(String tripId) async {
    final response = await _client.get(
      _galleryUri(tripId),
      headers: await _authorizationHeaders(),
    );
    final data = _decode(response.body);
    _throwForResponse(response, data, 'Unable to load gallery photos.');
    final rawPhotos = data['photos'] as List? ?? const [];
    final photos = rawPhotos
        .whereType<Map>()
        .map(
          (item) => TripGalleryPhoto.fromMap(Map<String, dynamic>.from(item)),
        )
        .where(
          (photo) => photo.publicId.isNotEmpty && photo.secureUrl.isNotEmpty,
        )
        .toList();
    final apiViewerUid = data['viewer_uid'] as String? ?? '';
    return TripGalleryResult(
      photos: photos,
      viewerUid: apiViewerUid.isNotEmpty
          ? apiViewerUid
          : _auth.currentUser?.uid ?? '',
      isAdmin: data['is_admin'] as bool? ?? false,
    );
  }

  Future<void> uploadPhoto({
    required String tripId,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.lengthInBytes > maximumPhotoBytes) {
      throw const TripGalleryException('Choose a photo smaller than 10 MB.');
    }
    final request = http.MultipartRequest('POST', _galleryUri(tripId))
      ..headers.addAll(await _authorizationHeaders())
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _imageContentType(filename),
        ),
      );
    try {
      final response = await _client.send(request);
      final body = await response.stream.bytesToString();
      final data = _decode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 404) {
          throw const TripGalleryException(
            'The gallery API is not deployed yet. Deploy the updated image service.',
          );
        }
        throw TripGalleryException(
          data['message'] as String? ?? 'Unable to upload the photo.',
        );
      }
    } on TripGalleryException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'TripGalleryService.upload',
        error,
        stackTrace: stackTrace,
      );
      throw const TripGalleryException('Unable to upload the photo.');
    }
  }

  Future<void> deletePhoto({
    required String tripId,
    required TripGalleryPhoto photo,
  }) async {
    final response = await _client.delete(
      _galleryUri(tripId),
      headers: {
        ...await _authorizationHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'public_id': photo.publicId}),
    );
    final data = _decode(response.body);
    _throwForResponse(response, data, 'Unable to delete the photo.');
  }

  Future<void> downloadPhoto(TripGalleryPhoto photo) async {
    final safeName = photo.filename.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final downloadUrl = photo.secureUrl.replaceFirst(
      '/upload/',
      '/upload/fl_attachment:$safeName/',
    );
    try {
      final launched = await launchUrl(
        Uri.parse(downloadUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const TripGalleryException('Unable to start the photo download.');
      }
    } on MissingPluginException {
      throw const TripGalleryException(
        'Restart the app to enable photo downloads.',
      );
    } on PlatformException catch (error) {
      throw TripGalleryException(
        error.message ?? 'Unable to start the photo download.',
      );
    }
  }

  Uri _galleryUri(String tripId) {
    if (!ImageServiceConfig.isConfigured) {
      throw const TripGalleryException(
        'The image service is not configured for this app.',
      );
    }
    return Uri.parse(
      '${ImageServiceConfig.baseUrl}/v1/trips/$tripId/gallery-photos',
    );
  }

  Future<Map<String, String>> _authorizationHeaders() async {
    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    if (user == null || token == null) {
      throw const TripGalleryException('Please sign in to use the gallery.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  static void _throwForResponse(
    http.Response response,
    Map<String, dynamic> data,
    String fallback,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 404) {
        throw const TripGalleryException(
          'The gallery API is not deployed yet. Deploy the updated image service.',
        );
      }
      throw TripGalleryException(data['message'] as String? ?? fallback);
    }
  }

  static Map<String, dynamic> _decode(String body) {
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

class TripGalleryException implements Exception {
  final String message;

  const TripGalleryException(this.message);
}
