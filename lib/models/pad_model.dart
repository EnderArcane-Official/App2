import 'dart:typed_data';

class PadModel {
  final int id;
  String? name;
  Uint8List? audioData;   // ham ses baytları (ulgm kaydetmek için)
  String? mimeType;
  bool isPlaying;
  bool isLoaded;

  PadModel({
    required this.id,
    this.name,
    this.audioData,
    this.mimeType,
    this.isPlaying = false,
    this.isLoaded = false,
  });

  PadModel copyWith({
    String? name,
    Uint8List? audioData,
    String? mimeType,
    bool? isPlaying,
    bool? isLoaded,
  }) {
    return PadModel(
      id: id,
      name: name ?? this.name,
      audioData: audioData ?? this.audioData,
      mimeType: mimeType ?? this.mimeType,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  void clear() {
    name = null;
    audioData = null;
    mimeType = null;
    isPlaying = false;
    isLoaded = false;
  }
}
