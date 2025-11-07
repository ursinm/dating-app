import 'package:flutter/material.dart';
import 'package:dating_app/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Помощь'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Как пользоваться приложением',
            items: [
              'Зарегистрируйтесь или войдите в свой аккаунт',
              'Заполните профиль: добавьте фото, укажите возраст и описание',
              'Пройдите тест совместимости для лучшего подбора',
              'Свайпайте карточки вправо для лайка, влево для пропуска',
              'Когда ваши лайки совпадут, появится мэтч',
              'Начните общение с вашими мэтчами в чате',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Часто задаваемые вопросы',
            items: [
              'Как изменить профиль? → Зайдите в Профиль и нажмите на иконку редактирования',
              'Как удалить мэтч? → В разделе Мэтчи свайпните карточку влево',
              'Как удалить сообщение? → Долгое нажатие на сообщение в чате',
              'Как сменить пароль? → Войдите в систему и используйте "Забыли пароль?"',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Безопасность',
            items: [
              'Не передавайте личные данные незнакомым людям',
              'Сообщайте о подозрительном поведении',
              'Используйте надежный пароль',
              'Не переходите по подозрительным ссылкам',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Техническая поддержка',
            items: [
              'Email: support@datingapp.com',
              'Время работы: Пн-Пт, 9:00-18:00',
              'Мы отвечаем в течение 24 часов',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<String> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.purplePrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

