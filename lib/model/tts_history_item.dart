import 'dart:convert';

class TtsHistoryItem {
  final String id;
  final String text;
  final String? filePath; // null if file synth isn’t supported
  final String voiceId;
  final double rate;
  final double pitch;
  final DateTime createdAt;

  TtsHistoryItem({
    required this.id,
    required this.text,
    required this.filePath,
    required this.voiceId,
    required this.rate,
    required this.pitch,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'filePath': filePath,
    'voiceId': voiceId,
    'rate': rate,
    'pitch': pitch,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TtsHistoryItem.fromMap(Map<String, dynamic> map) => TtsHistoryItem(
    id: map['id'] as String,
    text: map['text'] as String,
    filePath: map['filePath'] as String?,
    voiceId: map['voiceId'] as String,
    rate: (map['rate'] as num).toDouble(),
    pitch: (map['pitch'] as num).toDouble(),
    createdAt: DateTime.parse(map['createdAt'] as String),
  );

  String toJson() => jsonEncode(toMap());
  factory TtsHistoryItem.fromJson(String s) => TtsHistoryItem.fromMap(jsonDecode(s));
}
