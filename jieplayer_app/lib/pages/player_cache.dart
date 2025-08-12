import 'package:video_player/video_player.dart';

class PlayerCache {
  static final PlayerCache _instance = PlayerCache._();
  factory PlayerCache() => _instance;
  PlayerCache._();

  VideoPlayerController? _controller;
  Duration _lastPosition = Duration.zero;
  String? _lastUrl;

  Future<VideoPlayerController> get(String url, Duration startAt) async {
    if (_controller != null && _lastUrl == url) {
      await _controller!.seekTo(startAt);
      return _controller!;
    }
    await release();
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();
    await _controller!.seekTo(startAt);
    _lastUrl = url;
    return _controller!;
  }

  Duration getSavedPosition(String url) =>
      _lastUrl == url ? _lastPosition : Duration.zero;

  Future<void> release() async {
    if (_controller != null) {
      _lastPosition = _controller!.value.position;
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
      _lastUrl = null;
    }
  }
}