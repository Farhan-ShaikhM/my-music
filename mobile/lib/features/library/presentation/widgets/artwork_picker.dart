import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Helper class for artwork selection data if not defined elsewhere
class ArtworkSelection {
  final Uint8List bytes;
  final String mimeType;

  const ArtworkSelection({
    required this.bytes,
    required this.mimeType,
  });
}

class ArtworkPicker extends StatefulWidget {
  final Uint8List? initialArtwork;
  final double size;
  final ValueChanged<ArtworkSelection?> onArtworkChanged;

  const ArtworkPicker({
    super.key,
    this.initialArtwork,
    this.size = 220,
    required this.onArtworkChanged,
  });

  @override
  State<ArtworkPicker> createState() => _ArtworkPickerState();
}

class _ArtworkPickerState extends State<ArtworkPicker> {
  late Uint8List? _artworkBytes;

  final ImagePicker _imagePicker = ImagePicker();

  String _mimeTypeFromPath(String filePath) {
    final lowerPath = filePath.toLowerCase();

    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }

    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lowerPath.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }

  @override
  void initState() {
    super.initState();
    _artworkBytes = widget.initialArtwork;
  }

  Future<void> _pickArtwork() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromPath(image.path);

    if (!mounted) {
      return;
    }

    setState(() {
      _artworkBytes = bytes;
    });

    widget.onArtworkChanged(
      ArtworkSelection(
        bytes: bytes,
        mimeType: mimeType,
      ),
    );
  }

  void _removeArtwork() {
    setState(() {
      _artworkBytes = null;
    });

    widget.onArtworkChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasArtwork =
        _artworkBytes != null && _artworkBytes!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickArtwork,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasArtwork
                ? Image.memory(
                    _artworkBytes!,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.music_note,
                      size: 64,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickArtwork,
              icon: const Icon(Icons.image),
              label: Text(
                hasArtwork
                    ? 'Change Artwork'
                    : 'Add Artwork',
              ),
            ),

            if (hasArtwork) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove artwork',
                onPressed: _removeArtwork,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}