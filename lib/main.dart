import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GpsMapApp(),
    );
  }
}

class GpsMapApp extends StatefulWidget {
  const GpsMapApp({super.key});

  @override
  State<GpsMapApp> createState() => GpsMapAppState();
}

class GpsMapAppState extends State<GpsMapApp> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  CameraPosition? _initialCameraPosition;

  int _polylineIdCounter = 0;
  Set<Polyline> _polyLines = {};
  LatLng? _prevPosition;

  /// initState 함수는 async 안됨
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final position = await _determinePosition();

    _initialCameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 17,
    );

    setState(() {});

    /// LocationSettings : 위치 정보를 얼마나 정밀하게 조절 가능, 기본값으로
    const locationSettings = LocationSettings();
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _polylineIdCounter++;
      final polylineId = PolylineId('$_polylineIdCounter');
      final polyline = Polyline(
        polylineId: polylineId,
        color: Colors.red,
        width: 3,
        points: [
          _prevPosition ?? _initialCameraPosition!.target,
          LatLng(position.latitude, position.longitude),
        ],
      );
      setState(() {
        _polyLines.add(polyline);
        _prevPosition = LatLng(position.latitude, position.longitude);
      });
      _moveCamera(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// GoogleMap으로 구글맵을 띄울 수 있다.
      body: _initialCameraPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              /// 맵 타입을 normal로 변경하면 기본 모드
              mapType: MapType.normal,

              /// 첫 시작점 구글 본사
              initialCameraPosition: _initialCameraPosition!,

              /// 맵이 생성되자마자 맵을 컨트롤 할 수 있는 컨트롤러를 반환이 된다. 지도 조작 가능하다.
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              polylines: _polyLines,
            ),
    );
  }

  Future<void> _moveCamera(Position position) async {
    final GoogleMapController controller = await _controller.future;

    /// 지속적으로 현재 위치값을 받을 수 있다.
    /// Stream 지속적으로 변경이 되는 값, 새로운 위치 정보를 받는다.
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 17,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  /// 현재 위치 정보에 접근해야 할 때 사용
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    /// 로케이션 서비스가 켜져 있는지, 기기의 위치정보 기능을 off하면 false
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    /// 현재 위치 정보를 얻기 위해서는 사용자 동의를 얻어야 한다. 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    /// 거부를 2번이상 하면 더 이상 사용자에게 물어보지 않고 off
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    /// 위치 정보 권한을 받으면 현재 위치 정보를 얻는다.
    return await Geolocator.getCurrentPosition();
  }
}
