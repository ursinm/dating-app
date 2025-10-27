import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://pjbbfuzrngioddawzste.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqYmJmdXpybmdpb2RkYXd6c3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NTU4ODIsImV4cCI6MjA3NjIzMTg4Mn0.xjxQ8hvPrS4GvQ4XkhaU_R8p8F9IQ3w5STej8RwYfZs';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testDatabase() {
  console.log('🔍 Проверка подключения к базе данных...\n');

  try {
    // Проверка подключения
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);

    if (usersError) {
      console.error('❌ Ошибка при получении пользователей:', usersError.message);
      console.error('Детали:', usersError);
      return;
    }

    console.log('✅ Подключение к базе данных успешно!');
    console.log(`📊 Найдено пользователей: ${users.length}\n`);

    if (users.length > 0) {
      console.log('👥 Последние зарегистрированные пользователи:');
      users.forEach((user, index) => {
        console.log(`\n${index + 1}. Пользователь ID: ${user.user_id}`);
        console.log(`   Имя: ${user.user_name}`);
        console.log(`   Телефон: ${user.user_phone}`);
        console.log(`   Возраст: ${user.user_age}`);
        console.log(`   Пол: ${user.user_gender}`);
        console.log(`   Пароль (хэш): ${user.user_password ? '✓ Есть' : '✗ Нет'}`);
        console.log(`   Создан: ${new Date(user.created_at).toLocaleString('ru-RU')}`);
      });
    } else {
      console.log('⚠️  В базе данных нет пользователей');
    }

    // Проверка других таблиц
    console.log('\n\n📋 Проверка других таблиц:');
    
    const tables = ['questions', 'answer_opinions', 'user_answers', 'likes', 'matches', 'chats', 'messages'];
    
    for (const table of tables) {
      const { count, error } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      if (error) {
        console.log(`   ${table}: ❌ Ошибка - ${error.message}`);
      } else {
        console.log(`   ${table}: ✓ ${count} записей`);
      }
    }

  } catch (error) {
    console.error('❌ Критическая ошибка:', error);
  }
}

testDatabase();
