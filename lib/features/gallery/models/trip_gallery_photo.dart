class TripGalleryPhoto {
  final String publicId;
  final String secureUrl;
  final String uploadedBy;
  final DateTime createdAt;
  final String filename;
  final int? width;
  final int? height;
  final int? bytes;

  const TripGalleryPhoto({
    required this.publicId,
    required this.secureUrl,
    required this.uploadedBy,
    required this.createdAt,
    required this.filename,
    required this.width,
    required this.height,
    required this.bytes,
  });

  factory TripGalleryPhoto.fromMap(Map<String, dynamic> map) {
    final publicId = map['public_id'] as String? ?? '';
    final explicitOwner = map['uploaded_by'] as String? ?? '';
    final publicIdParts = publicId.split('/');
    final ownerFromPath = publicIdParts.length >= 2
        ? publicIdParts[publicIdParts.length - 2]
        : '';
    return TripGalleryPhoto(
      publicId: publicId,
      secureUrl: map['secure_url'] as String? ?? '',
      uploadedBy: explicitOwner.isNotEmpty ? explicitOwner : ownerFromPath,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      filename: map['filename'] as String? ?? 'trip-photo',
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      bytes: (map['bytes'] as num?)?.toInt(),
    );
  }
}

class TripGalleryResult {
  final List<TripGalleryPhoto> photos;
  final String viewerUid;
  final bool isAdmin;

  const TripGalleryResult({
    required this.photos,
    required this.viewerUid,
    required this.isAdmin,
  });
}
