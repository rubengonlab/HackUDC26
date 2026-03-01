enum NoteType { audio, text, image, link, document }

enum CategoryStatus { uncategorized, pending, approved }

/// Estado del procesamiento de texto por la IA.
/// - pending:   en cola / aún no procesado
/// - processed: la IA generó un texto reformulado válido  ← mostrar IA en grande
/// - approved:  el usuario lo aprobó explícitamente
/// - failed:    la IA no pudo procesar                    ← mostrar original en grande
enum TextStatus { pending, processed, approved, failed }

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
  final TextStatus textStatus;

  // Campos de detalle
  final String? reorderedText;
  final String? contentUrl;
  final String? url;
  final String? contextText;

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
    this.textStatus = TextStatus.pending,
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
    String? rawTextStatus;
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
        rawTextStatus = audio?['textStatus'] as String?;
        break;
      case 'IMAGE':
        type = NoteType.image;
        final image = json['image'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            image?['originalFileName'] as String? ?? 'Imagen';
        preview = json['contextText'] as String?;
        final imageId = image?['id'];
        contentUrl = imageId != null ? '/image/$imageId/content' : null;
        rawTextStatus = image?['textStatus'] as String?;
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
        rawTextStatus = doc?['textStatus'] as String?;
        break;
      default: // NOTE
        type = NoteType.text;
        final note = json['note'] as Map<String, dynamic>?;
        title = json['title'] as String? ??
            (note?['content'] as String? ?? '').split('\n').first;
        if (title.isEmpty) title = 'Nota';
        preview = note?['content'] as String?;
        reorderedText = note?['reorderedText'] as String?;
        rawTextStatus = note?['textStatus'] as String?;
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
      textStatus: _parseTextStatus(rawTextStatus),
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

  static TextStatus _parseTextStatus(String? s) {
    switch (s) {
      case 'PROCESSED': return TextStatus.processed;
      case 'APPROVED':  return TextStatus.approved;
      case 'FAILED':    return TextStatus.failed;
      default:          return TextStatus.pending;
    }
  }
}
