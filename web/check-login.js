import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://pjbbfuzrngioddawzste.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqYmJmdXpybmdpb2RkYXd6c3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NTU4ODIsImV4cCI6MjA3NjIzMTg4Mn0.xjxQ8hvPrS4GvQ4XkhaU_R8p8F9IQ3w5STej8RwYfZs';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkLogin(phone) {
  console.log(`\n🔍 Проверка логина для телефона: ${phone}\n`);

  try {
    const { data: users, error } = await supabase
      .from('users')
      .select('*')
      .eq('user_phone', phone);

    if (error) {
      console.error('❌ Ошибка при поиске пользователя:', error.message);
      return;
    }

    if (users.length === 0) {
      console.log('❌ Пользователь с таким номером НЕ НАЙДЕН');
      console.log('\n💡 Возможные причины:');
      console.log('   1. Номер введен неправильно');
      console.log('   2. Регистрация не завершена');
      console.log('   3. Проверьте формат номера (только цифры)\n');
      return;
    }

    console.log('✅ Пользователь найден!\n');
    const user = users[0];
    
    console.log('📋 Информация о пользователе:');
    console.log('   ID:', user.user_id);
    console.log('   Имя:', user.user_name);
    console.log('   Телефон:', user.user_phone);
    console.log('   Возраст:', user.user_age);
    console.log('   Пол:', user.user_gender);
    console.log('   Пароль установлен:', user.user_password ? '✓ Да' : '✗ Нет');
    console.log('   Длина пароля:', user.user_password ? user.user_password.length + ' символов' : '0');
    console.log('   Дата создания:', new Date(user.created_at).toLocaleString('ru-RU'));
    console.log('\n✅ Для входа используйте:');
    console.log('   Телефон:', user.user_phone);
    console.log('   Пароль: <тот, который вы указали при регистрации>');
    console.log('\n💡 Если не помните пароль, можете создать нового пользователя с другим номером.\n');

  } catch (error) {
    console.error('❌ Критическая ошибка:', error);
  }
}

// Проверяем для телефона Амаль
checkLogin('37525708191');
