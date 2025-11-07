import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/storage_service.dart';
import 'home_navigation_screen.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  
  String _selectedGender = 'Мужской';
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) throw Exception('Пользователь не авторизован');

      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _storageService.uploadProfilePhoto(_selectedImage!, userId);
      }

      await _apiService.updateUser(userId, {
        'user_age': int.tryParse(_ageController.text),
        'user_gender': _selectedGender,
        'user_description': _descriptionController.text.trim(),
        if (photoUrl != null) 'user_photo_url': photoUrl,
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дополнительная информация'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
                (route) => false,
              );
            },
            child: const Text('Пропустить'),
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Фото профиля
                Center(
                  child: Stack(
                      children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.purpleLight,
                          shape: BoxShape.circle,
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.purplePrimary,
                              )
                            : null,
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.purplePrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                          ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Расскажите о себе',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                        ),
                
                const SizedBox(height: 32),
                
                // Возраст
                        TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Возраст',
                    hintText: 'Введите ваш возраст',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                    if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 18 || age > 100) {
                        return 'Введите возраст от 18 до 100';
                      }
                            }
                            return null;
                          },
                ),
                
                const SizedBox(height: 16),
                
              // Пол
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Пол',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),
                    DropdownMenuItem(value: 'Женский', child: Text('Женский')),
                    DropdownMenuItem(value: 'Другой', child: Text('Другой')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGender = value);
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Описание
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'О себе',
                    hintText: 'Расскажите о своих интересах и увлечениях...',
                    prefixIcon: Icon(Icons.edit_outlined),
                    alignLabelWithHint: true,
                              ),
                ),
                
                const SizedBox(height: 32),
                
                // Кнопка сохранения
                            ElevatedButton(
                  onPressed: _isLoading ? null : _saveInfo,
                              style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Сохранить'),
                              ),
                      ],
            ),
          ),
        ),
      ),
    );
  }
}
