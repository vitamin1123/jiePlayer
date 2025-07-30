import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import 'movie_detail_page.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});
  
  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<MovieCategory> _categories = [];
  List<Movie> _movies = [];
  String _selectedCategoryId = '0';
  String _searchQuery = '';
  int _currentPage = 1;
  int _maxPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMovies();
    }
  }
  
  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response['class'] != null) {
        final categories = (response['class'] as List)
            .map((item) => MovieCategory.fromJson(item))
            .where((category) => category.typeId != '19' && category.typeId != '61')
            .toList();
        
        setState(() {
          _categories = [
            MovieCategory(typeId: '0', typeName: '全部'),
            ...categories,
          ];
        });
      }
    } catch (e) {
      _showErrorSnackBar('获取分类失败: $e');
    }
  }
  
  Future<void> _loadMovies({bool isRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _movies.clear();
        _currentPage = 1;
      }
    });
    
    try {
      final response = await ApiService.getMovies(
        typeId: _selectedCategoryId,
        page: _currentPage,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      if (response['code'] == 1) {
        final movieList = (response['list'] as List)
            .map((item) => Movie.fromJson(item))
            .where((movie) => movie.typeId != '19' && movie.typeId != '61')
            .toList();
        
        setState(() {
          if (isRefresh) {
            _movies = movieList;
          } else {
            _movies.addAll(movieList);
          }
          _maxPage = response['pagecount'] ?? 1;
        });
      }
    } catch (e) {
      _showErrorSnackBar('加载影片失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMoreMovies() async {
    if (_isLoadingMore || _currentPage >= _maxPage) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    try {
      final response = await ApiService.getMovies(
        typeId: _selectedCategoryId,
        page: _currentPage,
        keyword: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      if (response['code'] == 1) {
        final movieList = (response['list'] as List)
            .map((item) => Movie.fromJson(item))
            .where((movie) => movie.typeId != '19' && movie.typeId != '61')
            .toList();
        
        setState(() {
          _movies.addAll(movieList);
        });
      }
    } catch (e) {
      _showErrorSnackBar('加载更多失败: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  void _onCategoryChanged(String? categoryId) {
    if (categoryId != null && categoryId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = categoryId;
      });
      _loadMovies(isRefresh: true);
    }
  }
  
  void _onSearchSubmitted(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadMovies(isRefresh: true);
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _navigateToDetail(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(movie: movie),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white.withOpacity(0.85),
            expandedHeight: 80,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategoryId,
                            hint: const Text('选择分类', style: TextStyle(fontSize: 15)),
                            isExpanded: true,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.typeId,
                                child: Center(
                                  child: Text(
                                    category.typeName,
                                    style: const TextStyle(fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onCategoryChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                          decoration: InputDecoration(
                            hintText: '输入关键词搜索',
                            hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.7),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _onSearchSubmitted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: _movies.length,
              itemBuilder: (context, index) {
                return _buildMovieCard(_movies[index], index);
              },
            ),
          ),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMovieCard(Movie movie, int index) {
    final cardHeight = 200.0 + (index % 3) * 30; // 创建瀑布流效果
    
    return GestureDetector(
      onTap: () => _navigateToDetail(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4), // 原来是8
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4), // 原来是8
          child: Container(
            height: cardHeight,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 影片封面
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A90E2).withOpacity(0.8),
                          const Color(0xFF4A90E2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 背景图片
                        if (movie.vodPic.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              movie.vodPic,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF4A90E2),
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // 渐变遮罩
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // 播放按钮
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        // 评分标签
                        if (movie.vodScore.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                borderRadius: BorderRadius.circular(4), // 评分标签建议保持4
                              ),
                              child: Text(
                                movie.vodScore,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // 影片信息
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.vodName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.vodContent.isNotEmpty 
                              ? movie.vodContent
                              : movie.vodRemarks,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}