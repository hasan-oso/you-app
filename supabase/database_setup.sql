-- YOU App Database Schema V2 (Launch Ready)

-- 1. Enable UUID Extension
create extension if not exists "uuid-ossp";

-- 2. Create Profiles Table (Public Profile Data)
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text,
  full_name text,
  avatar_path text default 'assets/avatars/m3.png',
  
  -- Metrics
  coins int default 30,
  xp int default 0,
  rank text default 'rank_beginner',
  
  -- Biometrics
  gender text default 'male',
  age int default 25,
  height numeric default 175.0,
  weight numeric default 75.0,
  bmr numeric default 0, -- FIXED: Added missing column
  daily_calories int default 2000, -- Often used with BMR
  activity_level text default 'moderate',
  goal_type text default 'maintain',
  onboarding_completed boolean default false,
  
  -- Health Config (Arrays)
  allergies text[] default '{}',
  diseases text[] default '{}',
  
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. Create Meal Logs Table
create table public.meal_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  
  meal_name text not null,
  calories int not null,
  protein int default 0,
  carbs int default 0,
  fats int default 0,
  weight_g int default 0,
  
  ingredients text[] default '{}',
  danger_ingredients text[] default '{}',
  is_safe boolean default true,
  
  image_path text, -- Cloud Storage Path or Local Reference
  
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 4. Create Workout Logs Table
create table public.workout_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  
  exercise_ids text[] default '{}', -- Stored as IDs for flexibility
  total_xp_earned int default 0,
  
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 5. Row Level Security (RLS) Policies
-- Enable RLS
alter table profiles enable row level security;
alter table meal_logs enable row level security;
alter table workout_logs enable row level security;

-- Policies for Profiles
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Policies for Meal Logs
create policy "Users can view own logs."
  on meal_logs for select
  using ( auth.uid() = user_id );

create policy "Users can insert own logs."
  on meal_logs for insert
  with check ( auth.uid() = user_id );

-- Policies for Workout Logs
create policy "Users can view own workouts."
  on workout_logs for select
  using ( auth.uid() = user_id );

create policy "Users can insert own workouts."
  on workout_logs for insert
  with check ( auth.uid() = user_id );

-- 6. Storage Buckets (Optional: Required if you use Storage)
-- insert into storage.buckets (id, name, public) values ('meal_images', 'meal_images', true);
-- create policy "Avatar images are publicly accessible." on storage.objects for select using ( bucket_id = 'meal_images' );
-- create policy "Anyone can upload an avatar." on storage.objects for insert with check ( bucket_id = 'meal_images' );

-- 7. Auto-Profile Trigger (Optional but Recommended)
-- Automatically creates a profile entry when a new user signs up via Auth
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, full_name, username, avatar_path)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'full_name', 'assets/avatars/m3.png');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

