-- ============================================================
-- 删除餐厅（只能删自己添加的）
-- 依赖 migration-review-photo-cleanup.sql
--
-- 删除餐厅会连带删掉它下面的评价（外键 on delete cascade），
-- 所以先把这个餐厅所有评价的图片路径收集出来，登记到 photo_deletions，
-- 前端拿到后逐个删，和删评价那套一致。
-- ============================================================

create or replace function public.delete_own_restaurant(p_id uuid, p_device text)
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

  if not exists (
    select 1 from public.restaurants
     where id = p_id and device_id = p_device
  ) then
    return null;                       -- 不是自己加的
  end if;

  -- 收集该店所有评价里的图片
  select coalesce(array_agg(x), '{}') into ph
    from public.reviews rv
    cross join lateral unnest(coalesce(rv.photos, '{}')) as x
   where rv.restaurant_id = p_id;

  delete from public.restaurants where id = p_id and device_id = p_device;
  get diagnostics n = row_count;
  if n = 0 then
    return null;
  end if;

  -- 登记可删路径，前端随后真正删掉这些文件
  insert into public.photo_deletions (path)
  select substring(u from position('/review-photos/' in u) + length('/review-photos/'))
    from unnest(ph) as u
   where position('/review-photos/' in u) > 0
  on conflict (path) do nothing;

  return ph;
end;
$$;

revoke all on function public.delete_own_restaurant(uuid, text) from public;
grant execute on function public.delete_own_restaurant(uuid, text) to anon;

-- 自检：
-- select public.delete_own_restaurant('<uuid>', '<device>');  -- 返回图片数组或 null
