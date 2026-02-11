import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import '../models/photo_spot.dart';
import 'edit_spot_screen.dart';

class CameraScreen extends StatefulWidget {
  final bool returnPathOnly;

  const CameraScreen({super.key, this.returnPathOnly = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeControllerFuture ??= _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await [Permission.camera, Permission.location].request();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    return _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      if (_controller == null || !_controller!.value.isInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Camera is not available.')),
          );
        }
        return;
      }

      final image = await _controller!.takePicture();
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // EXIFにGPS情報を書き込む
      final exif = await Exif.fromPath(image.path);
      await exif.writeAttributes({
        'GPSLatitude': position.latitude,
        'GPSLatitudeRef': position.latitude >= 0 ? 'N' : 'S',
        'GPSLongitude': position.longitude,
        'GPSLongitudeRef': position.longitude >= 0 ? 'E' : 'W',
      });
      await exif.close();

      // ギャラリーに保存
      try {
        await Gal.putImage(image.path);
      } catch (e) {
        debugPrint('ギャラリー保存エラー: $e');
      }

      if (!mounted) return;

      if (widget.returnPathOnly) {
        // パスのみを返却する（追加撮影用）
        Navigator.of(context).pop(image.path);
      } else {
        // 新規スポット登録へ
        final tempSpot = PhotoSpot(
          latitude: position.latitude,
          longitude: position.longitude,
          imagePath: image.path,
        );

        final finalSpot = await Navigator.of(context).push<PhotoSpot>(
          MaterialPageRoute(
              builder: (context) => EditSpotScreen(photoSpot: tempSpot)),
        );

        if (finalSpot != null && mounted) {
          Navigator.of(context).pop(finalSpot);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller == null) {
              return const Center(child: Text('No camera found'));
            }
            return CameraPreview(_controller!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
