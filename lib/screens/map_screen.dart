import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../helpers/db_helper.dart';
import '../models/photo_spot.dart';
import 'camera_screen.dart';
import 'photo_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadPhotoSpots();
  }

  Future<void> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    final spots = dataList
        .map(
          (item) => PhotoSpot(
            id: item['id'],
            latitude: item['latitude'],
            longitude: item['longitude'],
            imagePath: item['imagePath'],
          ),
        )
        .toList();

    for (final spot in spots) {
      _addMarker(spot);
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

  void _addMarker(PhotoSpot spot) {
      final marker = Marker(
        markerId: MarkerId(spot.id.toString()),
        position: spot.position,
        onTap: () {
          _showImageDialog(spot.imagePath);
        },
      );
      setState(() {
          _markers.add(marker);
      });
  }

  void _navigateAndAddNewSpot() async {
    final newSpot = await Navigator.push<PhotoSpot>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (newSpot != null) {
      _addMarker(newSpot);
      mapController.animateCamera(CameraUpdate.newLatLng(newSpot.position));
    }
  }

  void _navigateToPhotoList() async {
    final selectedSpot = await Navigator.push<PhotoSpot>(
      context,
      MaterialPageRoute(builder: (context) => const PhotoListScreen()),
    );

    if (selectedSpot != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(selectedSpot.position));
      _showImageDialog(selectedSpot.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap GourmetLog'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _navigateToPhotoList,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(35.944, 140.051), // Initial camera position
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddNewSpot,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
