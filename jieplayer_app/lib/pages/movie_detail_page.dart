import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/movie_model.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  
  const MovieDetailPage({super.key, required this.movie});
  
  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  int? _currentPlayingIndex;
  bool _isPlayerVisible = false;
  
  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }
  
  void _playVideo(int index) async {
    final playList = widget.movie.playList;
    if (index >= playList.length) return;
    
    // 销毁之前的播放器
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    
    // 创建新的视频播放器控制器
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(playList[index].url),
    );
    
    try {
      await _videoPlayerController!.initialize();
      
      // 创建 Chewie 控制器
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
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
      
      // 监听播放完成事件
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration) {
          // 播放完成后自动播放下一个
          if (index < playList.length - 1) {
            _playVideo(index + 1);
          }
        }
      });
      
      setState(() {
        _currentPlayingIndex = index;
        _isPlayerVisible = true;
      });
    } catch (e) {
      print('视频加载失败: $e');
      // 可以显示错误提示
    }
  }
  
  void _hidePlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    setState(() {
      _currentPlayingIndex = null;
      _isPlayerVisible = false;
      _chewieController = null;
      _videoPlayerController = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final playList = widget.movie.playList;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.movie.vodName,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主内容卡片
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面和基本信息
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧封面图
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.movie.vodPic,
                            width: 120,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 160,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.movie,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 右侧信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.movie.vodName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (widget.movie.vodScore.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF007AFF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${widget.movie.vodScore} 分',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.category, '类型', '${widget.movie.typeName} ${widget.movie.vodClass}'),
                              _buildInfoRow(Icons.access_time, '时长', '${widget.movie.vodDuration}分钟'),
                              _buildInfoRow(Icons.calendar_today, '年份', widget.movie.vodYear),
                              _buildInfoRow(Icons.location_on, '地区', '${widget.movie.vodArea}（${widget.movie.vodLang}）'),
                              if (widget.movie.vodActor.isNotEmpty)
                                _buildInfoRow(Icons.people, '演员', widget.movie.vodActor),
                              if (widget.movie.vodRemarks.isNotEmpty)
                                _buildInfoRow(Icons.note, '备注', widget.movie.vodRemarks),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 简介
                  if (widget.movie.vodContent.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '剧情简介',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.movie.vodContent,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 播放器区域
            if (_isPlayerVisible && _chewieController != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            '正在播放',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
                            onPressed: _hidePlayer,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Chewie(controller: _chewieController!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // 播放列表
            if (playList.isNotEmpty)
              Container(
                margin: EdgeInsets.fromLTRB(16, _isPlayerVisible ? 16 : 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '播放列表',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: playList.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFE5E5EA),
                      ),
                      itemBuilder: (context, index) {
                        final isPlaying = _currentPlayingIndex == index;
                        return ListTile(
                          leading: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                            color: isPlaying ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                          ),
                          title: Text(
                            playList[index].title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                              color: isPlaying ? const Color(0xFF007AFF) : const Color(0xFF1A1A1A),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPlaying ? const Color(0xFF007AFF) : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isPlaying ? '播放中' : '播放',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isPlaying ? Colors.white : const Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                          onTap: () => _playVideo(index),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF8E8E93),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label：$value',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}