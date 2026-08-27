import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/import_song_draft.dart';
import '../presentation/widgets/artwork_picker.dart';
import '../providers/library_data_providers.dart';
import '../providers/library_providers.dart';

class ImportSongReviewScreen extends ConsumerStatefulWidget {
  final ImportSongDraft draft;

  const ImportSongReviewScreen({super.key, required this.draft});

  @override
  ConsumerState<ImportSongReviewScreen> createState() =>
      _ImportSongReviewScreenState();
}

class _ImportSongReviewScreenState
    extends ConsumerState<ImportSongReviewScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _albumController;

  Uint8List? _artworkBytes;

  // Manage multiple artist names dynamically for review and modification
  late List<String> _artistNames;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.draft.title);
    _albumController = TextEditingController(
      text: widget.draft.albumName ?? '',
    );

    _artworkBytes = widget.draft.artworkBytes;
    _artistNames = List.from(widget.draft.artistNames);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Song')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ArtworkPicker(
              initialArtwork: _artworkBytes,
              onArtworkChanged: (selection) {
                setState(() {
                  _artworkBytes = selection?.bytes;
                  widget.draft.artworkMimeType = selection?.mimeType;
                });
              },
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            _buildArtistSection(),

            const SizedBox(height: 16),

            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Album',
                hintText: 'Enter album name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _reviewImport,
              icon: const Icon(Icons.library_add),
              label: const Text('Import Song'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Artists',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            for (int i = 0; i < _artistNames.length; i++)
              Chip(
                label: Text(_artistNames[i]),
                onDeleted: () {
                  setState(() {
                    _artistNames.removeAt(i);
                  });
                },
              ),
            if (_artistNames.isEmpty)
              const Text(
                'No artists assigned (will show as Unknown artist)',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddArtistDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Artist'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddArtistDialog() async {
    String typedName = '';
    String? selectedExistingId;
    bool useExisting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final artistsAsync = ref.watch(libraryArtistsProvider);

            return AlertDialog(
              title: const Text('Add Artist'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Type New'),
                        icon: Icon(Icons.edit),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Existing'),
                        icon: Icon(Icons.person),
                      ),
                    ],
                    selected: {useExisting},
                    onSelectionChanged: (selection) {
                      setDialogState(() {
                        useExisting = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!useExisting)
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Artist name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        typedName = value;
                      },
                    )
                  else
                    artistsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading artists: $err'),
                      data: (artists) {
                        if (artists.isEmpty) {
                          return const Text('No existing artists available.');
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: selectedExistingId,
                          decoration: const InputDecoration(
                            labelText: 'Select artist',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final artist in artists)
                              DropdownMenuItem<String>(
                                value: artist.id,
                                child: Text(artist.name),
                              ),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedExistingId = val;
                              if (val != null) {
                                final found = artists.firstWhere(
                                  (a) => a.id == val,
                                );
                                typedName = found.name;
                              }
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (typedName.trim().isNotEmpty) {
                      setState(() {
                        if (!_artistNames.contains(typedName.trim())) {
                          _artistNames.add(typedName.trim());
                        }
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reviewImport() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song title cannot be empty.')),
      );
      return;
    }

    final album = _albumController.text.trim();

    widget.draft.title = title;
    widget.draft.artistNames = _artistNames;
    widget.draft.albumName = album.isEmpty ? null : album;
    widget.draft.artworkBytes = _artworkBytes;

    try {
      final importService = ref.read(musicImportServiceProvider);

      await importService.importDraft(widget.draft);

      if (!mounted) return;

      Navigator.pop(context, widget.draft);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import song: $error')));
    }
  }
}
