import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://pjbbfuzrngioddawzste.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqYmJmdXpybmdpb2RkYXd6c3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NTU4ODIsImV4cCI6MjA3NjIzMTg4Mn0.xjxQ8hvPrS4GvQ4XkhaU_R8p8F9IQ3w5STej8RwYfZs';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const USER_ID = 4; // ID пользователя Амаль

async function clearUserAnswers() {
  console.log(`\n🗑️  Удаление всех ответов пользователя ID=${USER_ID}...\n`);

  try {
    // Получаем все ответы пользователя
    const { data: answers, error: fetchError } = await supabase
      .from('user_answers')
      .select('*')
      .eq('user_id', USER_ID);

    if (fetchError) {
      console.error('❌ Ошибка получения ответов:', fetchError);
      return;
    }

    if (!answers || answers.length === 0) {
      console.log('✅ У пользователя нет ответов для удаления');
      return;
    }

    console.log(`📊 Найдено ответов: ${answers.length}`);
    
    // Удаляем все ответы
    const { error: deleteError } = await supabase
      .from('user_answers')
      .delete()
      .eq('user_id', USER_ID);

    if (deleteError) {
      console.error('❌ Ошибка удаления:', deleteError);
      return;
    }

    console.log(`✅ Успешно удалено ${answers.length} ответов!`);
    console.log('\n💡 Теперь можете пройти тест заново в приложении.\n');

  } catch (error) {
    console.error('❌ Критическая ошибка:', error);
  }
}

clearUserAnswers();
