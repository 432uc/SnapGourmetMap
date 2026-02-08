import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:exif/exif.dart' as exif;
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

  Future<void> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    final spots = dataList.map((item) => PhotoSpot.fromMap(item)).toList();
    
    final Set<Marker> newMarkers = {};
    for (final spot in spots) {
      // Add marker only if location data is valid.
      if (spot.latitude != null && spot.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(spot.id.toString()),
            position: spot.position,
            infoWindow: InfoWindow(title: spot.shopName ?? 'Spot #${spot.id}'),
            onTap: () => _showImageDialog(spot),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _markers = newMarkers);
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

  double? _convertDmsToDecimal(List<exif.Ratio>? dms, String? ref) {
    if (dms == null || dms.length != 3 || ref == null) return null;
    try {
      double degrees = dms[0].toDouble();
      double minutes = dms[1].toDouble();
      double seconds = dms[2].toDouble();
      double decimal = degrees + (minutes / 60) + (seconds / 3600);
      return (ref == 'S' || ref == 'W') ? -decimal : decimal;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image_picker.XFile? image = await image_picker.ImagePicker().pickImage(source: image_picker.ImageSource.gallery);
      if (image == null) return;

      final fileBytes = await image.readAsBytes();
      final exifData = await exif.readExifFromBytes(fileBytes);

      final latTag = exifData['GPS GPSLatitude'];
      final lonTag = exifData['GPS GPSLongitude'];
      final latRefTag = exifData['GPS GPSLatitudeRef'];
      final lonRefTag = exifData['GPS GPSLongitudeRef'];

      double? latitude;
      double? longitude;

      if (latTag != null && lonTag != null && latRefTag != null && lonRefTag != null) {
        latitude = _convertDmsToDecimal(latTag.values.toList().cast<exif.Ratio>(), latRefTag.toString());
        longitude = _convertDmsToDecimal(lonTag.values.toList().cast<exif.Ratio>(), lonRefTag.toString());
      }
      
      // Create a spot, possibly without location.
      final tempSpot = PhotoSpot(latitude: latitude, longitude: longitude, imagePath: image.path);

      if (!mounted) return;
      final newSpot = await Navigator.of(context).push<PhotoSpot>(
        MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: tempSpot)),
      );

      if (newSpot != null) {
        await _loadPhotoSpots();
        if (newSpot.latitude != null && newSpot.longitude != null) {
           mapController.animateCamera(CameraUpdate.newLatLng(newSpot.position));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing image: ${e.toString()}')));
    }
  }

  void _navigateAndAddNewSpot() async {
    final newSpot = await Navigator.push<PhotoSpot>(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
    if (newSpot != null) {
      await _loadPhotoSpots();
      if (newSpot.latitude != null && newSpot.longitude != null) {
        mapController.animateCamera(CameraUpdate.newLatLng(newSpot.position));
      }
    }
  }

  void _navigateToPhotoList() async {
    final selectedSpot = await Navigator.push<PhotoSpot>(context, MaterialPageRoute(builder: (context) => const PhotoListScreen()));
    if (selectedSpot != null && selectedSpot.latitude != null && selectedSpot.longitude != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(selectedSpot.position));
      mapController.showMarkerInfoWindow(MarkerId(selectedSpot.id.toString()));
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
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _pickFromGallery,
            tooltip: 'Import from Gallery',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _navigateToPhotoList,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => _loadPhotoSpots());
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(target: LatLng(35.944, 140.051), zoom: 15.0),
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
