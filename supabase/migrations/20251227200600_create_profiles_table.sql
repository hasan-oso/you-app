-- Create profiles table
create table public.profiles (
  id uuid default gen_random_uuid() primary key,
  name text,
  gender text check (gender in ('male', 'female')),
  allergies text[],
  diseases text[],
  xp int default 0,
  coins int default 100,
  avatar_path text
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Create policies (Updated for Anonymous Flow)
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Enable insert for anonymous users"
  on profiles for insert
  with check ( true );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );
