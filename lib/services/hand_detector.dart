import 'package:camera/camera.dart';
import 'package:hand_detection/hand_detection.dart';
import 'package:flutter/services.dart';

class HandBoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  const HandBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class HandDetectorService {
  HandDetector? _detector;
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      
      _detector = await HandDetector.create(
        mode: HandMode.boxesAndLandmarks,
        detectorConf: 0.5,        // Seuil plus haut = détection plus rapide
        maxDetections: 1,         // Une seule main = beaucoup plus rapide
        minLandmarkScore: 0.2,
        enableGestures: false,
        
      );
      _initialized = true;
      print(' HandDetector initialisé');
    } catch (e) {
      print(' HandDetector init error: $e');
      _initialized = false;
    }
  }



  int resolveRotationDegrees({
    required int sensorOrientation,
    required bool isFrontCamera,
    required DeviceOrientation deviceOrientation,
  }) {
    int deviceDegrees;
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:     deviceDegrees = 0;   break;
      case DeviceOrientation.landscapeLeft:  deviceDegrees = 90;  break;
      case DeviceOrientation.portraitDown:   deviceDegrees = 180; break;
      case DeviceOrientation.landscapeRight: deviceDegrees = 270; break;
      default: deviceDegrees = 0;
    }

    if (isFrontCamera) {
      return (sensorOrientation + deviceDegrees) % 360;
    } else {
      return (sensorOrientation - deviceDegrees + 360) % 360;
    }
  }

  /// Convertit degrés → CameraFrameRotation
  /// null = pas de rotation (0°)
  CameraFrameRotation? _degreesToRotation(int degrees) {
    switch (degrees) {
      case 90:  return CameraFrameRotation.cw90;
      case 180: return CameraFrameRotation.cw180;
      case 270: return CameraFrameRotation.cw270;
      default:  return null; // 0° = pas de rotation
    }
  }

  Future<List<Hand>> detectHands(
    CameraImage cameraImage,
    int rotationDegrees,
  ) async {
    if (!_initialized || _detector == null) return [];
    try {
      final rotation = _degreesToRotation(rotationDegrees);

      final hands = await _detector!.detectFromCameraImage(
        cameraImage,
        rotation: rotation,
        isBgra: false,
      );

      
      print(' Mains: ${hands.length}');
      return hands;
    } catch (e) {
      print(' detectHands: $e');
      return [];
    }
  }

  HandBoundingBox? getHandBoundingBox(
    Hand hand,
    int imageWidth,
    int imageHeight,
  ) {
    try {
      final bbox = hand.boundingBox;
      final double l = bbox.left.clamp(0.0, imageWidth.toDouble());
      final double t = bbox.top.clamp(0.0, imageHeight.toDouble());
      final double w = (bbox.right - bbox.left)
          .clamp(1.0, imageWidth.toDouble() - l);
      final double h = (bbox.bottom - bbox.top)
          .clamp(1.0, imageHeight.toDouble() - t);
      return HandBoundingBox(left: l, top: t, width: w, height: h);
    } catch (e) {
      print(' getHandBoundingBox: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    if (_initialized && _detector != null) {
      await _detector!.dispose();
      _initialized = false;
      _detector = null;
    }
  }
}