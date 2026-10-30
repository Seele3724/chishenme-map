-- ============================================================
-- 吃什么 · 第一阶段数据库
-- 在 Supabase 控制台 → SQL Editor 里整段执行
-- ============================================================

-- 餐厅 ---------------------------------------------------------
create table if not exists public.restaurants (
  id          uuid primary key default gen_random_uuid(),
  poi_id      text,                          -- 高德 POI id，用来去重
  name        text not null,
  city        text not null,
  cuisine     text not null,
  price       int  not null check (price >= 0),
  addr        text,
  lat         double precision not null,
  lng         double precision not null,
  tags        text[] default '{}',
  device_id   text,                          -- 阶段一的轻量身份
  status      text not null default 'active',
  created_at  timestamptz not null default now()
);

-- 同一个高德 POI 只能有一条记录；手动选点（poi_id 为空）不受约束
create unique index if not exists restaurants_poi_uniq
  on public.restaurants (poi_id)
  where poi_id is not null;

create index if not exists restaurants_city_idx on public.restaurants (city, status);

-- 评价 ---------------------------------------------------------
create table if not exists public.reviews (
  id            uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  device_id     text not null,
  nickname      text,
  stars         int  not null check (stars between 1 and 5),
  body          text not null check (char_length(body) between 1 and 1000),
  status        text not null default 'active',
  created_at    timestamptz not null default now(),
  -- 一台设备对一家店只能写一条，防止自己刷自己的分
  unique (restaurant_id, device_id)
);

create index if not exists reviews_restaurant_idx on public.reviews (restaurant_id, status);

-- 行级权限 -----------------------------------------------------
-- 阶段一没有登录，靠 anon key 直接读写。这意味着：
-- 任何拿到 anon key 的人都能插入和删除数据，只适合种子期。
-- 上量之前必须接 Auth，把策略改成 auth.uid() 相关。

alter table public.restaurants enable row level security;
alter table public.reviews     enable row level security;

drop policy if exists "anon can read restaurants"   on public.restaurants;
drop policy if exists "anon can insert restaurants" on public.restaurants;
create policy "anon can read restaurants"
  on public.restaurants for select to anon using (status = 'active');
create policy "anon can insert restaurants"
  on public.restaurants for insert to anon with check (true);

drop policy if exists "anon can read reviews"   on public.reviews;
drop policy if exists "anon can insert reviews" on public.reviews;
drop policy if exists "anon can delete reviews" on public.reviews;
create policy "anon can read reviews"
  on public.reviews for select to anon using (status = 'active');
create policy "anon can insert reviews"
  on public.reviews for insert to anon with check (true);
create policy "anon can delete reviews"
  on public.reviews for delete to anon using (true);

-- 自检 ---------------------------------------------------------
-- 执行完跑一下，两个都应该返回 true
-- select relrowsecurity from pg_class where relname = 'restaurants';
-- select relrowsecurity from pg_class where relname = 'reviews';
