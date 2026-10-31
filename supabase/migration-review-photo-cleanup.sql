-- ============================================================
-- 删评价时连图片一起删
-- 依赖 migration-review-delete.sql 之后执行
--
-- 思路：浏览器没有 service_role，删不了存储对象。
-- 所以让「已授权的删除请求」变成一张表：
--   1) RPC 先校验 device_id，删掉评价，再把这条评价的图片路径写进 photo_deletions
--   2) 存储桶的删除策略只允许删 photo_deletions 里列出的路径
--   3) 前端拿到路径后逐个删，删完把授权行也清掉
-- 这样 anon 依旧不能删别人的图，但能删自己刚被授权的那几张。
-- ============================================================

-- 1. 授权表
create table if not exists public.photo_deletions (
  path       text primary key,
  created_at timestamptz not null default now()
);

alter table public.photo_deletions enable row level security;

drop policy if exists "anon can read photo deletions"   on public.photo_deletions;
drop policy if exists "anon can delete photo deletions" on public.photo_deletions;

create policy "anon can read photo deletions"
  on public.photo_deletions for select to anon using (true);
create policy "anon can delete photo deletions"
  on public.photo_deletions for delete to anon using (true);

grant select, delete on public.photo_deletions to anon;

-- 2. 存储桶：只允许删授权表里有的对象
drop policy if exists "anon can delete authorized review photos" on storage.objects;
create policy "anon can delete authorized review photos"
  on storage.objects for delete to anon
  using (
    bucket_id = 'review-photos'
    and exists (select 1 from public.photo_deletions d where d.path = name)
  );

-- 3. 改函数：返回值从 boolean 换成 text[]（删掉的图片 URL 列表）
--    没权限 / 不存在都返回 null；返回空数组表示评价删了但没图
drop function if exists public.delete_own_review(uuid, text);

create or replace function public.delete_own_review(p_id uuid, p_device text)
returns text[]
language plpgsql
security definer
set search_path = public
as $$
declare
  ph text[];
  n  int;
begin
  if p_id is null or p_device is null or length(p_device) < 6 then
    return null;
  end if;

  select photos into ph
    from public.reviews
   where id = p_id and device_id = p_device;

  if not found then
    return null;                       -- 不是自己的，或已经没了
  end if;

  delete from public.reviews where id = p_id and device_id = p_device;
  get diagnostics n = row_count;
  if n = 0 then
    return null;
  end if;

  ph := coalesce(ph, '{}');

  -- 把图片路径登记成「可删」，前端随后就能删掉这些对象
  insert into public.photo_deletions (path)
  select substring(u from position('/review-photos/' in u) + length('/review-photos/'))
    from unnest(ph) as u
   where position('/review-photos/' in u) > 0
  on conflict (path) do nothing;

  return ph;
end;
$$;

revoke all on function public.delete_own_review(uuid, text) from public;
grant execute on function public.delete_own_review(uuid, text) to anon;

-- 自检：
-- select public.delete_own_review('<uuid>', '<device>');   -- 返回 URL 数组或 null
