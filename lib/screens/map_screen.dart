import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../helpers/db_helper.dart';
import '../models/photo_spot.dart';
import 'camera_screen.dart';
import 'photo_list_screen.dart';
import 'settings_screen.dart';
import 'edit_spot_screen.dart';

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
    setState(() {
      _markers.clear();
    });
    final spots = dataList.map((item) => PhotoSpot.fromMap(item)).toList();

    for (final spot in spots) {
      _addMarker(spot);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showImageDialog(PhotoSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Image.file(File(spot.imagePath))],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: spot)),
              ).then((_) => _loadPhotoSpots());
            },
          ),
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
        _showImageDialog(spot);
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
      _showImageDialog(selectedSpot);
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadPhotoSpots());
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(35.944, 140.051),
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
