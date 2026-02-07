import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'camera_screen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? imagePath;

  const MapScreen({super.key, this.initialPosition, this.imagePath});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null && widget.imagePath != null) {
      _addMarker(widget.initialPosition!, widget.imagePath!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.file(File(imagePath)),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _addMarker(LatLng position, String imagePath) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          onTap: () {
            _showImageDialog(imagePath);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap GourmetLog'),
        backgroundColor: Colors.orange,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.initialPosition ?? const LatLng(35.944, 140.051),
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
