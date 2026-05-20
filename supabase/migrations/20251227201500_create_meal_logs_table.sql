-- Create meal_logs table
create table public.meal_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  meal_name text,
  calories int,
  proteins int,
  carbs int,
  fats int,
  ingredients text[],
  is_safe boolean,
  danger_ingredients text[],
  image_path text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.meal_logs enable row level security;

-- Policies
create policy "Users can view their own meal logs."
  on meal_logs for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own meal logs."
  on meal_logs for insert
  with check ( auth.uid() = user_id );
