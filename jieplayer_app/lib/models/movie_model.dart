class MovieCategory {
  final String typeId;
  final String typeName;
  
  MovieCategory({
    required this.typeId,
    required this.typeName,
  });
  
  factory MovieCategory.fromJson(Map<String, dynamic> json) {
    return MovieCategory(
      typeId: json['type_id']?.toString() ?? '',
      typeName: json['type_name']?.toString() ?? '',
    );
  }
}

class Movie {
  final String vodId;
  final String vodName;
  final String vodPic;
  final String vodContent;
  final String vodScore;
  final String typeName;
  final String vodClass;
  final String vodDuration;
  final String vodYear;
  final String vodArea;
  final String vodLang;
  final String vodActor;
  final String vodRemarks;
  final String vodPlayUrl;
  final String typeId;
  
  Movie({
    required this.vodId,
    required this.vodName,
    required this.vodPic,
    required this.vodContent,
    required this.vodScore,
    required this.typeName,
    required this.vodClass,
    required this.vodDuration,
    required this.vodYear,
    required this.vodArea,
    required this.vodLang,
    required this.vodActor,
    required this.vodRemarks,
    required this.vodPlayUrl,
    required this.typeId,
  });
  
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      vodId: json['vod_id']?.toString() ?? '',
      vodName: json['vod_name']?.toString() ?? '',
      vodPic: json['vod_pic']?.toString() ?? '',
      vodContent: json['vod_content']?.toString() ?? '',
      vodScore: json['vod_score']?.toString() ?? '',
      typeName: json['type_name']?.toString() ?? '',
      vodClass: json['vod_class']?.toString() ?? '',
      vodDuration: json['vod_duration']?.toString() ?? '',
      vodYear: json['vod_year']?.toString() ?? '',
      vodArea: json['vod_area']?.toString() ?? '',
      vodLang: json['vod_lang']?.toString() ?? '',
      vodActor: json['vod_actor']?.toString() ?? '',
      vodRemarks: json['vod_remarks']?.toString() ?? '',
      vodPlayUrl: json['vod_play_url']?.toString() ?? '',
      typeId: json['type_id']?.toString() ?? '',
    );
  }
  
  // 获取播放列表
  List<PlayItem> get playList {
    if (vodPlayUrl.isEmpty) return [];
    
    return vodPlayUrl.split('#').map((item) {
      final parts = item.split(r'$');
      return PlayItem(
        title: parts.isNotEmpty ? parts[0] : '未知',
        url: parts.length > 1 ? parts[1] : '',
      );
    }).where((item) => item.url.isNotEmpty).toList();
  }
}

class PlayItem {
  final String title;
  final String url;
  
  PlayItem({
    required this.title,
    required this.url,
  });
}