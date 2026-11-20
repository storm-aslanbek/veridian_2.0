import 'package:veridian/services/ui_strings.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:veridian/services/localization_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<YandexMapController> _controllerCompleter = Completer();

  // Картадағы объектілер тізімі
  List<MapObject> mapObjects = [];

  // Қазір таңдалған сүзгі ('all', 'branch', 'atm')
  String _selectedFilter = 'all';

  final _localization = LocalizationService();

  // Тараздың орталығы (шамамен)
  final Point _taraz = const Point(latitude: 42.8900, longitude: 71.3700);

  final List<Map<String, dynamic>> _allMarkersData = [
    // Филиалдар
    {
      'id': 'branch_1',
      'lat': 42.897644,
      'lon': 71.357947,
      'title': 'Отделения',
      'address': 'улица Казыбек би, 182',
      'isBranch': true,
    },
    {
      'id': 'branch_2',
      'lat': 42.896956,
      'lon': 71.375237,
      'title': 'Отделения',
      'address': 'улица Казыбек би, 109А',
      'isBranch': true,
    },

    // Банкоматтар
    {
      'id': 'atm_1',
      'lat': 42.886051,
      'lon': 71.385747,
      'title': 'Банкомат',
      'address': 'проспект Абая, 157',
      'isBranch': false,
    },
    {
      'id': 'atm_2',
      'lat': 42.872177,
      'lon': 71.377860,
      'title': 'Банкомат',
      'address': 'улица Байзак Батыра, 194Д',
      'isBranch': false,
    },
    {
      'id': 'atm_3',
      'lat': 42.901724,
      'lon': 71.368706,
      'title': 'Банкомат',
      'address': 'улица Желтоксан, 71',
      'isBranch': false,
    },
    {
      'id': 'atm_4',
      'lat': 42.888330,
      'lon': 71.352078,
      'title': 'Банкомат',
      'address': 'микрорайон Салтанат, 31',
      'isBranch': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateMapMarkers();
  }

  // Flutter иконкасын суретке айналдыратын көмекші функция
  Future<Uint8List> _getIconBytes(IconData icon, Color color, int size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final iconStr = String.fromCharCode(icon.codePoint);

    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        letterSpacing: 0.0,
        fontSize: size.toDouble(),
        fontFamily: icon.fontFamily,
        color: color,
      ),
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image img = await picture.toImage(size, size);
    final ByteData? byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  // Маркерлерді жаңарту және сүзгілеу
  Future<void> _updateMapMarkers() async {
    List<MapObject> newMarkers = [];

    // Иконкаларды дайындау (Көк - филиал, Жасыл - банкомат)
    final branchIconBytes = await _getIconBytes(
      Icons.account_balance,
      Colors.blue[800]!,
      100,
    );
    final atmIconBytes = await _getIconBytes(
      Icons.atm,
      Colors.green[600]!,
      100,
    );

    for (var data in _allMarkersData) {
      bool isBranch = data['isBranch'] as bool;

      // СҮЗГІЛЕУ ЛОГИКАСЫ
      if (_selectedFilter == 'all' ||
          (_selectedFilter == 'branch' && isBranch) ||
          (_selectedFilter == 'atm' && !isBranch)) {
        newMarkers.add(
          PlacemarkMapObject(
            mapId: MapObjectId(data['id'] as String),
            point: Point(
              latitude: data['lat'] as double,
              longitude: data['lon'] as double,
            ),
            opacity: 1,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                // Дайын болған bytes суретті қолданамыз
                image: BitmapDescriptor.fromBytes(
                  isBranch ? branchIconBytes : atmIconBytes,
                ),
                scale: 0.7, // Иконка өлшемі
              ),
            ),
            onTap: (PlacemarkMapObject self, Point point) {
              _showMarkerInfo(
                context,
                data['title'] as String,
                data['address'] as String,
                isBranch,
                point,
              );
            },
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        mapObjects = newMarkers;
      });
    }
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
    });
    _updateMapMarkers();
  }

  Future<void> _moveToUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localization.translate('gps_disabled'),
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _localization.translate('permission_denied'),
              ),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiText('Доступ к геолокации запрещён.')),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      final controller = await _controllerCompleter.future;

      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
            zoom: 15,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.5,
        ),
      );
    } catch (e) {
      debugPrint("Қате: $e");
    }
  }

  void _showMarkerInfo(
    BuildContext context,
    String titleKey,
    String addressKey,
    bool isBranch,
    Point point,
  ) {
    // Егер аударма кілті табылмаса, мәтіннің өзін көрсетеді
    final title = uiText(titleKey);
    final address = uiText(addressKey);
    final type = isBranch
        ? _localization.translate('branch')
        : _localization.translate('atm');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Icon(
                    isBranch ? Icons.account_balance : Icons.local_atm,
                    color: isBranch ? Colors.blue[800] : Colors.green[600],
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openMaps(point);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _localization.translate('build_route'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMaps(Point point) async {
    final url =
        'https://yandex.kz/maps/?pt=${point.longitude},${point.latitude}&z=15&l=map';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _zoomIn() async {
    final controller = await _controllerCompleter.future;
    await controller.moveCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = await _controllerCompleter.future;
    await controller.moveCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _localization.translate('bank_on_map'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. КАРТА
          YandexMap(
            onMapCreated: (YandexMapController controller) {
              _controllerCompleter.complete(controller);
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _taraz, zoom: 13),
                ),
              );
            },
            mapObjects: mapObjects,
            zoomGesturesEnabled: true,
          ),

          // 2. БАСҚАРУ БАТЫРМАЛАРЫ (+, -, location)
          Positioned(
            right: 15,
            top: MediaQuery.of(context).size.height * 0.30,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 10),
                _MapButton(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(height: 20),
                _MapButton(
                  icon: Icons.my_location,
                  onPressed: _moveToUserLocation,
                ),
              ],
            ),
          ),

          // 3. СҮЗГІ БАТЫРМАЛАРЫ ЖӘНЕ АҚПАРАТТЫҚ КАРТОЧКА
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: _localization.translate('filter_all'),
                        isSelected: _selectedFilter == 'all',
                        onTap: () => _onFilterChanged('all'),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: _localization.translate('filter_branches'),
                        isSelected: _selectedFilter == 'branch',
                        onTap: () => _onFilterChanged('branch'),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: _localization.translate('filter_atms'),
                        isSelected: _selectedFilter == 'atm',
                        onTap: () => _onFilterChanged('atm'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _localization.translate('map_info_text'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _MapButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
