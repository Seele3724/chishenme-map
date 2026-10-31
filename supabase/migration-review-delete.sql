-- ============================================================
-- 只允许发布者删除自己的评价
-- 在 Supabase 控制台 → SQL Editor 执行（或用管理接口跑）
--
-- 阶段一没有登录，身份是「设备 id」（reviews.device_id）。
-- 所以这里把删除收敛成一个函数：设备 id 对得上才删得掉。
-- 直接 DELETE 的口子全部关掉。
-- ============================================================

-- 1. 去掉「任何 anon 都能删任何评价」的旧策略
drop policy if exists "anon can delete reviews" on public.reviews;

-- 2. 唯一入口：函数内部校验 device_id
create or replace function public.delete_own_review(p_id uuid, p_device text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  if p_id is null or p_device is null or length(p_device) < 6 then
    return false;
  end if;

  delete from public.reviews
   where id = p_id
     and device_id = p_device;

  get diagnostics n = row_count;
  return n > 0;
end;
$$;

-- 3. 只给 anon 执行权限，不给人看函数体以外的权限
revoke all on function public.delete_own_review(uuid, text) from public;
grant execute on function public.delete_own_review(uuid, text) to anon;

-- 自检：
-- select public.delete_own_review('<some-uuid>', 'not-my-device');  -- 应返回 false
