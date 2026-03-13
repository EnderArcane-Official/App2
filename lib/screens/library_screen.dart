import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../services/supabase_service.dart';
import '../theme.dart';

// Kategori listesi — web versiyonuyla aynı
const _categories = [
  ('all', '🎵 All'),
  ('royalty-free', '✅ Royalty-Free'),
  ('attribution', '🏷️ Attribution'),
  ('copyrighted', '🔒 Copyrighted'),
  ('electronic', '⚡ Electronic'),
  ('rock', '🎸 Rock'),
  ('hiphop', '🎤 Hip-Hop'),
  ('lofi', '☕ Lo-Fi'),
  ('jazz', '🎷 Jazz'),
  ('pop', '🌟 Pop'),
];

class LoopItem {
  final String id;
  final String name;
  final String author;
  final List<String> tags;
  final String category;
  final String coverEmoji;

  const LoopItem({
    required this.id, required this.name, required this.author,
    required this.tags, required this.category, required this.coverEmoji,
  });

  factory LoopItem.fromMap(Map<String, dynamic> m) => LoopItem(
    id: m['id'] ?? '',
    name: m['name'] ?? 'Untitled Loop',
    author: m['uploader_id'] ?? 'Unknown',
    tags: List<String>.from(m['tags'] ?? []),
    category: m['category'] ?? 'other',
    coverEmoji: m['cover_emoji'] ?? '🎵',
  );
}

class LibraryScreen extends StatefulWidget {
  /// Pad'lere ses yüklemek için callback — pad_screen ile entegrasyon
  final Function(int padIndex, Uint8List data, String name, String mime)? onLoadToPad;

  const LibraryScreen({super.key, this.onLoadToPad});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LoopItem> _all = [];
  List<LoopItem> _filtered = [];
  String _activeCategory = 'all';
  String _search = '';
  bool _loading = false;
  bool _loaded = false;
  String _error = '';
  String? _loadingLoopId; // hangi loop yükleniyor

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Supabase'den loop listesini çek — web versiyonuyla aynı sorgu
  Future<void> _loadLibrary() async {
    if (_loaded) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await SupabaseService.client
          .from('library')
          .select('*')
          .order('created_at', ascending: false);

      _all = (res as List).map((m) => LoopItem.fromMap(m)).toList();
      _loaded = true;
      _applyFilter();
    } catch (e) {
      setState(() => _error = '❌ Could not load library.\n$e');
    }
    setState(() => _loading = false);
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((loop) {
        final matchCat = _activeCategory == 'all' ||
            loop.category == _activeCategory ||
            loop.tags.contains(_activeCategory);
        final matchSearch = _search.isEmpty ||
            loop.name.toLowerCase().contains(_search) ||
            loop.author.toLowerCase().contains(_search);
        return matchCat && matchSearch;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    _activeCategory = cat;
    _applyFilter();
  }

  void _onSearch(String val) {
    _search = val.toLowerCase();
    _applyFilter();
  }

  // Supabase Storage'dan loop dosyalarını indir ve pad'e yükle
  Future<void> _loadLoop(LoopItem loop) async {
    setState(() => _loadingLoopId = loop.id);
    try {
      // manifest.json oku
      final manifestUrl = SupabaseService.client.storage
          .from('library')
          .getPublicUrl('${loop.id}/manifest.json');

      final manifestRes = await http.get(Uri.parse(manifestUrl));
      if (manifestRes.statusCode != 200) throw Exception('manifest.json not found');
      final manifest = jsonDecode(manifestRes.body) as Map<String, dynamic>;
      final pads = manifest['pads'] as Map<String, dynamic>?;
      if (pads == null) throw Exception('Invalid manifest');

      // Pad dosyalarını indir
      final downloads = <int, Future<MapEntry<Uint8List, String>>>{};
      for (int i = 0; i < 16; i++) {
        final key = '${i + 1}';
        final fileName = pads[key] as String?;
        if (fileName == null) continue;

        final audioUrl = SupabaseService.client.storage
            .from('library')
            .getPublicUrl('${loop.id}/$fileName');

        final idx = i;
        downloads[idx] = http.get(Uri.parse(audioUrl)).then((r) {
          final mime = fileName.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';
          final name = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
          return MapEntry(r.bodyBytes, name);
        });
      }

      final results = await Future.wait(
        downloads.entries.map((e) async => MapEntry(e.key, await e.value)),
      );

      // Callback ile pad_screen'e gönder
      if (widget.onLoadToPad != null) {
        for (final r in results) {
          final mime = r.value.value.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';
          widget.onLoadToPad!(r.key, r.value.key, r.value.value, mime);
        }
      }

      _showToast('✅ Loop loaded! Go to Pad.');
    } catch (e) {
      _showToast('❌ Error: $e');
    }
    setState(() => _loadingLoopId = null);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppTheme.textColor)),
      backgroundColor: AppTheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.accent),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + kategori header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              // Arama kutusu
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '🔍 Search loops...',
                  hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accent)),
                ),
              ),
              const SizedBox(height: 10),

              // Kategori butonları — yatay scroll
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (key, label) = _categories[i];
                    final active = _activeCategory == key;
                    return GestureDetector(
                      onTap: () => _selectCategory(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.accent : AppTheme.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppTheme.accent : AppTheme.border),
                        ),
                        child: Text(label, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.muted,
                        )),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // İçerik
        Expanded(
          child: _loading
              ? const Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    SizedBox(height: 12),
                    Text('⏳ Loading library...', style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                  ],
                ))
              : _error.isNotEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.danger, fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                          onPressed: () { _loaded = false; _loadLibrary(); },
                          child: const Text('Retry'),
                        ),
                      ],
                    ))
                  : _filtered.isEmpty
                      ? const Center(child: Text('🎵 No loops found.', style: TextStyle(color: AppTheme.muted, fontSize: 14)))
                      : RefreshIndicator(
                          color: AppTheme.accent,
                          backgroundColor: AppTheme.surface,
                          onRefresh: () async { _loaded = false; await _loadLibrary(); },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _LoopCard(
                              loop: _filtered[i],
                              isLoading: _loadingLoopId == _filtered[i].id,
                              onLoad: () => _loadLoop(_filtered[i]),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── LOOP KART ──
class _LoopCard extends StatelessWidget {
  final LoopItem loop;
  final bool isLoading;
  final VoidCallback onLoad;

  const _LoopCard({required this.loop, required this.isLoading, required this.onLoad});

  Color _tagColor(String tag) {
    if (tag == 'royalty-free') return const Color(0xFF22C55E);
    if (tag == 'attribution') return const Color(0xFFFBBF24);
    if (tag == 'copyrighted') return AppTheme.danger;
    return AppTheme.accent3;
  }

  Color _tagBg(String tag) {
    if (tag == 'royalty-free') return const Color(0xFF22C55E).withOpacity(0.15);
    if (tag == 'attribution') return const Color(0xFFFBBF24).withOpacity(0.15);
    if (tag == 'copyrighted') return AppTheme.danger.withOpacity(0.15);
    return AppTheme.accent.withOpacity(0.15);
  }

  String _tagLabel(String tag) {
    if (tag == 'royalty-free') return '✅ Royalty-Free';
    if (tag == 'attribution') return '🏷️ Attribution';
    if (tag == 'copyrighted') return '🔒 Copyrighted';
    return '#$tag';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Cover emoji
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.accent, AppTheme.accent2]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(loop.coverEmoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loop.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                const SizedBox(height: 2),
                Text('by @${loop.author}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                if (loop.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: loop.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _tagBg(t), borderRadius: BorderRadius.circular(10)),
                      child: Text(_tagLabel(t), style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: _tagColor(t))),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Load butonu
          isLoading
              ? const SizedBox(width: 48, height: 32, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))))
              : ElevatedButton(
                  onPressed: onLoad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Load', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }
}
