import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../player/presentation/widgets/mini_player.dart';
import '../models/song.dart';
import '../providers/library_providers.dart';
import 'widgets/song_options_sheet.dart';
import 'widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(libraryIndexProvider).value;
    final results = index?.search(_query) ?? const <Song>[];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Songs, artists, albums',
            filled: true,
            fillColor: AppColors.card,
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: Stack(
        children: [
          if (_query.trim().isNotEmpty && results.isEmpty)
            const Center(
              child: Text(
                'No matches',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 110, top: 8),
              itemCount: results.length,
              itemBuilder: (context, i) => SongTile(
                song: results[i],
                onTap: () {
                  FocusScope.of(context).unfocus();
                  playFromList(context, ref, results, i);
                },
              ),
            ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: MiniPlayer()),
          ),
        ],
      ),
    );
  }
}
