-- Server schema (Supabase Postgres). Only the daily leaderboard lives here;
-- everything else is on-device (see schema.local.sql). Access: Postgres RLS.
-- Inserts into daily_results go only through the submit-daily edge function
-- (service role), which re-checks the solution first.

create extension if not exists moddatetime;

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table daily_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  puzzle_date date not null,                 -- the player's local calendar date
  engine_version smallint not null,          -- daily generator version that made the board
  board_size smallint not null check (board_size between 5 and 10),
  time_ms integer not null check (time_ms > 0),
  mistakes smallint not null check (mistakes between 0 and 2),
  hidden boolean not null default false,     -- moderation: hide implausible times
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint one_result_per_day unique (user_id, puzzle_date)
);
create index daily_results_board on daily_results (puzzle_date, time_ms, created_at) where not hidden;
create index daily_results_user on daily_results (user_id);

create trigger profiles_updated_at before update on profiles
  for each row execute procedure moddatetime(updated_at);
create trigger daily_results_updated_at before update on daily_results
  for each row execute procedure moddatetime(updated_at);

-- Every new (anonymous) auth user gets a profile with a generated name.
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, display_name)
  values (new.id, 'Player ' || lpad((floor(random() * 10000))::int::text, 4, '0'));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute procedure handle_new_user();

alter table profiles enable row level security;
alter table daily_results enable row level security;

create policy "names are public" on profiles for select using (true);
create policy "rename yourself" on profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

create policy "leaderboard is public" on daily_results for select
  using (not hidden or user_id = auth.uid());
-- no insert/update/delete policies: writes happen in submit-daily only.

-- Top N for a date plus the caller's own row, ranked by time then submit order.
create function daily_leaderboard(p_date date, p_limit int default 50)
returns table (rank bigint, display_name text, time_ms integer, is_me boolean)
language sql stable security invoker set search_path = public as $$
  with ranked as (
    select r.user_id, p.display_name, r.time_ms,
           rank() over (order by r.time_ms, r.created_at) as rank
    from daily_results r join profiles p on p.id = r.user_id
    where r.puzzle_date = p_date and not r.hidden
  )
  select rank, display_name, time_ms, user_id = auth.uid()
  from ranked
  where rank <= p_limit or user_id = auth.uid()
  order by rank;
$$;
