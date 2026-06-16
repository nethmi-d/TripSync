import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoPicker extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;
  final VoidCallback? onPick;
  final String actionLabel;

  const ProfilePhotoPicker({
    super.key,
    required this.selectedPhoto,
    required this.existingPhotoUrl,
    required this.onPick,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _PhotoPreview(
                selectedPhoto: selectedPhoto,
                existingPhotoUrl: existingPhotoUrl,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: const Color(0xFF2563EB),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onPick,
                    tooltip: actionLabel,
                    icon: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onPick, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final XFile? selectedPhoto;
  final String? existingPhotoUrl;

  const _PhotoPreview({
    required this.selectedPhoto,
    required this.existingPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final photo = selectedPhoto;
    if (photo != null) {
      return FutureBuilder<Uint8List>(
        future: photo.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _avatar(MemoryImage(snapshot.data!));
          }
          return _avatar(null, isLoading: true);
        },
      );
    }

    final url = existingPhotoUrl;
    return _avatar(url == null ? null : NetworkImage(url));
  }

  Widget _avatar(ImageProvider<Object>? image, {bool isLoading = false}) {
    return CircleAvatar(
      radius: 46,
      backgroundColor: const Color(0xFFEFF6FF),
      backgroundImage: image,
      child: image == null
          ? isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    size: 48,
                    color: Color(0xFF3B82F6),
                  )
          : null,
    );
  }
}
