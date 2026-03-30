-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

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
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  username text,
  avatar_url text,
  license_type text DEFAULT 'B'::text,
  is_verified boolean DEFAULT false,
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
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
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
  CONSTRAINT questions_pkey PRIMARY KEY (id),
  CONSTRAINT questions_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id)
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
  CONSTRAINT theory_cards_pkey PRIMARY KEY (id),
  CONSTRAINT theory_cards_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.theory_chapters(id),
  CONSTRAINT theory_cards_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id)
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
  CONSTRAINT theory_chapters_related_quiz_topic_id_fkey FOREIGN KEY (related_quiz_topic_id) REFERENCES public.topics(id)
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
  CONSTRAINT videos_pkey PRIMARY KEY (id),
  CONSTRAINT videos_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.video_categories(id)
);