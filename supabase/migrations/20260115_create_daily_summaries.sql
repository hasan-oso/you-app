-- 1. Create daily_summaries table
create table public.daily_summaries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  date date not null,
  total_calories int default 0,
  total_protein int default 0,
  total_carbs int default 0,
  total_fats int default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, date)
);

-- 2. Enable RLS
alter table public.daily_summaries enable row level security;

-- 3. Policy: Insert own data
create policy "Effective data entry"
on public.daily_summaries for insert
with check (auth.uid() = user_id);

-- 4. Policy: Select own data
create policy "Effective data selection"
on public.daily_summaries for select
using (auth.uid() = user_id);
