class NoteModel {
  final int id;
  final String title;
  final String contentText;
  final List<dynamic> drawingData;

  const NoteModel({
    required this.id,
    required this.title,
    required this.contentText,
    required this.drawingData,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawDrawing = json['drawing_data'];
    return NoteModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      contentText: json['content_text'] ?? '',
      drawingData: rawDrawing is List ? rawDrawing : <dynamic>[],
    );
  }
}