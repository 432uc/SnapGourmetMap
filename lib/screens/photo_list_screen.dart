import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/photo_spot.dart';

class PhotoListScreen extends StatefulWidget {
  const PhotoListScreen({super.key});

  @override
  State<PhotoListScreen> createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  late Future<List<PhotoSpot>> _photoSpotsFuture;

  @override
  void initState() {
    super.initState();
    _photoSpotsFuture = _loadPhotoSpots();
  }

  Future<List<PhotoSpot>> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    return dataList
        .map((item) => PhotoSpot(
              id: item['id'],
              latitude: item['latitude'],
              longitude: item['longitude'],
              imagePath: item['imagePath'],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Photos'),
      ),
      body: FutureBuilder<List<PhotoSpot>>(
        future: _photoSpotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No photos yet!'));
          }

          final spots = snapshot.data!;
          return ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.file(
                    File(spot.imagePath),
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text('Spot ${spot.id}'),
                  subtitle: Text('Lat: ${spot.latitude}, Lng: ${spot.longitude}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
