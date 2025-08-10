import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'movie_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<_VideoItem> _videos = [];
  bool _loading = true;
  bool _allLoaded = false;
  int? _pageCount;
  int _currentPg = 1;
  Timer? _timer;

  final Map<int, VideoPlayerController> _preCache = {};

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _preCache.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadPage() async {
    final url =
        'https://api.yzzy-api.com/inc/api_mac10.php?ac=detail&h=24${_currentPg == 1 ? '' : '&pg=$_currentPg'}';
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    final List list = data['list'] ?? [];

    if (_currentPg == 1) {
      _pageCount = data['pagecount'] as int;
    }

    final batch = <_VideoItem>[];
    final rand = Random();
    for (var item in list) {
      final playUrls = (item['vod_play_url'] as String).split('\$');
      if (playUrls.length >= 2) {
        batch.add(_VideoItem(
          vodId: item['vod_id'],
          name: item['vod_name'],
          desc: item['vod_content'],
          cover: item['vod_pic'],
          url: playUrls[1],
          raw: item,
          episode: 1,
        ));
      }
    }
    batch.shuffle(rand);

    setState(() {
      _loading = false;
      _videos.addAll(batch);
    });

    if (_currentPg < _pageCount!) {
      _currentPg++;
      _timer = Timer(const Duration(seconds: 5), _loadPage);
    } else {
      setState(() => _allLoaded = true);
    }
  }

  Future<void> _preload(int index) async {
    if (_videos.isEmpty) return;
    final indices = {index, index + 1}
        .where((i) => i >= 0 && i < _videos.length)
        .toSet();

    await Future.wait(indices.map((i) async {
      if (_preCache.containsKey(i)) return;
      final vc = VideoPlayerController.networkUrl(Uri.parse(_videos[i].url));
      await vc.initialize();
      _preCache[i] = vc;
    }));
  }

  void _evict(int currentIndex) {
    final keep = {currentIndex - 1, currentIndex, currentIndex + 1};
    final keys = _preCache.keys.toList();
    for (final k in keys) {
      if (!keep.contains(k)) {
        _preCache[k]?.dispose();
        _preCache.remove(k);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _videos.length + (_allLoaded ? 1 : 0),
      onPageChanged: (index) {
        if (index < _videos.length) {
          _preload(index);
          _evict(index);
        }
      },
      itemBuilder: (context, index) {
        if (index == _videos.length) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '24H 内更新已浏览完',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        }
        final video = _videos[index];
        return _VideoPage(
          key: ValueKey(video.url),
          video: video,
          preCachedController: _preCache[index],
        );
      },
    );
  }
}

/* ------------------------------------------------------ */
/* 数据模型                                                */
/* ------------------------------------------------------ */
class _VideoItem {
  final String vodId;
  final String name;
  final String desc;
  final String cover;
  final String url;
  final Map<String, dynamic> raw;
  final int episode;

  _VideoItem({
    required this.vodId,
    required this.name,
    required this.desc,
    required this.cover,
    required this.url,
    required this.raw,
    required this.episode,
  });
}

/* ------------------------------------------------------ */
/* 单页播放器                                              */
/* ------------------------------------------------------ */
class _VideoPage extends StatefulWidget {
  final _VideoItem video;
  final VideoPlayerController? preCachedController;

  const _VideoPage({
    required this.video,
    this.preCachedController,
    super.key,
  });

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _controller;
  ChewieController? _chewie;
  bool _hasError = false;
  bool _initializing = true;
  bool _wasPlaying = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _initializing = true;
    _hasError = false;
    try {
      _controller = widget.preCachedController ??
          VideoPlayerController.networkUrl(Uri.parse(widget.video.url));
      await _controller.initialize();
      if (!mounted) return;
      _chewie = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _controller.value.aspectRatio,
      );
      _initializing = false;
      setState(() {});
    } catch (_) {
      _initializing = false;
      _hasError = true;
      setState(() {});
    }
  }

  void pause() {
    if (_chewie == null) return;
    if (_controller.value.isPlaying) {
      _wasPlaying = true;
      _chewie!.pause();
    } else {
      _wasPlaying = false;
    }
  }

  void resumeIfNeeded() {
    if (_chewie == null) return;
    if (_wasPlaying) _chewie!.play();
  }

  void _togglePlay() {
    if (_chewie == null) return;
    if (_controller.value.isPlaying) {
      _chewie!.pause();
      _wasPlaying = false;
    } else {
      _chewie!.play();
      _wasPlaying = true;
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    if (widget.preCachedController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget playerArea;
    if (_initializing) {
      playerArea = const Center(
        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
      );
    } else if (_hasError) {
      playerArea = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            const Text('视频加载失败',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _initVideo, child: const Text('重试')),
          ],
        ),
      );
    } else {
      playerArea = AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Chewie(controller: _chewie!),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /* 播放器居中 */
          Center(child: playerArea),

          /* 简介、标题（下层） */
          Positioned(
            left: 16,
            bottom: 32,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    children: [
                      TextSpan(text: widget.video.name),
                      const TextSpan(text: ' 第 1 集'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          /* 手势层：覆盖播放器区域，但不遮挡按钮 */
          if (!_initializing && !_hasError)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _togglePlay,
              ),
            ),

          /* 明细按钮：最上层，确保优先响应点击 */
          Positioned(
            right: 24,
            bottom: 80,
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white, size: 32),
              onPressed: () {
                final movie = Movie.fromJson(widget.video.raw);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}