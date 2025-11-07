import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/theme/app_theme.dart';
import 'package:dating_app/models/user_model.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:dating_app/services/api_service.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/screens/compatibility_test_screen.dart';
import 'package:dating_app/screens/help_screen.dart';
import 'package:dating_app/screens/about_screen.dart';
import 'package:dating_app/screens/settings_screen.dart';
import 'package:dating_app/utils/image_utils.dart';
import 'package:dating_app/widgets/optimized_image.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  int? _currentUserId;
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGender;
  File? _newPhoto;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      debugPrint('🔍 ProfileScreen: Загрузка профиля...');
      
      _currentUserId = await _authService.getCurrentUserId();
      debugPrint('👤 Current User ID: $_currentUserId');
      
      if (_currentUserId == null) {
        debugPrint('❌ User ID is null');
        // Пробуем получить по email из Firebase Auth
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          debugPrint('📧 Пробуем загрузить по email: ${firebaseUser.email}');
          final user = await _apiService.getUserByEmail(firebaseUser.email!);
          if (user != null) {
            debugPrint('✅ Пользователь найден по email');
            _currentUserId = user.userId;
            // Сохраняем userId для будущего использования
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', user.userId);
          }
        }
      }

      if (_currentUserId == null) {
        debugPrint('❌ Не удалось получить userId');
        setState(() {
          _isLoading = false;
          _currentUser = null;
        });
        return;
      }

      final user = await _apiService.getUserById(_currentUserId!);
      debugPrint('📊 Результат getUserById: ${user != null ? "найден" : "не найден"}');
      
      if (user == null) {
        debugPrint('⚠️ Пользователь не найден, возможно нужно создать профиль');
      }
      
      setState(() {
        _currentUser = user;
        _isLoading = false;
        
        // Заполняем контроллеры
        if (user != null) {
          _nameController.text = user.userName;
          _ageController.text = user.userAge?.toString() ?? '';
          _descriptionController.text = user.userDescription ?? '';
          _selectedGender = user.userGender;
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading profile: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _currentUser = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _newPhoto = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_newPhoto != null) {
        photoUrl = await _storageService.uploadProfilePhoto(_newPhoto!, _currentUserId!);
      }

      await _apiService.updateUser(_currentUserId!, {
        'user_name': _nameController.text.trim(),
        'user_age': int.tryParse(_ageController.text),
        'user_gender': _selectedGender,
        'user_description': _descriptionController.text.trim(),
        if (photoUrl != null) 'user_photo_url': photoUrl,
      });

      await _loadProfile();
      
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Профиль'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Пользователь не найден',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Попробуйте перезайти в аккаунт',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Выйти и войти заново'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textDark),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.purplePrimary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
        ],
      ),
      body: _isEditing ? _buildEditingView() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Градиентный хедер с аватаром
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purplePrimary,
                  AppTheme.purplePrimary.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    // Аватар с градиентом и тенью
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            AppTheme.purpleLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: (_currentUser!.userPhotoUrl != null &&
                                _currentUser!.userPhotoUrl!.isNotEmpty)
                            ? ImageUtils.isBase64Image(_currentUser!.userPhotoUrl)
                                ? Image(
                                    image: ImageUtils.getImageProvider(
                                        _currentUser!.userPhotoUrl)!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.purpleLight,
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppTheme.purplePrimary,
                                        ),
                                      );
                                    },
                                  )
                                : OptimizedImage(
                                    imageUrl: _currentUser!.userPhotoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      color: AppTheme.purpleLight,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.purplePrimary,
                                        ),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      color: AppTheme.purpleLight,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppTheme.purplePrimary,
                                      ),
                                    ),
                                  )
                            : Container(
                                color: AppTheme.purpleLight,
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppTheme.purplePrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Имя
                    Text(
                      _currentUser!.userName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentUser!.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Контент
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Информация о пользователе
                _buildSectionCard(
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.cake_outlined,
                        title: 'Возраст',
                        value: _currentUser!.userAge != null
                            ? '${_currentUser!.userAge} лет'
                            : 'Не указан',
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildInfoTile(
                        icon: Icons.wc_outlined,
                        title: 'Пол',
                        value: _currentUser!.userGender ?? 'Не указан',
                      ),
                      if (_currentUser!.userDescription != null &&
                          _currentUser!.userDescription!.isNotEmpty) ...[
                        const Divider(height: 1, indent: 72),
                        _buildInfoTile(
                          icon: Icons.info_outline,
                          title: 'О себе',
                          value: _currentUser!.userDescription!,
                          maxLines: 5,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Настройки
                _buildSectionCard(
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.assessment_outlined,
                        title: 'Пройдите тест совместимости',
                        subtitle: '10 вопросов для лучшего подбора',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CompatibilityTestScreen()),
                          );
                          if (result == true && mounted) {
                            _loadProfile();
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        icon: Icons.settings_outlined,
                        title: 'Настройки',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Помощь',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HelpScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'О приложении',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Кнопка выхода
                _buildSectionCard(
                  child: _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Выйти из аккаунта',
                    subtitle: 'Текущая сессия будет завершена',
                    onTap: _logout,
                    color: AppTheme.error,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.purpleLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.purplePrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.purplePrimary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.purplePrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppTheme.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? AppTheme.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Градиентный хедер с аватаром для редактирования
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purplePrimary,
                  AppTheme.purplePrimary.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    // Фото профиля с кнопкой камеры
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                AppTheme.purpleLight,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: _newPhoto != null
                                ? Image.file(
                                    _newPhoto!,
                                    fit: BoxFit.cover,
                                  )
                                : (_currentUser!.userPhotoUrl != null &&
                                        _currentUser!.userPhotoUrl!.isNotEmpty)
                                    ? ImageUtils.isBase64Image(_currentUser!.userPhotoUrl)
                                        ? Image(
                                            image: ImageUtils.getImageProvider(
                                                _currentUser!.userPhotoUrl)!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: AppTheme.purpleLight,
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 70,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          )
                                        : OptimizedImage(
                                            imageUrl: _currentUser!.userPhotoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: Container(
                                              color: AppTheme.purpleLight,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            errorWidget: Container(
                                              color: AppTheme.purpleLight,
                                              child: const Icon(
                                                Icons.person,
                                                size: 70,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                    : Container(
                                        color: AppTheme.purpleLight,
                                        child: const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white,
                                        ),
                                      ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.purplePrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Редактирование профиля',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Форма редактирования
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Форма редактирования
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Возраст',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Пол',
                          prefixIcon: Icon(Icons.wc_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Мужской', child: Text('Мужской')),
                          DropdownMenuItem(
                              value: 'Женский', child: Text('Женский')),
                          DropdownMenuItem(
                              value: 'Другой', child: Text('Другой')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'О себе',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Кнопки отмены и сохранения
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _newPhoto = null;
                            _loadProfile();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.purplePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
