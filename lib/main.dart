import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'baseball_stitch_background.dart';
import 'collection_photo.dart';
import 'team_logos.dart';
import 'user_collection_storage.dart';

void main() {
  runApp(const MlbStadiumApp());
}

class MlbStadiumApp extends StatelessWidget {
  const MlbStadiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MLB Stadium Map Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002D62)),
        useMaterial3: true,
      ),
      home: const StadiumMapPage(),
    );
  }
}

// 球場資料模型
class Stadium {
  final String team;
  final String name;
  final String league;
  final Color teamColor;
  final double latitude;
  final double longitude;
  final String description;
  final String stadiumImagePath; // 新增：對應 JSON 中的地端照片路徑
  final String? logoAssetPath; // 地圖標點用的球隊 logo

  bool hasTicket;
  bool hasCap;
  bool hasBobblehead;

  String? ticketPhotoPath;
  String? capPhotoPath;
  String? bobbleheadPhotoPath;

  Stadium({
    required this.team,
    required this.name,
    required this.league,
    required this.teamColor,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.stadiumImagePath,
    this.logoAssetPath,
    this.hasTicket = false,
    this.hasCap = false,
    this.hasBobblehead = false,
  });

  bool get isFullyUnlocked => hasTicket && hasCap && hasBobblehead;

  /// 三項收藏任勾一項，該球場即計入巡禮進度（每座最多算 1）。
  bool get hasAnyCollection => hasTicket || hasCap || hasBobblehead;
}

/// 依 usa_map.png 實際版面，把經緯度換算成螢幕上的標點座標。
class _UsMapLayout {
  static const double imageWidth = 1513;
  static const double imageHeight = 983;
  static const double displayScale = 0.9;

  // 本土 48 州在 PNG 上的可繪製區域（比例，對應 Wikimedia 空白美國地圖）
  static const double contentLeft = 0.108;
  static const double contentTop = 0.098;
  static const double contentWidth = 0.785;
  static const double contentHeight = 0.680;

  static const double lonWest = -124.5;
  static const double lonEast = -67.0;
  static const double latNorth = 49.0;
  static const double latSouth = 25.0;

  /// 相對地圖寬度的水平微調（正值往右、負值往左）
  static const Map<String, double> _shiftXByTeam = {
    // 右上角東北區：略往右
    'Boston Red Sox': 0.085,
    'New York Yankees': 0.085,
    'New York Mets': 0.085,
    'Toronto Blue Jays': 0.028,
    'Philadelphia Phillies': 0.085,
    'Baltimore Orioles': 0.085,
    'Washington Nationals': 0.085,
    'Pittsburgh Pirates': 0.055,
    // 西岸 AL：往左（再左移一次）
    'Los Angeles Angels': -0.080,
    'Oakland Athletics': -0.080,
    // NL 左下／灣區：往左（再左移一次；Diamondbacks 維持原幅度）
    'San Diego Padres': -0.110,
    'Los Angeles Dodgers': -0.110,
    'Arizona Diamondbacks': -0.055,
    'San Francisco Giants': -0.110,
    // Cleveland：略往右一點點
    'Cleveland Guardians': 0.012,
    // Rockies：往左
    'Colorado Rockies': -0.035,
    // Marlins：大幅度往右（再移一次）
    'Miami Marlins': 0.140,
    'Chicago White Sox': 0.040,
    'Minnesota Twins': 0.025,
    // Reds / Braves：大幅度往右
    'Cincinnati Reds': 0.070,
    'Atlanta Braves': 0.095,
    // Rays：大幅度往右兩次後，微調往左
    'Tampa Bay Rays': 0.115,
  };

  /// 相對地圖高度的垂直微調（正值往下、負值往上）
  static const Map<String, double> _shiftYByTeam = {
    'Arizona Diamondbacks': 0.035,
    'Colorado Rockies': 0.065,
    'St. Louis Cardinals': 0.080,
    // Marlins：大幅度往下（再移一次）
    'Miami Marlins': 0.160,
    'Pittsburgh Pirates': 0.040,
    'Chicago White Sox': 0.040,
    'Minnesota Twins': 0.025,
    // 中南區：大幅度往下（Houston 移兩次）
    'Kansas City Royals': 0.070,
    'Texas Rangers': 0.140,
    'Houston Astros': 0.210,
    // Reds / Braves：大幅度往下
    'Cincinnati Reds': 0.070,
    'Atlanta Braves': 0.120,
    // Rays：大幅度往下兩次
    'Tampa Bay Rays': 0.140,
  };

  final double containerWidth;
  final double containerHeight;
  final double displayWidth;
  final double displayHeight;
  final double offsetX;
  final double offsetY;

  _UsMapLayout({
    required this.containerWidth,
    required this.containerHeight,
  })  : displayWidth = imageWidth * _fitScale(containerWidth, containerHeight) * displayScale,
        displayHeight = imageHeight * _fitScale(containerWidth, containerHeight) * displayScale,
        offsetX = (containerWidth - imageWidth * _fitScale(containerWidth, containerHeight) * displayScale) / 2,
        offsetY = (containerHeight - imageHeight * _fitScale(containerWidth, containerHeight) * displayScale) / 2;

  static double _fitScale(double containerWidth, double containerHeight) {
    final widthScale = containerWidth / imageWidth;
    final heightScale = containerHeight / imageHeight;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  /// 標點圓心座標（markerSize 為圓點直徑）
  Offset markerCenter(double latitude, double longitude, double markerSize) {
    final xRatio = ((longitude - lonWest) / (lonEast - lonWest)).clamp(0.0, 1.0);
    final yRatio = ((latNorth - latitude) / (latNorth - latSouth)).clamp(0.0, 1.0);

    final xOnImage = contentLeft + xRatio * contentWidth;
    final yOnImage = contentTop + yRatio * contentHeight;

    return Offset(
      offsetX + xOnImage * displayWidth,
      offsetY + yOnImage * displayHeight,
    );
  }

  Offset markerCenterForStadium(Stadium stadium, double markerSize) {
    final center = markerCenter(
      stadium.latitude,
      stadium.longitude,
      markerSize,
    );
    final shiftX = _shiftXByTeam[stadium.team] ?? 0.0;
    final shiftY = _shiftYByTeam[stadium.team] ?? 0.0;
    if (shiftX == 0.0 && shiftY == 0.0) return center;
    return Offset(
      center.dx + shiftX * displayWidth,
      center.dy + shiftY * displayHeight,
    );
  }

  Offset markerTopLeftForStadium(Stadium stadium, double markerSize) {
    final center = markerCenterForStadium(stadium, markerSize);
    return Offset(center.dx - markerSize / 2, center.dy - markerSize / 2);
  }
}

// 主頁面：地圖插旗頁
class StadiumMapPage extends StatefulWidget {
  const StadiumMapPage({super.key});

  @override
  State<StadiumMapPage> createState() => _StadiumMapPageState();
}

class _StadiumMapPageState extends State<StadiumMapPage>
    with SingleTickerProviderStateMixin {
  List<Stadium> stadiums = [];
  bool isLoading = true;
  TabController? _tabController;

  // 記錄目前滑鼠懸停在線上的球場，用來動態顯示介紹框
  Stadium? hoveredStadium;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStadiumsFromPythonJson(); // 🚀 初始化時，直接去 assets 讀取你的完整 JSON
  }

  // ⭐ 核心功能：讀取並動態解析 Python 生成出來的 30 座球場 JSON
  Future<void> _loadStadiumsFromPythonJson() async {
    try {
      // 1. 讀取地端文字檔
      final String response = await rootBundle.loadString(
        'assets/stadiums_data.json',
      );
      // 2. 用 jsonDecode 轉成陣列
      final List<dynamic> data = jsonDecode(response);

      // 3. 跑迴圈對應塞入物件
      final loadedStadiums = data.map((json) {
        String hexColor = json['teamColor'].replaceAll('#', '0xFF');
        return Stadium(
          team: json['team'],
          name: json['name'],
          league: json['league'],
          teamColor: Color(int.parse(hexColor)),
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
          description: json['description'] ?? '大聯盟精彩主場球場之一',
          stadiumImagePath:
              json['localImagePath'] ?? 'assets/stadium_photos/default.jpg',
          logoAssetPath: TeamLogos.pathForTeam(json['team'] as String),
        );
      }).toList();

      final collection = await UserCollectionStorage.load();
      _applyCollectionToStadiums(loadedStadiums, collection);

      setState(() {
        stadiums = loadedStadiums;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("讀取 JSON 失敗，請確保 assets/stadiums_data.json 設定正確。錯誤: $e");
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _applyCollectionToStadiums(
    List<Stadium> list,
    Map<String, dynamic> root,
  ) {
    final entries = root['stadiums'];
    if (entries is! Map<String, dynamic>) return;

    for (final stadium in list) {
      final id = UserCollectionStorage.stadiumIdFromImagePath(
        stadium.stadiumImagePath,
      );
      final raw = entries[id];
      if (raw is! Map<String, dynamic>) continue;

      stadium.hasTicket = raw['hasTicket'] == true;
      stadium.hasCap = raw['hasCap'] == true;
      stadium.hasBobblehead = raw['hasBobblehead'] == true;
      stadium.ticketPhotoPath = raw['ticketPhotoPath'] as String?;
      stadium.capPhotoPath = raw['capPhotoPath'] as String?;
      stadium.bobbleheadPhotoPath = raw['bobbleheadPhotoPath'] as String?;
    }
  }

  Future<void> _persistCollection() async {
    final stadiumsMap = <String, dynamic>{};
    for (final stadium in stadiums) {
      final id = UserCollectionStorage.stadiumIdFromImagePath(
        stadium.stadiumImagePath,
      );
      stadiumsMap[id] = UserCollectionStorage.entryFromStadium(
        hasTicket: stadium.hasTicket,
        hasCap: stadium.hasCap,
        hasBobblehead: stadium.hasBobblehead,
        ticketPhotoPath: stadium.ticketPhotoPath,
        capPhotoPath: stadium.capPhotoPath,
        bobbleheadPhotoPath: stadium.bobbleheadPhotoPath,
      );
    }
    await UserCollectionStorage.saveDocument({
      'version': 1,
      'stadiums': stadiumsMap,
    });
  }

  int _visitedStadiumCount() =>
      stadiums.where((s) => s.hasAnyCollection).length;

  @override
  Widget build(BuildContext context) {
    final visitedCount = _visitedStadiumCount();
    final totalStadiums = stadiums.length;
    final progress =
        totalStadiums == 0 ? 0.0 : visitedCount / totalStadiums;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E6D4),
      appBar: AppBar(
        title: const Text(
          'MLB 全美球場巡禮插旗地圖',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF002D62),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: '⚾ 美國聯盟 (AL) 地圖'),
            Tab(text: '⚾ 國家聯盟 (NL) 地圖'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 進度條
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: Colors.blueAccent, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '全美球場巡禮進度：$visitedCount / $totalStadiums 座',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '每座球場三項收藏任勾一項即計入（每座最多 1）',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.green,
                              backgroundColor: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 地圖主戰場（底層淡縫線背景，不影響標點座標）
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const BaseballStitchBackground(),
                      TabBarView(
                        controller: _tabController,
                        physics:
                            const NeverScrollableScrollPhysics(), // 停用滑動切換，避免跟滑鼠互動衝突
                        children: [
                          _buildMapView(leagueFilter: 'AL'),
                          _buildMapView(leagueFilter: 'NL'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 核心功能：建立地圖與插旗點
  Widget _buildMapView({required String leagueFilter}) {
    final filteredStadiums = stadiums
        .where((s) => s.league == leagueFilter)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const markerSize = 32.0;
        final layout = _UsMapLayout(
          containerWidth: constraints.maxWidth,
          containerHeight: constraints.maxHeight,
        );

        return Stack(
          children: [
            // 1. 最底層：本地美國地圖（90% 縮放、置中）
            Positioned(
              left: layout.offsetX,
              top: layout.offsetY,
              width: layout.displayWidth,
              height: layout.displayHeight,
              child: Image.asset(
                'assets/usa_map_ocean.png',
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text(
                        '🗺️ 無法載入地圖\n請確認 assets/usa_map_ocean.png 存在',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. 中間層：球隊 logo 標點
            ...filteredStadiums.map((stadium) {
              final point = layout.markerTopLeftForStadium(stadium, markerSize);

              return Positioned(
                left: point.dx,
                top: point.dy,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => hoveredStadium = stadium),
                  onExit: (_) => setState(() => hoveredStadium = null),
                  child: GestureDetector(
                    onTap: () => _navigateToDetail(stadium),
                    child: _buildTeamLogoMarker(stadium, markerSize),
                  ),
                ),
              );
            }),

            // 3. 最頂層：滑鼠懸停介紹框
            if (hoveredStadium != null &&
                hoveredStadium!.league == leagueFilter)
              _buildHoverCard(hoveredStadium!, layout),
          ],
        );
      },
    );
  }

  Widget _buildTeamLogoMarker(Stadium stadium, double size) {
    final borderColor =
        stadium.hasAnyCollection ? Colors.green : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: stadium.logoAssetPath == null
          ? ColoredBox(
              color: stadium.teamColor,
              child: const Icon(Icons.sports_baseball, size: 16, color: Colors.white),
            )
          : Image.asset(
              stadium.logoAssetPath!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: stadium.teamColor,
                  child: const Icon(
                    Icons.sports_baseball,
                    size: 16,
                    color: Colors.white,
                  ),
                );
              },
            ),
    );
  }

  // 建立懸停介紹框
  Widget _buildHoverCard(Stadium stadium, _UsMapLayout layout) {
    const markerSize = 32.0;
    final center = layout.markerCenterForStadium(stadium, markerSize);

    double leftPosition = center.dx + 16;
    double topPosition = center.dy - 100;

    // 防止卡片溢出右側邊界
    if (leftPosition > layout.containerWidth - 240) {
      leftPosition = leftPosition - 250;
    }
    if (topPosition < 8) {
      topPosition = center.dy + 20;
    }

    return Positioned(
      left: leftPosition,
      top: topPosition,
      child: GestureDetector(
        onTap: () => _navigateToDetail(stadium),
        child: MouseRegion(
          onEnter: (_) => setState(() => hoveredStadium = stadium),
          onExit: (_) => setState(() => hoveredStadium = null),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ 智慧型防破圖圖片渲染區塊：有 local 讀 local，沒有就優雅切換為優質網路圖
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: stadium.teamColor.withValues(alpha: 0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        stadium.stadiumImagePath,
                        fit: BoxFit.cover,
                        // 當 local 圖片找不到或破圖時，會秒速執行底下的替代機制
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://images.unsplash.com/photo-1544045564-252f9a716d6c?w=400&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            errorBuilder: (context, err, st) {
                              return Center(
                                child: Icon(
                                  Icons.stadium,
                                  color: stadium.teamColor,
                                  size: 36,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stadium.team,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: stadium.teamColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    stadium.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stadium.description,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 14,
                            color: stadium.hasTicket
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.local_play,
                            size: 14,
                            color: stadium.hasCap
                                ? Colors.red
                                : Colors.grey[300],
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.accessibility,
                            size: 14,
                            color: stadium.hasBobblehead
                                ? Colors.orange
                                : Colors.grey[300],
                          ),
                        ],
                      ),
                      const Text(
                        '點擊進入 ➔',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Stadium stadium) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StadiumDetailPage(
          stadium: stadium,
          onCollectionChanged: _persistCollection,
        ),
      ),
    );
    setState(() {}); // 回來時刷新進度條
  }
}

// 球場詳細回憶頁面
class StadiumDetailPage extends StatefulWidget {
  final Stadium stadium;
  final Future<void> Function() onCollectionChanged;

  const StadiumDetailPage({
    super.key,
    required this.stadium,
    required this.onCollectionChanged,
  });

  @override
  State<StadiumDetailPage> createState() => _StadiumDetailPageState();
}

class _StadiumDetailPageState extends State<StadiumDetailPage> {
  @override
  Widget build(BuildContext context) {
    final stadium = widget.stadium;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(stadium.team),
        backgroundColor: stadium.teamColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: stadium.teamColor, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stadium.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '所屬聯盟：${stadium.league == 'AL' ? '美國聯盟' : '國家聯盟'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            '地理坐標：${stadium.latitude.toStringAsFixed(4)}, ${stadium.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '我的收藏清單',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '左側圖示切換是否收集；下方區域上傳／更換照片',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            _buildCollectionTile(
              title: '🎫 進場票根',
              isCollected: stadium.hasTicket,
              photoPath: stadium.ticketPhotoPath,
              onToggle: () => _toggleCollection(
                () => stadium.hasTicket = !stadium.hasTicket,
              ),
              onPickPhoto: () => _pickPhotoFor(
                setPath: (path) => stadium.ticketPhotoPath = path,
                markCollected: () => stadium.hasTicket = true,
              ),
              onClearPhoto: stadium.ticketPhotoPath == null
                  ? null
                  : () => _clearPhotoFor(
                        clearPath: () => stadium.ticketPhotoPath = null,
                      ),
            ),
            _buildCollectionTile(
              title: '🧢 限定禮物 / 球帽',
              isCollected: stadium.hasCap,
              photoPath: stadium.capPhotoPath,
              onToggle: () => _toggleCollection(
                () => stadium.hasCap = !stadium.hasCap,
              ),
              onPickPhoto: () => _pickPhotoFor(
                setPath: (path) => stadium.capPhotoPath = path,
                markCollected: () => stadium.hasCap = true,
              ),
              onClearPhoto: stadium.capPhotoPath == null
                  ? null
                  : () => _clearPhotoFor(
                        clearPath: () => stadium.capPhotoPath = null,
                      ),
            ),
            _buildCollectionTile(
              title: '🧸 搖頭娃娃 (Bobblehead)',
              isCollected: stadium.hasBobblehead,
              photoPath: stadium.bobbleheadPhotoPath,
              onToggle: () => _toggleCollection(
                () => stadium.hasBobblehead = !stadium.hasBobblehead,
              ),
              onPickPhoto: () => _pickPhotoFor(
                setPath: (path) => stadium.bobbleheadPhotoPath = path,
                markCollected: () => stadium.hasBobblehead = true,
              ),
              onClearPhoto: stadium.bobbleheadPhotoPath == null
                  ? null
                  : () => _clearPhotoFor(
                        clearPath: () => stadium.bobbleheadPhotoPath = null,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCollection(VoidCallback toggle) async {
    setState(toggle);
    await widget.onCollectionChanged();
  }

  Future<void> _pickPhotoFor({
    required void Function(String path) setPath,
    required VoidCallback markCollected,
  }) async {
    try {
      final encoded = await CollectionPhoto.pickAndEncode();
      if (encoded == null || !mounted) return;

      setState(() {
        setPath(encoded);
        markCollected();
      });
      await widget.onCollectionChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上傳失敗：$e')),
      );
    }
  }

  Future<void> _clearPhotoFor({required VoidCallback clearPath}) async {
    setState(clearPath);
    await widget.onCollectionChanged();
  }

  Widget _buildCollectionTile({
    required String title,
    required bool isCollected,
    required String? photoPath,
    required VoidCallback onToggle,
    required VoidCallback onPickPhoto,
    required VoidCallback? onClearPhoto,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '切換收集狀態',
                  onPressed: onToggle,
                  icon: Icon(
                    isCollected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCollected ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (onClearPhoto != null)
                  TextButton(
                    onPressed: onClearPhoto,
                    child: const Text('清除照片'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: onPickPhoto,
              borderRadius: BorderRadius.circular(8),
              child: CollectionPhoto.preview(photoPath, height: 120),
            ),
          ],
        ),
      ),
    );
  }
}
