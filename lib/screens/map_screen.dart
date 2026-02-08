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

  // Reverted to the simpler, stable version of loading spots.
  Future<void> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    final spots = dataList.map((item) => PhotoSpot.fromMap(item)).toList();
    
    setState(() {
      _markers.clear();
    });

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

  // Restored the simple _addMarker method.
  void _addMarker(PhotoSpot spot) {
    final marker = Marker(
      markerId: MarkerId(spot.id.toString()),
      position: spot.position,
      infoWindow: InfoWindow(title: spot.shopName ?? 'Spot #${spot.id}'),
      onTap: () {
        _showImageDialog(spot);
      },
    );
    setState(() {
      _markers.add(marker);
    });
  }

  // Reverted to use _addMarker for consistency.
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
          // Reverted: The visibility toggle button has been removed.
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // This line is added
    );
  }
}
