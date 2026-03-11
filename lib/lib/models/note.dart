import 'dart:convert';

class Note {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;
  Duration? recordingDuration;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.recordingDuration,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    Duration? recordingDuration,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recordingDurationMs': recordingDuration?.inMilliseconds,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      recordingDuration: json['recordingDurationMs'] != null
          ? Duration(milliseconds: json['recordingDurationMs'])
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Note.fromJsonString(String jsonString) =>
      Note.fromJson(jsonDecode(jsonString));

  /// Auto-generate a title from first few words of content
  static String generateTitle(String content) {
    if (content.isEmpty) return 'Untitled Note';
    final words = content.trim().split(' ');
    final titleWords = words.take(5).join(' ');
    return titleWords.length > 40
        ? '${titleWords.substring(0, 40)}...'
        : titleWords;
  }
}
