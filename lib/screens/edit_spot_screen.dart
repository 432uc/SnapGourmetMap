import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/db_helper.dart';
import '../models/category.dart';
import '../models/sub_category.dart';
import '../models/photo_spot.dart';
import '../models/order_item.dart';
import 'camera_screen.dart';

class EditSpotScreen extends StatefulWidget {
  final PhotoSpot photoSpot;

  const EditSpotScreen({super.key, required this.photoSpot});

  @override
  State<EditSpotScreen> createState() => _EditSpotScreenState();
}

class _EditSpotScreenState extends State<EditSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _notesController;
  
  // Image management
  List<String> _currentImages = [];

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  int? _selectedRating;
  String? _selectedVisitCount;
  List<OrderItem> _orders = [];

  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.photoSpot.shopName);
    _notesController = TextEditingController(text: widget.photoSpot.notes);
    _selectedRating = widget.photoSpot.rating;
    _selectedVisitCount = widget.photoSpot.visitCount;
    _orders = List.from(widget.photoSpot.orders);
    
    // Initialize image list
    _currentImages = widget.photoSpot.allImages;
    
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadCategories();
    if (widget.photoSpot.categoryId != null && _categories.any((c) => c.id == widget.photoSpot.categoryId)) {
      try {
        _selectedCategory = _categories.firstWhere((cat) => cat.id == widget.photoSpot.categoryId);
        await _loadSubCategories(widget.photoSpot.categoryId!);
        if (widget.photoSpot.subCategoryId != null && _subCategories.any((s) => s.id == widget.photoSpot.subCategoryId)) {
          _selectedSubCategory = _subCategories.firstWhere((sub) => sub.id == widget.photoSpot.subCategoryId);
        }
      } catch (e) {
        // Handle case where category might not exist anymore
        print('Error loading categories: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final categoriesData = await DBHelper.getData('categories');
    _categories = categoriesData.map((item) => Category.fromMap(item)).toList();
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final subCategoriesData = await DBHelper.getDataWhere('sub_categories', 'categoryId = ?', [categoryId]);
    _subCategories = subCategoriesData.map((item) => SubCategory.fromMap(item)).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_currentImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed.')));
      return;
    }
    try {
      String? imagePath;
      if (source == ImageSource.camera) {
        imagePath = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => const CameraScreen(returnPathOnly: true),
          ),
        );
      } else {
        final pickedFile = await ImagePicker().pickImage(source: source);
        imagePath = pickedFile?.path;
      }

      if (imagePath != null) {
        setState(() {
          _currentImages.add(imagePath!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _removeImage(int index) {
    if (_currentImages.length <= 1) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one image is required.')));
       return;
    }
    setState(() {
      _currentImages.removeAt(index);
    });
  }

  void _onCategoryChanged(Category? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedCategory = newCategory;
        _selectedSubCategory = null;
        _subCategories = [];
        _loadSubCategories(newCategory.id!);
      });
    }
  }

  void _addOrderItem() {
    setState(() {
      _orders.add(OrderItem());
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orders.removeAt(index);
    });
  }

  Future<void> _saveSpot() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_currentImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one image.')));
        return;
    }

    try {
      if (widget.photoSpot.latitude == null || widget.photoSpot.longitude == null) {
        throw Exception('Location data is missing. Cannot save spot.');
      }

      final spotToSave = PhotoSpot(
        id: widget.photoSpot.id,
        latitude: widget.photoSpot.latitude!,
        longitude: widget.photoSpot.longitude!,
        imagePath: _currentImages[0], // Main image
        additionalImages: _currentImages.length > 1 ? _currentImages.sublist(1) : [],
        categoryId: _selectedCategory?.id,
        subCategoryId: _selectedSubCategory?.id,
        shopName: _shopNameController.text,
        rating: _selectedRating,
        visitCount: _selectedVisitCount,
        notes: _notesController.text,
        orders: _orders,
        visitDate: widget.photoSpot.visitDate,
      );

      if (spotToSave.id != null) {
        await DBHelper.update('photo_spots', spotToSave.toMap(), spotToSave.id!);
        if (mounted) Navigator.of(context).pop();
      } else {
        final newId = await DBHelper.insert('photo_spots', spotToSave.toMap());
        if (newId > 0) {
            final results = await DBHelper.getDataWhere('photo_spots', 'id = ?', [newId]);
            if (results.isNotEmpty) {
                 final finalSpot = PhotoSpot.fromMap(results.first);
                 if (mounted) Navigator.of(context).pop(finalSpot);
            } else {
                 throw Exception('Failed to retrieve the newly saved spot.');
            }
        } else {
            throw Exception('Failed to save the spot to the database.');
        }
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving spot: ${e.toString()}'))
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photoSpot.id == null ? 'Add Spot Details' : 'Edit Spot Details'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveSpot)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 150,
                      child: ReorderableListView(
                        scrollDirection: Axis.horizontal,
                        onReorder: (int oldIndex, int newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final String item = _currentImages.removeAt(oldIndex);
                            _currentImages.insert(newIndex, item);
                          });
                        },
                        footer: _currentImages.length < 5
                            ? GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (ctx) => Wrap(
                                            children: [
                                              ListTile(
                                                  leading: const Icon(Icons.camera_alt),
                                                  title: const Text('Camera'),
                                                  onTap: () {
                                                    Navigator.pop(ctx);
                                                    _pickImage(ImageSource.camera);
                                                  }),
                                              ListTile(
                                                  leading: const Icon(Icons.photo_library),
                                                  title: const Text('Gallery'),
                                                  onTap: () {
                                                    Navigator.pop(ctx);
                                                    _pickImage(ImageSource.gallery);
                                                  }),
                                            ],
                                          ));
                                },
                                child: Container(
                                  width: 80,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.add_a_photo, size: 30),
                                ),
                              )
                            : null,
                        children: [
                          for (int index = 0; index < _currentImages.length; index++)
                            Container(
                              key: ValueKey(_currentImages[index]),
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(_currentImages[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) => Container(
                                          color: Colors.grey,
                                          child: const Icon(Icons.broken_image))),
                                  if (_currentImages.length > 1)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                            color: Colors.black54,
                                            child: const Icon(Icons.close,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(2),
                                      child: Text(
                                          index == 0 ? 'Main' : '#${index + 1}',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(controller: _shopNameController, maxLength: 50, decoration: const InputDecoration(labelText: 'Shop Name')),
                    DropdownButtonFormField<int>(value: _selectedRating, hint: const Text('Rating'), items: [1, 2, 3, 4, 5].map((r) => DropdownMenuItem(value: r, child: Text('★' * r))).toList(), onChanged: (val) => setState(() => _selectedRating = val)),
                    DropdownButtonFormField<String>(value: _selectedVisitCount, hint: const Text('Visit Count'), items: ['1 time', '2 times', '3+ times'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (val) => setState(() => _selectedVisitCount = val)),
                    DropdownButtonFormField<Category>(value: _selectedCategory, hint: const Text('Select Genre'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(), onChanged: _onCategoryChanged, decoration: const InputDecoration(labelText: 'Genre')),
                    DropdownButtonFormField<SubCategory>(value: _selectedSubCategory, hint: const Text('Select Taste/Details'), items: _subCategories.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(), onChanged: (val) => setState(() => _selectedSubCategory = val), decoration: const InputDecoration(labelText: 'Taste/Details')),
                    const SizedBox(height: 20),
                    Text('Orders', style: Theme.of(context).textTheme.titleLarge),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(child: TextFormField(initialValue: _orders[index].itemName, decoration: const InputDecoration(labelText: 'Item'), onChanged: (val) => _orders[index].itemName = val)),
                            const SizedBox(width: 8),
                            SizedBox(width: 100, child: TextFormField(initialValue: _orders[index].price?.toString() ?? '', decoration: const InputDecoration(labelText: 'Price', suffixText: 'yen'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (val) => _orders[index].price = int.tryParse(val))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeOrderItem(index)),
                          ],
                        );
                      },
                    ),
                    Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.add_circle), onPressed: _addOrderItem)),
                    TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
                  ],
                ),
              ),
            ),
    );
  }
   @override
  void dispose() {
    _shopNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
