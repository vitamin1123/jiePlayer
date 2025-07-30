import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/services.dart';
import 'pages/movies_page.dart';

void main() {
  // 保证竖屏
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const JiePlayerApp());
}

/* =========================
 * 整个应用的根
 * ========================= */
class JiePlayerApp extends StatelessWidget {
  const JiePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JiePlayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'PingFang SC',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
      ),
      home: const AppRoot(), // 统一入口
    );
  }
}

/* =========================
 * 带 BottomNavigationBar 的壳子
 * ========================= */
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),   // 首页
    MoviesPage(), // 影片页
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: '影片',
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/* =========================
 * 真正的「首页」内容
 * ========================= */
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<String> _groups = [
    '推荐', '电影', '电视剧', '综艺', '动漫', '纪录片', '短剧', 'VIP专区'
  ];
  final List<String> _tabs = [
    '热门', '最新', '高分', '经典', '冷门', '豆瓣榜', '热搜', '收藏'
  ];
  String _selectedGroup = '推荐';
  int _selectedTab = 0;
  bool _showGroupPopup = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get _mockList => List.generate(
        20,
        (i) => '${_tabs[_selectedTab]}内容 ${i + 1}',
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // 顶部分组
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showGroupPopup = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF007AFF),
                              width: 1.5,
                            ),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedGroup,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _showGroupPopup
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 22,
                                color: _showGroupPopup
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        icon: const Icon(Icons.search,
                            color: Color(0xFF8E8E93)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // 横向 Tab
                SizedBox(
                  height: 44,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final selected = _tabController.index == i;
                        return GestureDetector(
                          onTap: () => _tabController.animateTo(i),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF007AFF).withOpacity(0.12)
                                  : Colors.white,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFE5E5EA),
                                width: 1.5,
                              ),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(22),
                                right: Radius.circular(22),
                              ),
                            ),
                            child: Text(
                              _tabs[i],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                // 列表
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _mockList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, index) => _buildCard(_mockList[index]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 分组弹窗
        if (_showGroupPopup)
          _GroupPopup(
            groups: _groups,
            selected: _selectedGroup,
            onClose: () => setState(() => _showGroupPopup = false),
            onConfirm: (group) {
              setState(() {
                _selectedGroup = group;
                _showGroupPopup = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildCard(String text) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
          onTap: () {},
        ),
      );
}

/* =========================
 * 影片页（空壳，可自行扩展）
 * ========================= */
// class MoviesPage extends StatelessWidget {
//   const MoviesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('影片页内容'));
//   }
// }

/* =========================
 * 分组选择弹窗
 * ========================= */
class _GroupPopup extends StatefulWidget {
  final List<String> groups;
  final String selected;
  final VoidCallback onClose;
  final ValueChanged<String> onConfirm;

  const _GroupPopup({
    required this.groups,
    required this.selected,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  State<_GroupPopup> createState() => _GroupPopupState();
}

class _GroupPopupState extends State<_GroupPopup> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.6;
    return Material(
      color: Colors.black.withOpacity(0.25),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(Icons.close,
                              size: 26, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: widget.groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final group = widget.groups[index];
                        final selected = group == _selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = group),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF007AFF).withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(
                                      color: const Color(0xFF007AFF),
                                      width: 1.5)
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  group,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? const Color(0xFF007AFF)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const Spacer(),
                                if (selected)
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF007AFF), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => widget.onConfirm(_selected),
                        child: const Text(
                          '确认分组',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}