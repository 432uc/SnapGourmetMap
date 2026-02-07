import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart'; // Will use later for current location

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  /* 
   Initial coordinates: 35.944, 140.051 (Toride Station area)
  */
  final LatLng _center = const LatLng(35.944, 140.051);

  final Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _markers.add(
        const Marker(
          markerId: MarkerId('sample_1'),
          position: LatLng(35.944, 140.051),
          infoWindow: InfoWindow(
            title: 'Sample Spot',
            snippet: 'This is a sample gourmet spot.',
          ),
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
          target: _center,
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: true, // Requires permissions in AndroidManifest.xml
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for adding a new spot
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
