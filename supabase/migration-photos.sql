-- ============================================================
-- 评价图片
-- 在 Supabase 控制台 → SQL Editor 执行
-- 依赖 migration-cuisine.sql 之后执行也可以，互不影响
-- ============================================================

-- 1. 评价表加一列，存图片的公开 URL
alter table public.reviews
  add column if not exists photos text[] not null default '{}';

-- 2. 建一个公开读取的存储桶
insert into storage.buckets (id, name, public)
values ('review-photos', 'review-photos', true)
on conflict (id) do update set public = true;

-- 3. 存储桶权限
-- 阶段一没有登录，只能放开 anon 上传。
-- 注意：这意味着任何拿到 anon key 的人都能往桶里传文件。
-- 上线前要换成 auth 策略，或加文件大小/频率限制。

drop policy if exists "review photos are public"  on storage.objects;
drop policy if exists "anon can upload review photos" on storage.objects;

create policy "review photos are public"
  on storage.objects for select
  using (bucket_id = 'review-photos');

create policy "anon can upload review photos"
  on storage.objects for insert to anon
  with check (bucket_id = 'review-photos');

-- 4. 自检：应该能查到一行
-- select id, name, public from storage.buckets where id = 'review-photos';
