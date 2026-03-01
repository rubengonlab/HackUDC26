enum NoteType { audio, text, image, link, document }

enum CategoryStatus { uncategorized, pending, approved }

class Note {
  final String id;
  final String title;
  final String? preview;
  final NoteType type;
  final String? categoryId;
  final String? categoryName;
  final DateTime createdAt;
  final int? durationSeconds;
  final CategoryStatus categoryStatus;

  // Campos de detalle
  final String? reorderedText;  // texto reformulado por IA (NOTE, AUDIO)
  final String? contentUrl;     // URL para obtener binario (IMAGE, AUDIO)
  final String? url;            // para LINK
  final String? contextText;    // contexto opcional

  Note({
    required this.id,
    required this.title,
    this.preview,
    required this.type,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    this.durationSeconds,
    this.categoryStatus = CategoryStatus.uncategorized,
    this.reorderedText,
    this.contentUrl,
    this.url,
    this.contextText,
  });

  static String typeLabel(NoteType type) {
    switch (type) {
      case NoteType.audio:    return 'Audio';
      case NoteType.text:     return 'Texto';
      case NoteType.image:    return 'Imagen';
      case NoteType.link:     return 'Enlace';
      case NoteType.document: return 'Documento';
    }
  }

  static String typeEmoji(NoteType type) {
    switch (type) {
      case NoteType.audio:    return '🎙️';
      case NoteType.text:     return '📝';
      case NoteType.image:    return '🖼️';
      case NoteType.link:     return '🔗';
      case NoteType.document: return '📄';
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
    String? reorderedText;
    String? contentUrl;
    String? url;
    final String? contextText = json['contextText'] as String?;
    final String? categoryName = json['categoryName'] as String?;

    switch (captureType) {
      case 'AUDIO':
        type = NoteType.audio;
        final audio = json['audio'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            audio?['originalFileName'] as String? ?? 'Audio';
        preview = audio?['parsedText'] as String?;
        reorderedText = audio?['reorderedParsedText'] as String?;
        contentUrl = audio?['contentUrl'] as String?;
        break;
      case 'IMAGE':
        type = NoteType.image;
        final image = json['image'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            image?['originalFileName'] as String? ?? 'Imagen';
        preview = json['contextText'] as String?;
        // El backend no incluye contentUrl en FileDataDto, construimos con id
        final imageId = image?['id'];
        contentUrl = imageId != null ? '/image/$imageId/content' : null;
        break;
      case 'LINK':
        type = NoteType.link;
        final link = json['link'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            link?['url'] as String? ?? json['origin'] as String? ?? 'Enlace';
        url = link?['url'] as String?;
        preview = url;
        break;
      case 'DOCUMENT':
        type = NoteType.document;
        final doc = json['document'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            doc?['originalFileName'] as String? ?? 'Documento';
        preview = doc?['parsedText'] as String?;
        reorderedText = doc?['reorderedParsedText'] as String?;
        contentUrl = doc?['contentUrl'] as String?;
        break;
      default: // NOTE
        type = NoteType.text;
        final note = json['note'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            (note?['content'] as String? ?? '').split('\n').first;
        if (title.isEmpty) title = 'Nota';
        preview = note?['content'] as String?;
        reorderedText = note?['reorderedText'] as String?;
    }

    return Note(
      id: 'cap_${json['id']}',
      title: title,
      preview: preview,
      type: type,
      categoryId: json['categoryId']?.toString(),
      categoryName: categoryName,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      categoryStatus: _parseStatus(json['categoryStatus']),
      reorderedText: reorderedText,
      contentUrl: contentUrl,
      url: url,
      contextText: contextText,
    );
  }

  static CategoryStatus _parseStatus(String? s) {
    switch (s) {
      case 'PENDING':   return CategoryStatus.pending;
      case 'APPROVED':  return CategoryStatus.approved;
      default:          return CategoryStatus.uncategorized;
    }
  }
}
