import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Настройки уведомлений
  bool _messageNotifications = true;
  bool _matchNotifications = true;
  bool _likeNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Базовые настройки
  bool _showOnlineStatus = true;
  bool _allowProfileViews = true;
  int _maxDistance = 50; // км
  int _ageRangeMin = 18;
  int _ageRangeMax = 100;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _matchNotifications = prefs.getBool('match_notifications') ?? true;
      _likeNotifications = prefs.getBool('like_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _showOnlineStatus = prefs.getBool('show_online_status') ?? true;
      _allowProfileViews = prefs.getBool('allow_profile_views') ?? true;
      _maxDistance = prefs.getInt('max_distance') ?? 50;
      _ageRangeMin = prefs.getInt('age_range_min') ?? 18;
      _ageRangeMax = prefs.getInt('age_range_max') ?? 100;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Уведомления
            _buildSectionTitle('Уведомления'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTelegramSwitchTile(
                    icon: Icons.message_outlined,
                    title: 'Уведомления о сообщениях',
                    subtitle: 'Получать уведомления о новых сообщениях',
                    value: _messageNotifications,
                    onChanged: (value) {
                      setState(() => _messageNotifications = value);
                      _saveSetting('message_notifications', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSwitchTile(
                    icon: Icons.favorite_outline,
                    title: 'Уведомления о мэтчах',
                    subtitle: 'Получать уведомления о новых мэтчах',
                    value: _matchNotifications,
                    onChanged: (value) {
                      setState(() => _matchNotifications = value);
                      _saveSetting('match_notifications', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSwitchTile(
                    icon: Icons.thumb_up_outlined,
                    title: 'Уведомления о лайках',
                    subtitle: 'Получать уведомления о новых лайках',
                    value: _likeNotifications,
                    onChanged: (value) {
                      setState(() => _likeNotifications = value);
                      _saveSetting('like_notifications', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSwitchTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Звук',
                    subtitle: 'Воспроизводить звук при уведомлениях',
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      _saveSetting('sound_enabled', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSwitchTile(
                    icon: Icons.vibration_outlined,
                    title: 'Вибрация',
                    subtitle: 'Вибрация при уведомлениях',
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() => _vibrationEnabled = value);
                      _saveSetting('vibration_enabled', value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Приватность
            _buildSectionTitle('Приватность'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTelegramSwitchTile(
                    icon: Icons.visibility_outlined,
                    title: 'Показывать статус онлайн',
                    subtitle: 'Другие пользователи видят, когда вы онлайн',
                    value: _showOnlineStatus,
                    onChanged: (value) {
                      setState(() => _showOnlineStatus = value);
                      _saveSetting('show_online_status', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSwitchTile(
                    icon: Icons.person_outline,
                    title: 'Разрешить просмотр профиля',
                    subtitle: 'Другие пользователи могут просматривать ваш профиль',
                    value: _allowProfileViews,
                    onChanged: (value) {
                      setState(() => _allowProfileViews = value);
                      _saveSetting('allow_profile_views', value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Фильтры поиска
            _buildSectionTitle('Фильтры поиска'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTelegramSliderTile(
                    icon: Icons.location_on_outlined,
                    title: 'Максимальное расстояние',
                    subtitle: '$_maxDistance км',
                    value: _maxDistance.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() => _maxDistance = value.toInt());
                      _saveSetting('max_distance', value.toInt());
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramRangeTile(
                    icon: Icons.cake_outlined,
                    title: 'Возраст',
                    subtitle: 'От $_ageRangeMin до $_ageRangeMax лет',
                    minValue: _ageRangeMin.toDouble(),
                    maxValue: _ageRangeMax.toDouble(),
                    onChanged: (min, max) {
                      setState(() {
                        _ageRangeMin = min.toInt();
                        _ageRangeMax = max.toInt();
                      });
                      _saveSetting('age_range_min', min.toInt());
                      _saveSetting('age_range_max', max.toInt());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // О приложении
            _buildSectionTitle('О приложении'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTelegramInfoTile(
                    icon: Icons.info_outline,
                    title: 'Версия',
                    value: '1.0.0',
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Политика конфиденциальности',
                    onTap: () {
                      // TODO: Открыть политику конфиденциальности
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Политика конфиденциальности')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildTelegramSettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Условия использования',
                    onTap: () {
                      // TODO: Открыть условия использования
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Условия использования')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTelegramSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.purplePrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTelegramSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: AppTheme.purplePrimary,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTelegramRangeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double minValue,
    required double maxValue,
    required Function(double, double) onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
            ),
          ),
          RangeSlider(
            values: RangeValues(minValue, maxValue),
            min: 18,
            max: 100,
            divisions: 82,
            onChanged: (values) {
              onChanged(values.start, values.end);
            },
            activeColor: AppTheme.purplePrimary,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTelegramInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.textGrey,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTelegramSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textGrey,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

