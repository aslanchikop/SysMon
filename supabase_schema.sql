-- 🐾 Animabase Schema: Базовая структура БД для Animora

-- 1. ТАБЛИЦА ПРОФИЛЕЙ (Связана с auth.users в Supabase)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  phone text unique,
  full_name text,
  avatar_url text,
  role text check (role in ('owner', 'provider', 'admin')) default 'owner',
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- Включаем RLS (Row Level Security)
alter table public.profiles enable row level security;

-- Создаем политики доступа для profiles
create policy "Профили могут просматривать все авторизованные пользователи"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Пользователи могут редактировать только свой профиль"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id);


-- 2. ТАБЛИЦА ПРОВАЙДЕРОВ (Ветклиники, груминг-салоны)
create table public.providers (
  id uuid default gen_random_uuid() primary key,
  profile_id uuid references public.profiles(id) on delete cascade not null,
  business_name text not null,
  type text check (type in ('vet_clinic', 'grooming', 'hotel', 'walking')) not null,
  description text,
  address text not null,
  lat float,
  lng float,
  phone text,
  photos text[],
  working_hours jsonb, -- Расписание работы
  rating float default 5.0,
  review_count int default 0,
  verified boolean default false,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.providers enable row level security;

-- Политики доступа для providers
create policy "Провайдеров могут просматривать все пользователи"
  on public.providers for select
  to authenticated
  using (true);

create policy "Провайдеры могут редактировать только свой профиль бизнеса"
  on public.providers for all
  to authenticated
  using (profile_id = auth.uid());


-- 3. ТАБЛИЦА УСЛУГ (Связана с провайдерами)
create table public.services (
  id uuid default gen_random_uuid() primary key,
  provider_id uuid references public.providers(id) on delete cascade not null,
  name text not null,
  description text,
  price int not null, -- В тенге
  duration_min int not null, -- Длительность услуги в минутах
  category text,
  active boolean default true,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.services enable row level security;

-- Политики доступа для services
create policy "Услуги могут просматривать все пользователи"
  on public.services for select
  to authenticated
  using (true);

create policy "Провайдеры могут управлять только своими услугами"
  on public.services for all
  to authenticated
  using (
    provider_id in (
      select id from public.providers where profile_id = auth.uid()
    )
  );


-- 4. ТАБЛИЦА ПИТОМЦЕВ
create table public.pets (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  species text check (species in ('dog', 'cat', 'bird', 'exotic')) not null,
  breed text,
  birth_date date,
  weight float,
  photo_url text,
  microchip_id text,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.pets enable row level security;

-- Политики доступа для pets
create policy "Владельцы видят только своих питомцев"
  on public.pets for all
  to authenticated
  using (owner_id = auth.uid());

create policy "Провайдеры видят питомцев, записанных к ним"
  on public.pets for select
  to authenticated
  using (
    exists (
      select 1 from public.bookings
      where bookings.pet_id = pets.id
        and bookings.provider_id in (
          select id from public.providers where profile_id = auth.uid()
        )
    )
  );


-- 5. ТАБЛИЦА БРОНИРОВАНИЙ (Записей на прием)
create table public.bookings (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references public.profiles(id) not null,
  provider_id uuid references public.providers(id) not null,
  pet_id uuid references public.pets(id) not null,
  service_id uuid references public.services(id) not null,
  booking_time timestamptz not null,
  status text check (status in ('pending', 'confirmed', 'completed', 'cancelled')) default 'pending',
  notes text,
  price int not null,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.bookings enable row level security;

-- Политики доступа для bookings
create policy "Владельцы видят свои бронирования"
  on public.bookings for select
  to authenticated
  using (owner_id = auth.uid());

create policy "Владельцы могут создавать бронирования"
  on public.bookings for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy "Провайдеры видят записи к ним"
  on public.bookings for select
  to authenticated
  using (
    provider_id in (
      select id from public.providers where profile_id = auth.uid()
    )
  );

create policy "Провайдеры могут обновлять статус записей к ним"
  on public.bookings for update
  to authenticated
  using (
    provider_id in (
      select id from public.providers where profile_id = auth.uid()
    )
  )
  with check (
    provider_id in (
      select id from public.providers where profile_id = auth.uid()
    )
  );


-- 🔄 АВТОМАТИЧЕСКОЕ СОЗДАНИЕ ПРОФИЛЯ ПРИ РЕГИСТРАЦИИ В AUTH
-- Функция-обработчик триггера
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, phone, full_name, avatar_url, role)
  values (
    new.id,
    new.phone,
    coalesce(new.raw_user_meta_data->>'full_name', 'Пользователь'),
    new.raw_user_meta_data->>'avatar_url',
    coalesce(new.raw_user_meta_data->>'role', 'owner')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Триггер
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
