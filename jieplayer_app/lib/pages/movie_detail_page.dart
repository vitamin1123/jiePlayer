import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import '../models/movie_model.dart';
import 'player_cache.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late final _cache = PlayerCache();
  ChewieController? _chewie;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _play(0);
  }

  @override
  void dispose() {
    _chewie?.dispose();
    super.dispose();
  }

  Future<void> _play(int index) async {
    if (index >= widget.movie.playList.length) return;
    _currentIndex = index;
    final url = widget.movie.playList[index].url;
    final pos = _cache.getSavedPosition(url);

    final controller = await _cache.get(url, pos);

    _chewie?.dispose();
    _chewie = ChewieController(
      videoPlayerController: controller,
      aspectRatio: 16 / 9,
      autoPlay: true,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF007AFF),
        handleColor: const Color(0xFF007AFF),
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.withOpacity(0.5),
      ),
    );
    controller.addListener(() {
      if (controller.value.position >= controller.value.duration &&
          index < widget.movie.playList.length - 1) {
        _play(index + 1);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.movie.vodName,
            style: const TextStyle(color: Color(0xFF1A1A1A))),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PlayerHeader(
              child: _chewie == null
                  ? const Center(child: CircularProgressIndicator())
                  : AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Chewie(controller: _chewie!),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.movie.vodContent.isNotEmpty)
                    Text(widget.movie.vodContent,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                  const Text('播放列表',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...List.generate(widget.movie.playList.length, (i) {
                    return ListTile(
                      leading: Icon(
                          i == _currentIndex
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_outline,
                          color: i == _currentIndex
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF8E8E93)),
                      title: Text(widget.movie.playList[i].title),
                      onTap: () => _play(i),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PlayerHeader({required this.child});

  @override
  double get minExtent => MediaQueryData.fromView(WidgetsBinding.instance.window).size.width * 9 / 16;
  @override
  double get maxExtent => minExtent;

  @override
  Widget build(_, __, ___) => child;

  @override
  bool shouldRebuild(_) => true;
}