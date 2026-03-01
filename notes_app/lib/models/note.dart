enum NoteType { audio, text, image, link }

enum CategoryStatus { uncategorized, pending, approved }

class Note {
  final String id;
  final String title;
  final String? preview;
  final NoteType type;
  final String? categoryId;   // null = sin categoría
  final DateTime createdAt;
  final int? durationSeconds; // solo audio
  final CategoryStatus categoryStatus;

  Note({
    required this.id,
    required this.title,
    this.preview,
    required this.type,
    this.categoryId,
    required this.createdAt,
    this.durationSeconds,
    this.categoryStatus = CategoryStatus.uncategorized,
  });

  static String typeLabel(NoteType type) {
    switch (type) {
      case NoteType.audio:
        return 'Audio';
      case NoteType.text:
        return 'Texto';
      case NoteType.image:
        return 'Imagen';
      case NoteType.link:
        return 'Enlace';
    }
  }

  static String typeEmoji(NoteType type) {
    switch (type) {
      case NoteType.audio:
        return '🎙️';
      case NoteType.text:
        return '📝';
      case NoteType.image:
        return '🖼️';
      case NoteType.link:
        return '🔗';
    }
  }

  /// Construye un Note desde la respuesta de GET /audio (AudioDto + captureId implícito)
  factory Note.fromAudioJson(Map<String, dynamic> json) {
    return Note(
      id: 'audio_${json['id']}',
      title: json['originalFileName'] ?? json['fileName'] ?? 'Audio',
      preview: null,
      type: NoteType.audio,
      categoryId: null, // el AudioDto no trae categoryId directamente
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      categoryStatus: CategoryStatus.uncategorized,
    );
  }

  /// Construye un Note desde la respuesta de GET /text (TextResourceDto)
  factory Note.fromTextJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String? ?? 'NOTE';
    final NoteType type = kind == 'LINK' ? NoteType.link : NoteType.text;

    return Note(
      id: '${kind.toLowerCase()}_${json['id']}',
      title: json['title'] ?? json['url'] ?? json['origin'] ?? 'Nota',
      preview: kind == 'LINK' ? json['url'] : json['content'],
      type: type,
      categoryId: json['categoryId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      categoryStatus: _parseStatus(json['categoryStatus']),
    );
  }

  /// Construye un Note desde CaptureDto (GET /captures)
  factory Note.fromCaptureJson(Map<String, dynamic> json) {
    final captureType = (json['captureType'] as String? ?? 'NOTE').toUpperCase();
    final NoteType type;
    String title;
    String? preview;

    switch (captureType) {
      case 'AUDIO':
        type = NoteType.audio;
        final audio = json['audio'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            audio?['originalFileName'] as String? ??
            'Audio';
        preview = audio?['parsedText'] as String?;
        break;
      case 'IMAGE':
        type = NoteType.image;
        final image = json['image'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            image?['originalFileName'] as String? ??
            'Imagen';
        preview = json['contextText'] as String?;
        break;
      case 'LINK':
        type = NoteType.link;
        final link = json['link'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            link?['url'] as String? ??
            json['origin'] as String? ??
            'Enlace';
        preview = link?['url'] as String?;
        break;
      case 'DOCUMENT':
        type = NoteType.image; // reuse image icon for now
        final doc = json['document'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            doc?['originalFileName'] as String? ??
            'Documento';
        preview = json['contextText'] as String?;
        break;
      default: // NOTE
        type = NoteType.text;
        final note = json['note'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            (note?['content'] as String? ?? '').split('\n').first;
        if (title.isEmpty) title = 'Nota';
        preview = note?['content'] as String?;
    }

    return Note(
      id: 'cap_${json['id']}',
      title: title,
      preview: preview,
      type: type,
      categoryId: json['categoryId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      categoryStatus: _parseStatus(json['categoryStatus']),
    );
  }

  static CategoryStatus _parseStatus(String? s) {
    switch (s) {
      case 'PENDING':
        return CategoryStatus.pending;
      case 'APPROVED':
        return CategoryStatus.approved;
      default:
        return CategoryStatus.uncategorized;
    }
  }
}
