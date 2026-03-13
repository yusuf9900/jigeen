import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Data for locations
  final Map<String, List<String>> _locations = {
    'Dakar': ['Dakar', 'Pikine', 'Guédiawaye', 'Rufisque', 'Bargny'],
    'Thiès': ['Thiès', 'Mbour', 'Tivaouane', 'Joal-Fadiouth'],
    'Diourbel': ['Diourbel', 'Touba', 'Mbacké'],
    'Saint-Louis': ['Saint-Louis', 'Richard-Toll', 'Dagana', 'Podor'],
    'Louga': ['Louga', 'Kébémer', 'Linguère'],
    'Kaolack': ['Kaolack', 'Nioro du Rip', 'Guinguinéo'],
     'Ziguinchor': ['Ziguinchor', 'Bignona', 'Oussouye', 'Cap Skirring'],
  };

  String? _selectedRegion;
  String? _selectedCommune;
  List<String> _communes = [];

  final List<String> _violenceTypes = [
    'Violence domestique',
    'Harcèlement de rue',
    'Cyber-harcèlement',
    'Violence psychologique',
    'Témoignage',
    'Autre',
  ];
  String? _selectedType;

  bool _isUrgent = false;
  bool _isAnonymous = false;
  bool _isLoading = false;
  File? _imageFile;

  final cloudinary = CloudinaryPublic('dnsjtdexy', 'Jigeen');

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow; // Re-throw the error to be caught by the calling function
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String imageUrl = '';
        if (_imageFile != null) {
          imageUrl = await _uploadImage(_imageFile!);
        }

        await FirebaseFirestore.instance.collection('reports').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'region': _selectedRegion,
          'commune': _selectedCommune,
          'location': '$_selectedCommune, $_selectedRegion', // Combined for easy display
          'type': _selectedType,
          'isUrgent': _isUrgent,
          'isAnonymous': _isAnonymous,
          'isTestimony': _selectedType == 'Témoignage',
          'timestamp': FieldValue.serverTimestamp(),
          'imagePath': imageUrl,
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('Error submitting report: $e'); // For debugging
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la soumission du signalement.'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Nouveau Signalement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Titre', labelStyle: TextStyle(color: Colors.white70)),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Veuillez entrer un titre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF2B2940),
                decoration: const InputDecoration(labelText: 'Type de violence', labelStyle: TextStyle(color: Colors.white70)),
                items: _violenceTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF2B2940),
                decoration: const InputDecoration(labelText: 'Région', labelStyle: TextStyle(color: Colors.white70)),
                items: _locations.keys.map((String region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRegion = newValue;
                    _communes = _locations[newValue]!;
                    _selectedCommune = null; // Reset commune when region changes
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner une région' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCommune,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF2B2940),
                decoration: InputDecoration(
                    labelText: 'Commune / Ville',
                    labelStyle: TextStyle(color: _selectedRegion == null ? Colors.grey : Colors.white70)),
                items: _communes.map((String commune) {
                  return DropdownMenuItem<String>(
                    value: commune,
                    child: Text(commune),
                  );
                }).toList(),
                onChanged: _selectedRegion == null ? null : (newValue) {
                  setState(() {
                    _selectedCommune = newValue;
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner une commune' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70)),
                maxLines: 5,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Veuillez entrer une description' : null,
              ),
              const SizedBox(height: 24),
              // Image picker
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2940),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: _imageFile == null
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white70),
                          label: const Text('Ajouter une photo', style: TextStyle(color: Colors.white70)),
                        ),
                      )
                    : GestureDetector(
                        onTap: _pickImage, // Allow re-picking the image
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Signalement Urgent', style: TextStyle(color: Colors.white)),
                value: _isUrgent,
                onChanged: (val) => setState(() => _isUrgent = val),
                activeColor: Colors.redAccent,
              ),
              SwitchListTile(
                title: const Text('Rester Anonyme', style: TextStyle(color: Colors.white)),
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val),
                activeColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Envoyer le Signalement', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
