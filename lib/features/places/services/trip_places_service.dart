import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/constants/image_service_config.dart';
import '../models/trip_place_suggestion.dart';

class TripPlacesService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final http.Client _client;

  TripPlacesService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? client,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client();

  Stream<TripPlacesResult> watchPlaces(String tripId) async* {
    final user = _requireUser();
    final trip = await _tripDocument(tripId);
    final data = trip.data() ?? const <String, dynamic>{};
    final memberIds = List<String>.from(data['memberIds'] as List? ?? const []);
    final adminIds = List<String>.from(data['adminIds'] as List? ?? const []);
    final isAdmin =
        data['createdBy'] == user.uid || adminIds.contains(user.uid);
    if (!isAdmin && !memberIds.contains(user.uid)) {
      throw const TripPlacesException('You are not a member of this trip.');
    }
    final imageHeaders = await _authorizationHeaders();

    await for (final snapshot in _places(
      tripId,
    ).orderBy('createdAt', descending: true).snapshots()) {
      yield TripPlacesResult(
        places: snapshot.docs
            .map((doc) => TripPlaceSuggestion.fromFirestore(doc.id, doc.data()))
            .toList(),
        viewerUid: user.uid,
        isAdmin: isAdmin,
        imageHeaders: imageHeaders,
      );
    }
  }

  Future<GooglePlacePreview> previewGooglePlace({
    required String tripId,
    required String mapsUrl,
  }) async {
    if (!isGoogleMapsUrl(mapsUrl)) {
      throw const TripPlacesException('Enter a valid Google Maps link.');
    }
    final response = await _client.post(
      _previewUri(tripId),
      headers: {
        ...await _authorizationHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'maps_url': mapsUrl.trim()}),
    );
    final data = _decode(response.body);
    _throwForResponse(response, data, 'Unable to read this Google Maps link.');
    return GooglePlacePreview.fromMap(data);
  }

  Future<void> addPlace({
    required String tripId,
    required GooglePlacePreview place,
    required String note,
  }) async {
    final user = _requireUser();
    try {
      await _places(tripId).add({
        ..._placeData(place, note),
        'uploadedBy': user.uid,
        'addedByName': _userName(user),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw TripPlacesException(
        _firebaseMessage(error, 'Unable to add this place.'),
      );
    }
  }

  Future<void> updatePlace({
    required String tripId,
    required TripPlaceSuggestion existing,
    required GooglePlacePreview place,
    required String note,
  }) async {
    await _ensureCanManage(tripId, existing);
    try {
      await _places(tripId).doc(existing.id).update({
        ..._placeData(place, note),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw TripPlacesException(
        _firebaseMessage(error, 'Unable to update this place.'),
      );
    }
  }

  Future<void> deletePlace({
    required String tripId,
    required TripPlaceSuggestion place,
  }) async {
    await _ensureCanManage(tripId, place);
    try {
      await _places(tripId).doc(place.id).delete();
    } on FirebaseException catch (error) {
      throw TripPlacesException(
        _firebaseMessage(error, 'Unable to delete this place.'),
      );
    }
  }

  Future<void> _ensureCanManage(
    String tripId,
    TripPlaceSuggestion place,
  ) async {
    final user = _requireUser();
    if (place.uploadedBy == user.uid) return;
    final trip = await _tripDocument(tripId);
    final data = trip.data() ?? const <String, dynamic>{};
    final adminIds = List<String>.from(data['adminIds'] as List? ?? const []);
    if (data['createdBy'] != user.uid && !adminIds.contains(user.uid)) {
      throw const TripPlacesException(
        'Only the person who added this place or a trip admin can change it.',
      );
    }
  }

  Future<void> openInGoogleMaps(String mapsUrl) async {
    if (!isGoogleMapsUrl(mapsUrl)) {
      throw const TripPlacesException('This Google Maps link is invalid.');
    }
    try {
      final opened = await launchUrl(
        Uri.parse(mapsUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw const TripPlacesException('Unable to open Google Maps.');
      }
    } on MissingPluginException {
      throw const TripPlacesException(
        'Restart the app to enable Google Maps links.',
      );
    } on PlatformException catch (error) {
      throw TripPlacesException(error.message ?? 'Unable to open Google Maps.');
    }
  }

  String placePhotoUrl(String tripId, String photoName) {
    final base = _placesUri(tripId);
    return base
        .replace(
          path: '${base.path}/photo',
          queryParameters: {'name': photoName},
        )
        .toString();
  }

  CollectionReference<Map<String, dynamic>> _places(String tripId) => _firestore
      .collection(FirestoreCollections.trips)
      .doc(tripId)
      .collection(FirestoreCollections.places);

  Future<DocumentSnapshot<Map<String, dynamic>>> _tripDocument(
    String tripId,
  ) async {
    try {
      final trip = await _firestore
          .collection(FirestoreCollections.trips)
          .doc(tripId)
          .get();
      if (!trip.exists) {
        throw const TripPlacesException('This trip no longer exists.');
      }
      return trip;
    } on FirebaseException catch (error) {
      throw TripPlacesException(
        _firebaseMessage(error, 'Unable to load this trip.'),
      );
    }
  }

  Map<String, dynamic> _placeData(GooglePlacePreview place, String note) => {
    'name': place.name,
    'location': place.location,
    'note': note.trim(),
    'mapsUrl': place.mapsUrl,
    'type': place.type,
    'googlePlaceId': place.placeId,
    'googlePhotoName': place.photoName,
    'googleAttribution': place.attribution,
  };

  Uri _placesUri(String tripId) {
    if (!ImageServiceConfig.isConfigured) {
      throw const TripPlacesException(
        'The image service is not configured for this app.',
      );
    }
    return Uri.parse('${ImageServiceConfig.baseUrl}/v1/trips/$tripId/places');
  }

  Uri _previewUri(String tripId) {
    final places = _placesUri(tripId);
    return places.replace(path: '${places.path}/preview');
  }

  Future<Map<String, String>> authorizationHeaders() => _authorizationHeaders();

  Future<Map<String, String>> _authorizationHeaders() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const TripPlacesException('Please sign in to use trip places.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const TripPlacesException('Please sign in to use trip places.');
    }
    return user;
  }

  static String _userName(User user) =>
      user.displayName?.trim().isNotEmpty == true
      ? user.displayName!.trim()
      : (user.email?.split('@').first ?? 'Trip member');

  static String _firebaseMessage(FirebaseException error, String fallback) =>
      error.code == 'permission-denied'
      ? 'Firestore blocked this action. Deploy the Places security rules.'
      : fallback;

  static bool isGoogleMapsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    final isGoogleDomain = RegExp(r'(^|\.)google\.[a-z.]+$').hasMatch(host);
    return host == 'maps.app.goo.gl' ||
        host == 'goo.gl' ||
        (isGoogleDomain &&
            (host.startsWith('maps.google.') ||
                uri.path == '/maps' ||
                uri.path.startsWith('/maps/')));
  }

  static void _throwForResponse(
    http.Response response,
    Map<String, dynamic> data,
    String fallback,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TripPlacesException(data['message'] as String? ?? fallback);
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
}

class TripPlacesException implements Exception {
  final String message;

  const TripPlacesException(this.message);
}
