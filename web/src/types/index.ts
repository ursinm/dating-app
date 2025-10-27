export interface User {
  user_id: number;
  user_name: string;
  user_email: string;
  user_age: number | null;
  user_gender: string | null;
  user_description: string | null;
  user_photo_url: string | null;
  is_online?: boolean; // Онлайн ли пользователь
  last_seen?: string; // Последнее время активности
  created_at?: string;
  updated_at?: string;
}

export interface Question {
  question_id: number;
  question_text: string;
  created_at?: string;
}

export interface AnswerOpinion {
  opinion_id: number;
  opinion_text: string;
  question_id: number;
  created_at?: string;
}

export interface UserAnswer {
  answer_id: number;
  answer_user: {
    user_id: number;
  };
  answer_question: {
    question_id: number;
  };
  answer_opinion: {
    opinion_id: number;
  };
  created_at?: string;
}

export interface Like {
  like_id: number;
  like_from_user: {
    user_id: number;
  };
  like_to_user: {
    user_id: number;
  };
  created_at?: string;
}

export interface Match {
  match_id: number;
  match_first_user: {
    user_id: number;
  };
  match_second_user: {
    user_id: number;
  };
  created_at?: string;
}

export interface Chat {
  chat_id: number;
  chat_first_user: {
    user_id: number;
  };
  chat_second_user: {
    user_id: number;
  };
  created_at?: string;
}

export interface Message {
  message_id: number;
  message_chat: {
    chat_id: number;
  };
  message_sender: {
    user_id: number;
  };
  message_text: string;
  message_type?: 'text' | 'image' | 'voice'; // Тип сообщения
  file_url?: string | null; // URL файла (фото или голосовое)
  voice_duration?: number | null; // Длительность голосового сообщения в секундах
  reply_to?: number | null; // ID сообщения на которое отвечают
  reply_to_message?: Message | null; // Само сообщение на которое отвечают (для UI)
  is_deleted?: boolean; // Помечено как удаленное
  created_at?: string;
}

export interface UserDTO {
  user_id?: number;
  user_name: string;
  user_email: string;
  user_age: number | null;
  user_gender: string | null;
  user_description: string | null;
  user_photo_url: string | null;
}

export interface LikeDTO {
  from_user_id: number;
  to_user_id: number;
}

export interface MatchDTO {
  match_first_user_id: number;
  match_second_user_id: number;
}

export interface ChatDTO {
  chat_first_user_id: number;
  chat_second_user_id: number;
}

export interface MessageDTO {
  chat_id: number;
  sender_id: number;
  message_text: string;
  message_type?: 'text' | 'image' | 'voice';
  file_url?: string | null;
  voice_duration?: number | null;
  reply_to?: number | null; // ID сообщения на которое отвечают
}

export interface UserAnswerDTO {
  user_id: number;
  question_id: number;
  opinion_id: number;
}
