-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  username text,
  avatar_url text,
  license_type text DEFAULT 'B'::text,
  is_verified boolean DEFAULT false,
  verified_until timestamp with time zone, -- NULL = lifetime access

  current_level integer DEFAULT 1,
  daily_streak integer DEFAULT 0,
  last_study_date timestamp with time zone,
  total_quizzes_taken integer DEFAULT 0,
  average_score numeric DEFAULT 0.0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'user'::text,
  xp integer DEFAULT 0,
  email text,
  admin_pin_hash text,
  admin_pin_failed_attempts integer NOT NULL DEFAULT 0,
  admin_pin_locked_until timestamp with time zone,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.categories (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  color_hex text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.topics (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT topics_pkey PRIMARY KEY (id),
  CONSTRAINT topics_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);
CREATE TABLE public.subtopics (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  topic_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subtopics_pkey PRIMARY KEY (id),
  CONSTRAINT subtopics_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.questions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  subtopic_id bigint,
  text_it text NOT NULL,
  text_en text,
  text_bn text,
  image_url text,
  is_true boolean NOT NULL,
  explanation_it text,
  explanation_en text,
  explanation_bn text,
  difficulty_level integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  explanation_audio_url text,
  audio_it_url text,
  audio_en_url text,
  audio_bn_url text,
  CONSTRAINT questions_pkey PRIMARY KEY (id),
  CONSTRAINT questions_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id)
);
CREATE TABLE public.quiz_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  mode USER-DEFINED NOT NULL,
  total_questions integer DEFAULT 30,
  errors_count integer,
  is_passed boolean,
  duration_seconds integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.quiz_answers (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  session_id uuid NOT NULL,
  user_id uuid NOT NULL,
  question_id bigint NOT NULL,
  selected_true boolean NOT NULL,
  is_correct boolean NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_answers_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_answers_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.quiz_sessions(id),
  CONSTRAINT quiz_answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT quiz_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id)
);
CREATE TABLE public.theory_chapters_prev (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  related_quiz_topic_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT theory_chapters_prev_pkey PRIMARY KEY (id),
  CONSTRAINT theory_chapters_related_quiz_topic_id_fkey FOREIGN KEY (related_quiz_topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.theory_cards_prev (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  chapter_id bigint,
  title_it text,
  title_en text,
  title_bn text,
  text_it text NOT NULL,
  text_en text,
  text_bn text,
  image_url text,
  display_order integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  subtopic_id bigint,
  CONSTRAINT theory_cards_prev_pkey PRIMARY KEY (id),
  CONSTRAINT theory_cards_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.theory_chapters_prev(id),
  CONSTRAINT theory_cards_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id)
);
CREATE TABLE public.video_categories (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT video_categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.videos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id bigint,
  title_it text NOT NULL,
  title_en text,
  title_bn text,
  youtube_url text NOT NULL,
  duration_minutes integer,
  thumbnail_url text,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  is_live_class boolean DEFAULT false,
  class_date date DEFAULT CURRENT_DATE,
  CONSTRAINT videos_pkey PRIMARY KEY (id),
  CONSTRAINT videos_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.video_categories(id)
);
CREATE TABLE public.theory_chapters (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  related_quiz_topic_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT theory_chapters_pkey PRIMARY KEY (id),
  CONSTRAINT theory_chapters_duplicate_related_quiz_topic_id_fkey FOREIGN KEY (related_quiz_topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.theory_cards (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  chapter_id bigint,
  title_it text,
  title_en text,
  title_bn text,
  text_it text NOT NULL,
  text_en text,
  text_bn text,
  image_url text,
  display_order integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  subtopic_id bigint,
  audio_explanation_url text,
  audio_it_url text,
  audio_en_url text,
  audio_bn_url text,
  CONSTRAINT theory_cards_pkey PRIMARY KEY (id),
  CONSTRAINT theory_cards_duplicate_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id),
  CONSTRAINT theory_cards_duplicate_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.theory_chapters(id)
);
CREATE TABLE public.vocabulary (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  word_it text NOT NULL,
  translation_en text NOT NULL,
  translation_bn text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vocabulary_pkey PRIMARY KEY (id)
);
CREATE TABLE public.homework_sets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  created_by uuid,
  question_count integer DEFAULT 0,
  time_limit_minutes integer DEFAULT 20,
  start_at timestamp with time zone,
  end_at timestamp with time zone,
  status USER-DEFINED DEFAULT 'draft'::homework_status,
  shuffle_questions boolean DEFAULT true,
  shuffle_answers boolean DEFAULT true,
  retry_allowed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT homework_sets_pkey PRIMARY KEY (id),
  CONSTRAINT homework_sets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.homework_questions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  homework_id uuid,
  question_id bigint,
  order_index integer DEFAULT 0,
  CONSTRAINT homework_questions_pkey PRIMARY KEY (id),
  CONSTRAINT homework_questions_homework_id_fkey FOREIGN KEY (homework_id) REFERENCES public.homework_sets(id),
  CONSTRAINT homework_questions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id)
);
CREATE TABLE public.homework_scores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  homework_id uuid,
  user_id uuid,
  session_id uuid,
  score numeric DEFAULT 0.0,
  correct_count integer DEFAULT 0,
  wrong_count integer DEFAULT 0,
  unanswered_count integer DEFAULT 0,
  time_taken_seconds integer NOT NULL,
  submitted_at timestamp with time zone DEFAULT now(),
  CONSTRAINT homework_scores_pkey PRIMARY KEY (id),
  CONSTRAINT homework_scores_homework_id_fkey FOREIGN KEY (homework_id) REFERENCES public.homework_sets(id),
  CONSTRAINT homework_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT homework_scores_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.quiz_sessions(id)
);



