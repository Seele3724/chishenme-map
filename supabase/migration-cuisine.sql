-- ============================================================
-- 菜系改名迁移
-- 只有在「之前已经加过云南菜 / 咖啡甜品 的店」时才需要执行；
-- 库里还没这些数据的话，跑不跑都一样（0 rows affected）。
-- 在 Supabase 控制台 → SQL Editor 里执行。
-- ============================================================

update public.restaurants
   set cuisine = '云贵菜'
 where cuisine = '云南菜';

-- 咖啡甜品拆成了 奶茶咖啡 + 甜品蛋糕，历史数据统一落到 奶茶咖啡
update public.restaurants
   set cuisine = '奶茶咖啡'
 where cuisine = '咖啡甜品';

-- 核对：下面两条应该返回 0
-- select count(*) from public.restaurants where cuisine = '云南菜';
-- select count(*) from public.restaurants where cuisine = '咖啡甜品';
