import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/trip_gallery_photo.dart';
import '../services/trip_gallery_service.dart';

const _galleryBlue = Color(0xFF2563EB);

class ImageGalleryScreen extends StatefulWidget {
  final String? tripId;

  const ImageGalleryScreen({super.key, this.tripId});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final TripGalleryService _service = TripGalleryService();
  late Future<TripGalleryResult> _galleryFuture;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _galleryFuture = _loadGallery();
  }

  Future<TripGalleryResult> _loadGallery() {
    final tripId = widget.tripId;
    if (tripId == null || tripId.isEmpty) {
      return Future.error(
        const TripGalleryException('No trip was selected for this gallery.'),
      );
    }
    return _service.loadPhotos(tripId);
  }

  void _refresh() {
    setState(() {
      _galleryFuture = _loadGallery();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: const Text('Trip Photos'),
        foregroundColor: Colors.white,
        backgroundColor: _galleryBlue,
        actions: [
          IconButton(
            tooltip: 'Add photos',
            onPressed: _uploading ? null : _pickPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
      body: FutureBuilder<TripGalleryResult>(
        future: _galleryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _galleryBlue),
            );
          }
          if (snapshot.hasError) {
            return _GalleryError(
              message: _messageFor(snapshot.error),
              onRetry: _refresh,
            );
          }
          final gallery = snapshot.data!;
          if (gallery.photos.isEmpty) {
            return _EmptyGallery(onAdd: _pickPhotos);
          }
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _galleryFuture;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                    ? 3
                    : 2;
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .88,
                  ),
                  itemCount: gallery.photos.length,
                  itemBuilder: (context, index) => _PhotoCard(
                    photo: gallery.photos[index],
                    canDelete:
                        gallery.isAdmin ||
                        gallery.photos[index].uploadedBy == gallery.viewerUid,
                    onOpen: () => _openPhoto(gallery, gallery.photos[index]),
                    onDownload: () => _download(gallery.photos[index]),
                    onDelete: () => _confirmDelete(gallery.photos[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final tripId = widget.tripId;
    if (tripId == null || _uploading) return;

    late final List<XFile> photos;
    try {
      photos = await _picker.pickMultiImage(
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 88,
      );
    } catch (_) {
      if (mounted) _showMessage('Unable to open the photo picker.');
      return;
    }

    if (photos.isEmpty || !mounted) return;
    setState(() => _uploading = true);

    var uploaded = 0;
    String? failureMessage;
    for (final photo in photos) {
      try {
        final bytes = await photo.readAsBytes();
        await _service.uploadPhoto(
          tripId: tripId,
          bytes: bytes,
          filename: photo.name,
        );
        uploaded++;
      } on TripGalleryException catch (error) {
        failureMessage = error.message;
      } catch (_) {
        failureMessage = 'Unable to upload one or more selected photos.';
      }
    }

    if (!mounted) return;
    setState(() {
      _uploading = false;
      _galleryFuture = _loadGallery();
    });

    final message = uploaded == photos.length
        ? '$uploaded ${uploaded == 1 ? 'photo' : 'photos'} added.'
        : uploaded > 0
        ? '$uploaded added; ${photos.length - uploaded} could not be uploaded.'
        : failureMessage ?? 'Unable to upload the selected photos.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMessage(message);
    });
  }

  Future<void> _download(TripGalleryPhoto photo) async {
    try {
      await _service.downloadPhoto(photo);
    } on TripGalleryException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _confirmDelete(TripGalleryPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
          'This photo will be permanently removed from the trip gallery.',
        ),
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
      await _service.deletePhoto(tripId: widget.tripId!, photo: photo);
      if (!mounted) return;
      _showMessage('Photo deleted.');
      _refresh();
    } on TripGalleryException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _openPhoto(TripGalleryResult gallery, TripGalleryPhoto photo) {
    final canDelete = gallery.isAdmin || photo.uploadedBy == gallery.viewerUid;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .92),
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 5,
                  child: Image.network(
                    photo.secureUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Download',
                      onPressed: () => _download(photo),
                      icon: const Icon(Icons.download_outlined),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Delete',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _confirmDelete(photo);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageFor(Object? error) {
    return error is TripGalleryException
        ? error.message
        : 'Unable to load the trip gallery.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoCard extends StatelessWidget {
  final TripGalleryPhoto photo;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.canDelete,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.secureUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE2E8F0),
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: Material(
                color: Colors.black.withValues(alpha: .48),
                shape: const CircleBorder(),
                child: PopupMenuButton<String>(
                  tooltip: 'Photo actions',
                  color: Colors.white,
                  iconColor: Colors.white,
                  onSelected: (value) =>
                      value == 'download' ? onDownload() : onDelete(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.download_outlined),
                        title: Text('Download'),
                      ),
                    ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text('Delete'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 9,
              child: Text(
                _photoDate(photo.createdAt),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGallery({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GalleryIllustration(),
            const SizedBox(height: 20),
            const Text(
              'No trip photos yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            const Text(
              'Add the first memory for everyone in your trip group.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(backgroundColor: _galleryBlue),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add photos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryIllustration extends StatelessWidget {
  const _GalleryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 176,
            height: 176,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.10,
            child: Container(
              width: 138,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _galleryBlue.withValues(alpha: .15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _LandscapePainter()),
              ),
            ),
          ),
          const Positioned(
            right: 18,
            bottom: 20,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: _galleryBlue,
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          const Positioned(
            left: 20,
            top: 14,
            child: Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 30),
          ),
        ],
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFDBEAFE), BlendMode.src);
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .28),
      13,
      Paint()..color = const Color(0xFFFBBF24),
    );
    final back = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * .64)
      ..lineTo(size.width * .32, size.height * .34)
      ..lineTo(size.width * .62, size.height * .72)
      ..lineTo(size.width, size.height * .44)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF60A5FA));
    final front = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * .78)
      ..lineTo(size.width * .36, size.height * .55)
      ..lineTo(size.width * .66, size.height * .82)
      ..lineTo(size.width, size.height * .64)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GalleryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GalleryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 58, color: _galleryBlue),
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

String _photoDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
