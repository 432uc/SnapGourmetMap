import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import '../models/photo_spot.dart';
import 'edit_spot_screen.dart';

class PhotoListScreen extends StatefulWidget {
  const PhotoListScreen({super.key});

  @override
  State<PhotoListScreen> createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  Future<List<PhotoSpot>>? _photoSpotsFuture;
  final _keywordController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  int? _selectedRating;
  String? _selectedVisitCount;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    DBHelper.getData('categories').then((data) {
      if (mounted) {
        setState(() {
          _categories = data.map((item) => Category.fromMap(item)).toList();
        });
      }
    });
    _performSearch(); 
  }

  void _performSearch() {
    setState(() {
      _photoSpotsFuture = DBHelper.searchSpots(
        keyword: _keywordController.text,
        categoryId: _selectedCategory?.id,
        rating: _selectedRating,
        visitCount: _selectedVisitCount,
        minPrice: int.tryParse(_minPriceController.text),
        maxPrice: int.tryParse(_maxPriceController.text),
      );
    });
  }

  void _resetSearch() {
    _keywordController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedRating = null;
      _selectedVisitCount = null;
    });
    _performSearch();
  }

  Future<String> _getCategoryInfo(PhotoSpot spot) async {
    if (spot.categoryId == null) return 'No Category';
    String categoryName = '';
    String subCategoryName = '';
    final categoryData = await DBHelper.getDataWhere('categories', 'id = ?', [spot.categoryId!]);
    if (categoryData.isNotEmpty) categoryName = categoryData.first['name'] as String;
    if (spot.subCategoryId != null) {
      final subCategoryData = await DBHelper.getDataWhere('sub_categories', 'id = ?', [spot.subCategoryId!]);
      if (subCategoryData.isNotEmpty) subCategoryName = subCategoryData.first['name'] as String;
    }
    return subCategoryName.isEmpty ? categoryName : '$categoryName / $subCategoryName';
  }

  void _navigateToEditScreen(PhotoSpot spot) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => EditSpotScreen(photoSpot: spot)));
    _performSearch(); // Refresh the list with current filters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Photos')),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Search Filters'),
            initiallyExpanded: false, // Start collapsed
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    TextField(controller: _keywordController, decoration: const InputDecoration(labelText: 'Keyword (Shop, Order)', hintText: 'e.g., ramen, shio')),
                    DropdownButtonFormField<Category>(value: _selectedCategory, hint: const Text('Genre'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: (val) => setState(() => _selectedCategory = val)),
                    DropdownButtonFormField<int>(value: _selectedRating, hint: const Text('Min. Rating'), items: [1,2,3,4,5].map((r) => DropdownMenuItem(value: r, child: Text('★' * r))).toList(), onChanged: (val) => setState(() => _selectedRating = val)),
                    DropdownButtonFormField<String>(value: _selectedVisitCount, hint: const Text('Visit Count'), items: ['1 time', '2 times', '3+ times'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (val) => setState(() => _selectedVisitCount = val)),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _minPriceController, decoration: const InputDecoration(labelText: 'Min Price'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                        const SizedBox(width: 8), 
                        const Text('~'), 
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _maxPriceController, decoration: const InputDecoration(labelText: 'Max Price'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [ElevatedButton(onPressed: _resetSearch, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey), child: const Text('Reset')), const SizedBox(width: 8), ElevatedButton(onPressed: _performSearch, child: const Text('Search'))]),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: FutureBuilder<List<PhotoSpot>>(
              future: _photoSpotsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('An error occurred:\n\n${snapshot.error}', style: const TextStyle(color: Colors.red))));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No matching photos found.'));

                final spots = snapshot.data!;
                return ListView.builder(
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: Image.file(File(spot.imagePath), width: 100, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.error, size: 40)),
                        title: Text(spot.shopName ?? 'Spot #${spot.id}'),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (spot.rating != null) Text('★' * spot.rating!), FutureBuilder<String>(future: _getCategoryInfo(spot), builder: (context, catSnapshot) => Text(catSnapshot.data ?? 'Loading...'))]),
                        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _navigateToEditScreen(spot)),
                        onTap: () => Navigator.of(context).pop(spot),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
