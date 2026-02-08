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
  Set<Marker> _markers = {}; // Not final

  @override
  void initState() {
    super.initState();
    _loadPhotoSpots();
  }

  // Unified and efficient method to load and display all markers.
  Future<void> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    final spots = dataList.map((item) => PhotoSpot.fromMap(item)).toList();
    
    final Set<Marker> newMarkers = {};
    for (final spot in spots) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(spot.id.toString()),
          position: spot.position,
          infoWindow: InfoWindow(title: spot.shopName ?? 'Spot #${spot.id}'),
          onTap: () {
            _showImageDialog(spot);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showImageDialog(PhotoSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spot.shopName ?? 'Spot #${spot.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (spot.rating != null) Text('Rating: ' + '★' * spot.rating!),
              const SizedBox(height: 8),
              Image.file(File(spot.imagePath), errorBuilder: (c, o, s) => const Icon(Icons.error)),
              const SizedBox(height: 8),
              if(spot.notes != null && spot.notes!.isNotEmpty) Text(spot.notes!),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: spot)),
              ).then((_) => _loadPhotoSpots());
            },
          ),
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // _addMarker is no longer needed.

  void _navigateAndAddNewSpot() async {
    final newSpot = await Navigator.push<PhotoSpot>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (newSpot != null) {
      await _loadPhotoSpots(); 
      mapController.animateCamera(CameraUpdate.newLatLng(newSpot.position));
    }
  }

  void _navigateToPhotoList() {
    // Simplified: Just navigate. The list screen will fetch its own fresh data.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhotoListScreen()),
    );
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
