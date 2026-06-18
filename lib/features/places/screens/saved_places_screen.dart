import 'package:flutter/material.dart';

import '../models/trip_place_suggestion.dart';
import '../services/trip_places_service.dart';

const _placesBlue = Color(0xFF2563EB);

class SavedPlacesScreen extends StatefulWidget {
  final String? tripId;

  const SavedPlacesScreen({super.key, this.tripId});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final TripPlacesService _service = TripPlacesService();
  late Stream<TripPlacesResult> _placesStream;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _placesStream = _watchPlaces();
  }

  Stream<TripPlacesResult> _watchPlaces() {
    final tripId = widget.tripId;
    if (tripId == null || tripId.isEmpty) {
      return Stream.error(
        const TripPlacesException('No trip was selected for these places.'),
      );
    }
    return _service.watchPlaces(tripId);
  }

  void _refresh() {
    setState(() {
      _placesStream = _watchPlaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: _placesBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Suggested Places',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add a place',
            onPressed: _saving ? null : () => _showPlaceDialog(),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: StreamBuilder<TripPlacesResult>(
        stream: _placesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _placesBlue),
            );
          }
          if (snapshot.hasError) {
            return _PlacesError(
              message: _errorMessage(snapshot.error),
              onRetry: _refresh,
            );
          }
          final result = snapshot.data!;
          if (result.places.isEmpty) {
            return _EmptyPlaces(onAdd: () => _showPlaceDialog());
          }
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: result.places.length,
              itemBuilder: (context, index) {
                final place = result.places[index];
                return _PlaceCard(
                  place: place,
                  imageUrl: place.googlePhotoName.isEmpty
                      ? null
                      : _service.placePhotoUrl(
                          widget.tripId!,
                          place.googlePhotoName,
                        ),
                  imageHeaders: result.imageHeaders,
                  isMine: place.uploadedBy == result.viewerUid,
                  canManage:
                      result.isAdmin || place.uploadedBy == result.viewerUid,
                  onMaps: () => _openMaps(place),
                  onEdit: () => _showPlaceDialog(place),
                  onDelete: () => _confirmDelete(place),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPlaceDialog([TripPlaceSuggestion? existing]) async {
    final noteController = TextEditingController(text: existing?.note ?? '');
    final mapsController = TextEditingController(text: existing?.mapsUrl ?? '');
    final formKey = GlobalKey<FormState>();
    GooglePlacePreview? preview = existing == null
        ? null
        : GooglePlacePreview.fromPlace(existing);
    Map<String, String> previewHeaders = const {};
    var loadingPreview = false;
    String? previewError;

    final draft = await showDialog<_PlaceDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Suggest a place' : 'Edit suggestion'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: mapsController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Google Maps link',
                        hintText: 'https://maps.app.goo.gl/...',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Google Maps link is required.';
                        }
                        if (!TripPlacesService.isGoogleMapsUrl(value)) {
                          return 'Enter a valid Google Maps link.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _placesBlue,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: loadingPreview
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                setDialogState(() {
                                  loadingPreview = true;
                                  previewError = null;
                                });
                                try {
                                  final result = await _service
                                      .previewGooglePlace(
                                        tripId: widget.tripId!,
                                        mapsUrl: mapsController.text,
                                      );
                                  final headers = await _service
                                      .authorizationHeaders();
                                  if (!dialogContext.mounted) return;
                                  setDialogState(() {
                                    preview = result;
                                    previewHeaders = headers;
                                    loadingPreview = false;
                                  });
                                } on TripPlacesException catch (error) {
                                  if (!dialogContext.mounted) return;
                                  setDialogState(() {
                                    previewError = error.message;
                                    loadingPreview = false;
                                  });
                                }
                              },
                        icon: loadingPreview
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.travel_explore),
                        label: Text(
                          loadingPreview
                              ? 'Loading place...'
                              : 'Get place details',
                        ),
                      ),
                    ),
                    if (previewError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        previewError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (preview != null) ...[
                      const SizedBox(height: 14),
                      _GooglePlacePreviewCard(
                        preview: preview!,
                        photoUrl: preview!.photoName.isEmpty
                            ? null
                            : _service.placePhotoUrl(
                                widget.tripId!,
                                preview!.photoName,
                              ),
                        imageHeaders: previewHeaders,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: noteController,
                        maxLength: 300,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Why do you suggest it? (optional)',
                          hintText: 'Best sunset view around 5:30 PM',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _placesBlue),
              onPressed: () {
                if (preview == null) return;
                Navigator.pop(
                  dialogContext,
                  _PlaceDraft(
                    note: noteController.text.trim(),
                    preview: preview!,
                  ),
                );
              },
              child: Text(existing == null ? 'Add place' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    if (draft != null && mounted) {
      await _savePlace(draft, existing);
    }

    // showDialog completes when the route is popped, while its closing
    // animation can still build the text fields for a short time.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    noteController.dispose();
    mapsController.dispose();
  }

  Future<void> _savePlace(
    _PlaceDraft draft,
    TripPlaceSuggestion? existing,
  ) async {
    final tripId = widget.tripId;
    if (tripId == null || _saving) return;
    setState(() => _saving = true);
    try {
      if (existing == null) {
        await _service.addPlace(
          tripId: tripId,
          place: draft.preview,
          note: draft.note,
        );
      } else {
        await _service.updatePlace(
          tripId: tripId,
          existing: existing,
          place: draft.preview,
          note: draft.note,
        );
      }
      if (!mounted) return;
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage(
            existing == null
                ? 'Place shared with the trip group.'
                : 'Place updated.',
          );
        }
      });
    } on TripPlacesException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        existing == null
            ? 'Unable to add this place.'
            : 'Unable to update this place.',
      );
    }
  }

  Future<void> _openMaps(TripPlaceSuggestion place) async {
    try {
      await _service.openInGoogleMaps(place.mapsUrl);
    } on TripPlacesException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _confirmDelete(TripPlaceSuggestion place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this suggestion?'),
        content: Text('"${place.name}" will be removed from the trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deletePlace(tripId: widget.tripId!, place: place);
      if (!mounted) return;
      _showMessage('Place deleted.');
    } on TripPlacesException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  String _errorMessage(Object? error) {
    return error is TripPlacesException
        ? error.message
        : 'Unable to load suggested places.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GooglePlacePreviewCard extends StatelessWidget {
  final GooglePlacePreview preview;
  final String? photoUrl;
  final Map<String, String> imageHeaders;

  const _GooglePlacePreviewCard({
    required this.preview,
    required this.photoUrl,
    required this.imageHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            width: double.infinity,
            child: photoUrl == null
                ? const ColoredBox(
                    color: Color(0xFFDBEAFE),
                    child: Icon(
                      Icons.place_outlined,
                      color: _placesBlue,
                      size: 54,
                    ),
                  )
                : Image.network(
                    photoUrl!,
                    headers: imageHeaders,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFDBEAFE),
                      child: Icon(
                        Icons.place_outlined,
                        color: _placesBlue,
                        size: 54,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _TypeBadge(isAccommodation: preview.isAccommodation),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  preview.location,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                if (preview.attribution.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Photo by ${preview.attribution}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final TripPlaceSuggestion place;
  final String? imageUrl;
  final Map<String, String> imageHeaders;
  final bool isMine;
  final bool canManage;
  final VoidCallback onMaps;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceCard({
    required this.place,
    required this.imageUrl,
    required this.imageHeaders,
    required this.isMine,
    required this.canManage,
    required this.onMaps,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl == null)
                    const ColoredBox(
                      color: Color(0xFFDBEAFE),
                      child: Icon(
                        Icons.landscape_outlined,
                        color: _placesBlue,
                        size: 54,
                      ),
                    )
                  else
                    Image.network(
                      imageUrl!,
                      headers: imageHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFDBEAFE),
                        child: Icon(
                          Icons.landscape_outlined,
                          color: _placesBlue,
                          size: 54,
                        ),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 13,
                    child: Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _TypeBadge(isAccommodation: place.isAccommodation),
                  ),
                  if (place.googleAttribution.isNotEmpty)
                    Positioned(
                      top: 11,
                      left: 11,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Photo: ${place.googleAttribution}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        place.location,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(place.note, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Added by ${isMine ? 'You' : place.addedByName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDCFCE7),
                        foregroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Maps'),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: 'Edit place',
                          onPressed: onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: _placesBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: 'Delete place',
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isAccommodation;

  const _TypeBadge({required this.isAccommodation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAccommodation ? Icons.hotel_outlined : Icons.place_outlined,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            isAccommodation ? 'Accommodation' : 'Place to visit',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPlaces({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _PlacesIllustration(),
            const SizedBox(height: 18),
            const Text(
              'No places suggested yet',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            const Text(
              'Share a place to visit or an accommodation for your trip group to try.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(backgroundColor: _placesBlue),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Suggest a place'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesIllustration extends StatelessWidget {
  const _PlacesIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 175,
            height: 175,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.08,
            child: Container(
              width: 145,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _placesBlue.withValues(alpha: .15),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: const Icon(
                Icons.map_outlined,
                color: Color(0xFF60A5FA),
                size: 70,
              ),
            ),
          ),
          const Positioned(
            top: 17,
            right: 31,
            child: Icon(Icons.location_on, color: _placesBlue, size: 58),
          ),
          const Positioned(
            left: 15,
            bottom: 20,
            child: CircleAvatar(
              radius: 23,
              backgroundColor: Color(0xFF16A34A),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlacesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 58, color: _placesBlue),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceDraft {
  final String note;
  final GooglePlacePreview preview;

  const _PlaceDraft({required this.note, required this.preview});
}
