import 'package:cloud_firestore/cloud_firestore.dart';

class TripPlaceSuggestion {
  final String id;
  final String uploadedBy;
  final String addedByName;
  final DateTime createdAt;
  final String name;
  final String location;
  final String note;
  final String mapsUrl;
  final String type;
  final String googlePlaceId;
  final String googlePhotoName;
  final String googleAttribution;

  const TripPlaceSuggestion({
    required this.id,
    required this.uploadedBy,
    required this.addedByName,
    required this.createdAt,
    required this.name,
    required this.location,
    required this.note,
    required this.mapsUrl,
    required this.type,
    required this.googlePlaceId,
    required this.googlePhotoName,
    required this.googleAttribution,
  });

  bool get isAccommodation => type == 'accommodation';

  factory TripPlaceSuggestion.fromFirestore(
    String id,
    Map<String, dynamic> map,
  ) {
    final createdAt = map['createdAt'];
    return TripPlaceSuggestion(
      id: id,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      addedByName: map['addedByName'] as String? ?? 'Trip member',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      name: map['name'] as String? ?? 'Suggested place',
      location: map['location'] as String? ?? '',
      note: map['note'] as String? ?? '',
      mapsUrl: map['mapsUrl'] as String? ?? '',
      type: map['type'] == 'accommodation' ? 'accommodation' : 'visit',
      googlePlaceId: map['googlePlaceId'] as String? ?? '',
      googlePhotoName: map['googlePhotoName'] as String? ?? '',
      googleAttribution: map['googleAttribution'] as String? ?? '',
    );
  }
}

class TripPlacesResult {
  final List<TripPlaceSuggestion> places;
  final String viewerUid;
  final bool isAdmin;
  final Map<String, String> imageHeaders;

  const TripPlacesResult({
    required this.places,
    required this.viewerUid,
    required this.isAdmin,
    required this.imageHeaders,
  });
}

class GooglePlacePreview {
  final String placeId;
  final String name;
  final String location;
  final String mapsUrl;
  final String type;
  final String photoName;
  final String attribution;

  const GooglePlacePreview({
    required this.placeId,
    required this.name,
    required this.location,
    required this.mapsUrl,
    required this.type,
    required this.photoName,
    required this.attribution,
  });

  bool get isAccommodation => type == 'accommodation';

  factory GooglePlacePreview.fromMap(Map<String, dynamic> map) {
    return GooglePlacePreview(
      placeId: map['google_place_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Suggested place',
      location: map['location'] as String? ?? '',
      mapsUrl: map['maps_url'] as String? ?? '',
      type: map['place_type'] == 'accommodation' ? 'accommodation' : 'visit',
      photoName: map['google_photo_name'] as String? ?? '',
      attribution: map['google_attribution'] as String? ?? '',
    );
  }

  factory GooglePlacePreview.fromPlace(TripPlaceSuggestion place) {
    return GooglePlacePreview(
      placeId: place.googlePlaceId,
      name: place.name,
      location: place.location,
      mapsUrl: place.mapsUrl,
      type: place.type,
      photoName: place.googlePhotoName,
      attribution: place.googleAttribution,
    );
  }
}
