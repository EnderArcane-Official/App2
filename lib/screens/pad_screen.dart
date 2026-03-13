import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/pad_model.dart';
import '../theme.dart';

class PadScreen extends StatefulWidget {
  const PadScreen({super.key});

  @override
  State<PadScreen> createState() => _PadScreenState();
}

class _PadScreenState extends State<PadScreen> {
  // 16 pad — web versiyonuyla aynı
  final List<PadModel> _pads = List.generate(16, (i) => PadModel(id: i));
  final List<AudioPlayer> _players = List.generate(16, (_) => AudioPlayer());

  // Timer — web: 3:00 = 180 sn
  int _secsLeft = 180;
  bool _timerOn = false;
  Timer? _timerIv;

  // Kayıt — web'deki recState mantığı
  bool _isRecording = false;

  @override
  void dispose() {
    _timerIv?.cancel();
    for (final player in _players) {
      player.dispose();
    }
    super.dispose();
  }

  // ── TIMER ──
  void _startTimer() {
    if (_timerOn) return;
    _timerOn = true;
    _timerIv = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secsLeft--;
        if (_secsLeft <= 0) {
          _stopAllPads();
          _resetTimer();
        }
      });
    });
  }

  void _stopTimer() {
    _timerOn = false;
    _timerIv?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _secsLeft = 180);
  }

  String get _timerText {
    final m = _secsLeft ~/ 60;
    final s = _secsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get _anyPlaying => _pads.any((p) => p.isPlaying);

  // ── PAD MANTIĞI ──
  void _padTap(int i) {
    if (!_pads[i].isLoaded) {
      _openFilePicker(i);
    } else {
      _togglePad(i);
    }
  }

  void _togglePad(int i) {
    if (_pads[i].isPlaying) {
      _stopPad(i);
    } else {
      _playPad(i);
    }
  }

  Future<void> _playPad(int i) async {
    if (!_pads[i].isLoaded || _pads[i].audioData == null) return;
    try {
      // Ses verisini geçici dosyaya yaz (just_audio için)
      final tmp = await getTemporaryDirectory();
      final ext = _pads[i].mimeType == 'audio/wav' ? 'wav' : 'mp3';
      final file = File(p.join(tmp.path, 'pad_$i.$ext'));
      await file.writeAsBytes(_pads[i].audioData!);

      await _players[i].setFilePath(file.path);
      await _players[i].setLoopMode(LoopMode.one);
      await _players[i].play();

      setState(() => _pads[i].isPlaying = true);
      if (!_timerOn) _startTimer();
    } catch (e) {
      _showToast('❌ Playback error: $e');
    }
  }

  Future<void> _stopPad(int i) async {
    await _players[i].stop();
    setState(() => _pads[i].isPlaying = false);
  }

  Future<void> _stopAllPads() async {
    for (int i = 0; i < 16; i++) {
      if (_pads[i].isPlaying) await _stopPad(i);
    }
    _stopTimer();
  }

  void _clearPad(int i) {
    _stopPad(i).then((_) {
      setState(() => _pads[i].clear());
    });
  }

  void _clearAllPads() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear all pads?', style: TextStyle(color: AppTheme.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopAllPads().then((_) {
                setState(() {
                  for (final pad in _pads) pad.clear();
                });
              });
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  // ── DOSYA SEÇ ──
  Future<void> _openFilePicker(int padIndex) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );
    if (result == null) return;

    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final name = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    final mime = file.extension == 'wav' ? 'audio/wav' : 'audio/mpeg';

    setState(() {
      _pads[padIndex].name = name.length > 14 ? name.substring(0, 14) : name;
      _pads[padIndex].audioData = bytes;
      _pads[padIndex].mimeType = mime;
      _pads[padIndex].isLoaded = true;
    });

    // Yükleyince otomatik çal (web versiyonuyla aynı)
    await _playPad(padIndex);
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    final loaded = _pads.where((p) => p.isLoaded).length;
    final playing = _pads.where((p) => p.isPlaying).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Header: timer + title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PAD SCREEN',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.muted,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _anyPlaying ? AppTheme.danger : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    _timerText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _anyPlaying ? AppTheme.danger : AppTheme.accent2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 4x4 Pad grid
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 16,
                itemBuilder: (_, i) => _PadWidget(
                  pad: _pads[i],
                  onTap: () => _padTap(i),
                  onLongPress: _pads[i].isLoaded ? () => _clearPad(i) : null,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Stats satırı
            Row(
              children: [
                _StatChip(label: 'Loaded', value: '$loaded'),
                const SizedBox(width: 10),
                _StatChip(label: 'Playing', value: '$playing'),
                const Spacer(),
                const _StatChip(label: 'Max', value: '3:00'),
              ],
            ),

            const SizedBox(height: 10),

            // Kayıt satırı
            _RecordRow(
              isRecording: _isRecording,
              onRecord: () => setState(() => _isRecording = !_isRecording),
            ),

            const SizedBox(height: 10),

            // Kontrol butonları
            Row(
              children: [
                Expanded(
                  child: _CtrlButton(
                    icon: '📁',
                    label: 'File',
                    onTap: () => _showFileSheet(),
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CtrlButton(
                    icon: '⏹',
                    label: 'Stop All',
                    onTap: _stopAllPads,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CtrlButton(
                    icon: '🗑',
                    label: 'Clear',
                    onTap: _clearAllPads,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FileSheet(
        onSaveUlgm: () {
          Navigator.pop(context);
          _showToast('📦 .ulgm export yakında!');
        },
        onLoadUlgm: () {
          Navigator.pop(context);
          _showToast('📂 .ulgm import yakında!');
        },
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.accent),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── PAD WİDGET ──
class _PadWidget extends StatelessWidget {
  final PadModel pad;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PadWidget({
    required this.pad,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppTheme.surface2;
    Color borderColor = AppTheme.border;

    if (pad.isPlaying) {
      bgColor = AppTheme.accent;
      borderColor = AppTheme.accent2;
    } else if (pad.isLoaded) {
      borderColor = AppTheme.accent.withOpacity(0.4);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: pad.isPlaying
              ? [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 20)]
              : null,
        ),
        child: Stack(
          children: [
            // Pad numarası (sol üst)
            Positioned(
              top: 6,
              left: 8,
              child: Text(
                '${pad.id + 1}',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: pad.isPlaying ? Colors.white60 : AppTheme.muted,
                ),
              ),
            ),
            // Orta içerik
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pad.isLoaded ? '🎵' : '➕',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pad.name ?? 'Empty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: pad.isPlaying ? Colors.white70 : AppTheme.muted,
                    ),
                  ),
                  if (!pad.isLoaded)
                    Text(
                      'tap & load',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppTheme.muted.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STAT CHİP ──
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.accent2,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.muted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── KAYIT SATIRI ──
class _RecordRow extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onRecord;
  const _RecordRow({required this.isRecording, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CtrlButton(
            icon: isRecording ? '⏸' : '⏺',
            label: isRecording ? 'Pause' : 'Record',
            onTap: onRecord,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CtrlButton(
            icon: '💾',
            label: 'Save Rec',
            onTap: () {},
            highlight: isRecording,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Text(
            '00:00',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CTRL BUTON ──
class _CtrlButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FILE SHEET ──
class _FileSheet extends StatelessWidget {
  final VoidCallback onSaveUlgm;
  final VoidCallback onLoadUlgm;
  const _FileSheet({required this.onSaveUlgm, required this.onLoadUlgm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'File Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor,
                ),
              ),
            ),
          ),
          const Divider(color: AppTheme.border),
          _SheetOption(
            icon: '📦',
            title: 'Save as .ulgm',
            sub: 'Export your loop pack',
            onTap: onSaveUlgm,
          ),
          _SheetOption(
            icon: '📂',
            title: 'Load .ulgm / .ulbm',
            sub: 'Import a loop pack',
            onTap: onLoadUlgm,
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _SheetOption({
    required this.icon, required this.title,
    required this.sub, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor,
                )),
                Text(sub, style: const TextStyle(
                  fontSize: 12, color: AppTheme.muted,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
