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
    final spots = await DBHelper.searchSpots();
    
    final Set<Marker> newMarkers = {};
    for (final spot in spots) {
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
      builder: (context) {
        int currentIndex = 0;
        // Map index to rotation turns (0-3)
        Map<int, int> rotations = {};

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final allImages = spot.allImages;

            return AlertDialog(
              title: Text(spot.shopName ?? 'Spot #${spot.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (spot.rating != null) ...[
                      Text('Rating: ' + '★' * spot.rating!),
                      const SizedBox(height: 8),
                    ],
                    if (allImages.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<DateTime>(
                            key: ValueKey(allImages[currentIndex]), 
                            future: File(allImages[currentIndex]).lastModified(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final dt = snapshot.data!;
                                final dateStr =
                                    "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                return Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const SizedBox(height: 16); 
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_right, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setStateDialog(() {
                                rotations[currentIndex] = ((rotations[currentIndex] ?? 0) + 1) % 4;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    SizedBox(
                      height: 300,
                      width: double.maxFinite,
                      child: allImages.isNotEmpty
                          ? PageView.builder(
                              key: ValueKey(allImages.length), 
                              controller: PageController(initialPage: currentIndex),
                              itemCount: allImages.length,
                              onPageChanged: (index) {
                                setStateDialog(() {
                                  currentIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final file = File(allImages[index]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: RotatedBox(
                                    quarterTurns: rotations[index] ?? 0,
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.contain, // Fit contain is better when rotating
                                      errorBuilder: (c, o, s) =>
                                          const Center(child: Icon(Icons.error)),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Text("No images")),
                    ),
                    const SizedBox(height: 8),
                    if (allImages.length < 5)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photo'),
                        onPressed: () async {
                           final newImagePath = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const CameraScreen(returnPathOnly: true)));
                           if(newImagePath != null) {
                              final updatedImages = List<String>.from(spot.additionalImages)..add(newImagePath);
                              final updatedSpot = spot.copyWith(additionalImages: updatedImages);
                              await DBHelper.update('photo_spots', updatedSpot.toMap(), updatedSpot.id!);
                              setStateDialog(() {
                                spot = updatedSpot;
                              });
                              _loadPhotoSpots();
                           }
                        },
                      ),
                    const SizedBox(height: 8),
                    if (spot.notes != null && spot.notes!.isNotEmpty) Text(spot.notes!),
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
                  child: Text(allImages.length > 1 ? 'Delete Photo' : 'Delete Spot', style: const TextStyle(color: Colors.red)),
                  onPressed: () async {
                    if (allImages.length > 1) {
                      final confirm = await showDialog<bool>(context: context, builder: (ctx) => 
                        AlertDialog(
                          title: const Text('Delete Photo'),
                          content: const Text('Delete this photo?'),
                          actions: [ TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)), TextButton(child: const Text('Delete'), onPressed: () => Navigator.of(ctx).pop(true))]
                        ));
                      if(confirm == true) {
                        final newImages = List<String>.from(allImages)..removeAt(currentIndex);
                        final newSpot = spot.copyWith(imagePath: newImages.isNotEmpty ? newImages[0] : null, additionalImages: newImages.length > 1 ? newImages.sublist(1) : []);
                        await DBHelper.update('photo_spots', newSpot.toMap(), newSpot.id!);
                        setStateDialog(() {
                          spot = newSpot;
                        });
                        _loadPhotoSpots();
                      }
                    } else {
                       final confirm = await showDialog<bool>(context: context, builder: (ctx) => 
                        AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text('Delete "${spot.shopName ?? 'this spot'}"?'),
                          actions: [ TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)), TextButton(child: const Text('Delete'), onPressed: () => Navigator.of(ctx).pop(true))]
                        ));
                      if (confirm == true) {
                        if (mounted) Navigator.of(context).pop();
                        await DBHelper.delete('photo_spots', spot.id!);
                        _loadPhotoSpots();
                      }
                    }
                  },
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
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
      final List<image_picker.XFile> images = await image_picker.ImagePicker().pickMultiImage();
      if (images.isEmpty) return;

      final firstImage = images.first;
      final fileBytes = await firstImage.readAsBytes();
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
      
      final tempSpot = PhotoSpot(
        latitude: latitude, 
        longitude: longitude, 
        imagePath: firstImage.path,
        additionalImages: images.length > 1 ? images.skip(1).take(4).map((e) => e.path).toList() : [],
      );

      if (!mounted) return;
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: tempSpot)),
      );

      if (result == true) {
        await _loadPhotoSpots();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing image: ${e.toString()}')));
    }
  }

  void _navigateAndAddNewSpot() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
    if (result != null && mounted) {
      await _loadPhotoSpots();
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
