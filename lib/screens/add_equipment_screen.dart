import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/equipment_model.dart';
import '../widgets/custom_text_field.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 50,
      );
      if (images.isNotEmpty) {
        setState(() {
          // Max 3 images
          if (_selectedImages.length + images.length <= 3) {
            _selectedImages.addAll(images);
          } else {
            final remaining = 3 - _selectedImages.length;
            _selectedImages.addAll(images.take(remaining));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocale.get("error")}: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 50,
      );
      if (image != null && _selectedImages.length < 3) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocale.get("error")}: $e')),
        );
      }
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];
    for (var xfile in _selectedImages) {
      try {
        final bytes = await File(xfile.path).readAsBytes();
        base64Images.add(base64Encode(bytes));
      } catch (e) {
        debugPrint('Image encoding error: $e');
      }
    }
    return base64Images;
  }

  Future<void> _submitEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final t = appLocale;

      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final docRef = FirebaseFirestore.instance.collection('equipment').doc();

        List<String> imageData = [];
        if (_selectedImages.isNotEmpty) {
          imageData = await _convertImagesToBase64();
        }

        final equipment = Equipment(
          id: docRef.id,
          ownerId: userId,
          type: _typeController.text.trim(),
          price: double.parse(_priceController.text),
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          isAvailable: true,
          imageUrls: imageData,
        );

        await _firestoreService.addEquipment(equipment);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.get('equipment_added'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.get("error")}: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('add_new_equipment')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker section
              Text(t.get('add_photos'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('(${_selectedImages.length}/3)',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedImages.length < 3)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: Text(t.get('add_photos')),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImages();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Camera'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _takePhoto();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 36, color: Theme.of(context).primaryColor),
                              const SizedBox(height: 8),
                              Text(t.get('add_photos'),
                                style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(entry.value.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedImages.removeAt(entry.key));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: t.get('equipment_type'),
                hint: t.get('equipment_type_hint'),
                icon: Icons.agriculture,
                controller: _typeController,
                validator: (val) => val == null || val.isEmpty ? t.get('equipment_type') : null,
              ),

              CustomTextField(
                label: t.get('rental_price'),
                hint: 'e.g. 500',
                icon: Icons.attach_money,
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return t.get('rental_price');
                  if (double.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),

              CustomTextField(
                label: t.get('location'),
                hint: t.get('location_hint'),
                icon: Icons.location_on_outlined,
                controller: _locationController,
                validator: (val) => val == null || val.isEmpty ? t.get('location') : null,
              ),

              CustomTextField(
                label: t.get('description'),
                hint: t.get('description_hint'),
                icon: Icons.description_outlined,
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? t.get('description') : null,
              ),

              const SizedBox(height: 48),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitEquipment,
                      child: Text(t.get('add_equipment').toUpperCase()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
