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

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  /// initState 함수는 async 안됨
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final position = await _determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// GoogleMap으로 구글맵을 띄울 수 있다.
      body: GoogleMap(
        /// 맵 타입을 normal로 변경하면 기본 모드
        mapType: MapType.normal,

        /// 첫 시작점 구글 본사
        initialCameraPosition: _kGooglePlex,

        /// 맵이 생성되자마자 맵을 컨트롤 할 수 있는 컨트롤러를 반환이 된다. 지도 조작 가능하다.
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),

      /// _goToTheLake가 찍힌다.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    final currentLocation = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
      zoom: 18,
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
