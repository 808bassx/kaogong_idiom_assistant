class WordModel {
  final int id;
  final String word;
  final String pinyin;
  final String meaning;
  final String source;
  final String usage;
  final String example;
  final String synonym;
  final String antonym;
  final String confusable;
  final String memoryTip;
  final List<String> tags;
  final bool isMastered;
  final int reviewCount;
  final int errorCount;
  final bool isFavorite;
  final String notes;
  final String? createdAt;
  final String? updatedAt;
  final String? lastReviewedAt;

  WordModel({
    required this.id,
    required this.word,
    this.pinyin = '',
    this.meaning = '',
    this.source = '',
    this.usage = '',
    this.example = '',
    this.synonym = '',
    this.antonym = '',
    this.confusable = '',
    this.memoryTip = '',
    this.tags = const [],
    this.isMastered = false,
    this.reviewCount = 0,
    this.errorCount = 0,
    this.isFavorite = false,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
    this.lastReviewedAt,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] ?? 0,
      word: json['word'] ?? '',
      pinyin: json['pinyin'] ?? '',
      meaning: json['meaning'] ?? '',
      source: json['source'] ?? '',
      usage: json['usage'] ?? '',
      example: json['example'] ?? '',
      synonym: json['synonym'] ?? '',
      antonym: json['antonym'] ?? '',
      confusable: json['confusable'] ?? '',
      memoryTip: json['memory_tip'] ?? '',
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      isMastered: json['is_mastered'] ?? false,
      reviewCount: json['review_count'] ?? 0,
      errorCount: json['error_count'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      notes: json['notes'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lastReviewedAt: json['last_reviewed_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'pinyin': pinyin,
    'meaning': meaning,
    'source': source,
    'usage': usage,
    'example': example,
    'synonym': synonym,
    'antonym': antonym,
    'confusable': confusable,
    'memory_tip': memoryTip,
    'tags': tags,
    'is_mastered': isMastered,
    'review_count': reviewCount,
    'error_count': errorCount,
    'is_favorite': isFavorite,
    'notes': notes,
  };
}

class WordListResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<WordModel> words;

  WordListResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.words,
  });

  factory WordListResponse.fromJson(Map<String, dynamic> json) {
    return WordListResponse(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      words: (json['words'] as List? ?? [])
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
