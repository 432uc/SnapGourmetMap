import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/photo_spot.dart';
import 'edit_spot_screen.dart';

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
    _refreshPhotoSpots();
  }

  void _refreshPhotoSpots() {
    setState(() {
        _photoSpotsFuture = _loadPhotoSpots();
    });
  }

  Future<List<PhotoSpot>> _loadPhotoSpots() async {
    final dataList = await DBHelper.getData('photo_spots');
    // Sort by id descending to show newest first
    dataList.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return dataList.map((item) => PhotoSpot.fromMap(item)).toList();
  }

  Future<String> _getCategoryInfo(PhotoSpot spot) async {
    if (spot.categoryId == null) return 'No Category';
    String categoryName = '';
    String subCategoryName = '';
    final categoryData = await DBHelper.getDataWhere('categories', 'id = ?', [spot.categoryId!]);
    if (categoryData.isNotEmpty) {
      categoryName = categoryData.first['name'] as String;
    }
    if (spot.subCategoryId != null) {
      final subCategoryData = await DBHelper.getDataWhere('sub_categories', 'id = ?', [spot.subCategoryId!]);
      if (subCategoryData.isNotEmpty) {
        subCategoryName = subCategoryData.first['name'] as String;
      }
    }
    return subCategoryName.isEmpty ? categoryName : '$categoryName / $subCategoryName';
  }

  void _navigateToEditScreen(PhotoSpot spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: spot)),
    );
    _refreshPhotoSpots();
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
                  leading: Image.file(File(spot.imagePath), width: 100, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.error)),
                  title: Text(spot.shopName ?? 'Spot #${spot.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (spot.rating != null) Text('★' * spot.rating!),
                      FutureBuilder<String>(
                        future: _getCategoryInfo(spot),
                        builder: (context, catSnapshot) {
                          return Text(catSnapshot.data ?? 'Loading...');
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEditScreen(spot),
                  ),
                  onTap: () => Navigator.of(context).pop(spot),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
