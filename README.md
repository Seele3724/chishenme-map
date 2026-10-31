# 吃什么 · chishenme-map

> 按菜系、人均、评分筛选餐厅，地图上一眼看清。支持多城市切换、用户上传餐厅、补充评价。

单文件静态站点（`index.html`），无构建步骤、无依赖安装。

目前数据为空——七个城市（上海、北京、南京、广州、深圳、杭州、成都）都从零开始，等你来填。

线上地址规划：`https://chishenme-map.pages.dev`

## 本地预览

直接双击 `index.html`，或在目录下起一个静态服务：

```bash
python -m http.server 8899
```

然后打开 http://localhost:8899

> 用 `file://` 打开也能跑，但 `localStorage` 在部分浏览器（如 Safari）的本地文件模式下受限，建议起服务或直接用线上地址。

## 目录

```
index.html    # 全部代码：结构 + 样式 + 逻辑 + 空的数据数组
README.md
```

## 部署

两种方式任选，仓库内容完全通用，不需要改代码。

### 方式 A：Cloudflare Pages（推荐）

1. 在 GitHub 建一个空仓库，名字用 `chishenme-map`（什么都不要勾选），把本目录推上去。
2. 打开 https://dash.cloudflare.com → Workers & Pages → Create → Pages → Connect to Git。
3. 选中这个仓库，构建配置全部留空：
   - Framework preset: `None`
   - Build command: 留空
   - Build output directory: `/`
4. 点 Save and Deploy，等十几秒，拿到 `https://chishenme-map.pages.dev`。

### 方式 B：Vercel

1. 同样先把仓库推到 GitHub。
2. 打开 https://vercel.com/new，Import 这个仓库。
3. Framework Preset 选 `Other`，Build 和 Output 都留空。
4. Deploy，拿到 `https://<项目名>.vercel.app`。

两个平台的免费额度对这个项目都绰绰有余（纯静态，几十 KB）。

## 更新版本

改完 `index.html` 后：

```bash
git add -A
git commit -m "改了什么"
git push
```

平台监听到 push 会自动重新部署，**地址不变**，一般十几秒后刷新就能看到新版本。

- Cloudflare Pages 和 Vercel 都会保留每次部署的构建记录，出问题可以一键回滚到上一版。
- Vercel 还会为每个分支生成独立的预览地址，可以先在手机上试，没问题再合并到主分支。

## 加一个城市

两处，都在 `index.html` 里：

1. 往 `CITIES` 数组里加名字（顺序就是城市横滑条上的顺序）。
2. 在 `CITY_VIEW` 里加中心点和初始缩放：`"深圳": { center: [22.5431, 114.0579], zoom: 11 }`。

`CITY_DATA` 会自动补空数组，`CITY_ABBR` 没写就用城市名的第一个字，所以不加也不会报错。

如果想内置一批餐厅数据，再准备一个 `const DEMO_SZ = [...]` 数组、写进 `CITY_DATA`，并拼进 `const DEMO = [].concat(...)`。

城市按钮、标题、图例、菜系筛选会自动跟着变（菜系筛选只列当前城市实际有的）。

> 城市是一等公民，不做「一张全国图」：跨城市的点凑在同一张图上会糊成一团，而且评分在不同城市之间本来就没有可比性。

## 数据说明

- 餐厅数据写在 `index.html` 里，按城市分成 `DEMO_SH` / `DEMO_BJ` / `DEMO_HZ` / `DEMO_CD` 四个数组，**目前都是空的**。字段格式在数组上方有注释说明。
- 用户添加的餐厅存在 `localStorage` 的 `shmap.custom.v1`，评价存在 `shmap.reviews.v1`。
- **数据是按域名隔离的**：换域名（比如从 `xxx.pages.dev` 换成自己的域名）用户数据不会跟过去，会显示为空。所以域名定了就别再换。


## 地点搜索

两个地方用到地理编码：添加餐厅时按店名自动定位，以及按目的地筛选 5 公里内的店。

代码走**多源链式回退**，前一个没结果或挂掉就换下一个：

1. **高德 POI 搜索**（需要 key，国内最准）
2. **Photon**（photon.komoot.io，免 key，支持 CORS，中文可用）
3. **Nominatim**（OSM，免 key，境外访问不稳定）

挂掉两次的服务会被熔断，本页后续不再尝试，避免每次搜索都等超时。

### 高德 key

已经配置好了，两个 key 都在 `index.html` 顶部的常量里：

| 常量 | 平台类型 | 用途 |
|---|---|---|
| `AMAP_JS_KEY` | Web端 (JS API) | 地图渲染（JSAPI 2.0） |
| `AMAP_SECURITY` | 安全密钥 | 配合 JSAPI 使用，必须挂到 `window._AMapSecurityConfig` |
| `AMAP_KEY` | Web服务 | POI 搜索、地理编码（JSONP 调用） |

`AMAP_KEY` 留空时会自动退到 Photon / Nominatim 免费源，但中文小店覆盖差很多。

> **安全提醒**：这两个前端 key 会随页面源码公开，这是设计如此。但要去 高德控制台 → 对应 Key → 设置 里绑定域名白名单（`chishenme-map.pages.dev`），防止被别人拿去刷额度。

> **坐标系**：高德返回 GCJ-02，站内统一存 WGS-84，所有入口和出口都做了转换。百度导航另需 BD-09，在 `gcj2bd` 里再转一次。
## 接后端（第一阶段：数据共享）

现在默认是**本机模式**：数据存在浏览器 localStorage 里，别人打开是空地图。

要让所有人看到同一份数据，接 Supabase（免费，5 分钟）：

### 1. 建项目

https://supabase.com 注册 → New project → 记下两个值（Settings → API）：

- **Project URL**，形如 `https://abcdefghijk.supabase.co`
- **anon public** key（`anon` `public` 那一栏，不是 service_role）

### 2. 建表

打开 SQL Editor，把 [`supabase/schema.sql`](supabase/schema.sql) 整段粘进去执行。

### 3. 填进 index.html

文件顶部两个常量：

```js
const SUPABASE_URL  = "https://abcdefghijk.supabase.co";
const SUPABASE_ANON = "填 anon public key";
```

填完就自动切到云端模式，不需要改别的代码。

### 两种模式的区别

|  | 本机模式（默认） | 云端模式 |
|---|---|---|
| 数据在哪 | 各自浏览器 | Supabase Postgres |
| 别人能看到吗 | 看不到 | 能看到 |
| 换设备 | 丢 | 还在 |
| 去重 | 无 | 按高德 POI id 唯一 |

`SUPABASE_URL` 留空时自动退回本机模式，所以线上不会因为没配而白屏。

### 阶段一的限制（重要）

- **没有登录**，身份是一台设备一个随机 id。清缓存等于换人。
- **没有鉴权**：拿到 anon key 的人理论上能插入和删除任意数据。只适合种子期小范围试用，**别大力传播**。
- **没有审核**：文字和图片都没过滤。
- 每次打开会拉全量数据，几千条以内没问题，再往上要改成按视野加载。

上量之前要做第二阶段：接 Auth、把 RLS 策略改成基于 `auth.uid()`、加内容审核。
### 评价配图

再跑一次 [`supabase/migration-photos.sql`](supabase/migration-photos.sql)，它会：

- 给 `reviews` 加 `photos text[]` 列
- 建一个公开读取的 `review-photos` 存储桶
- 开匿名上传权限

前端会自动把图片压到长边 1400px、JPEG 0.82 再上传，单条评价最多 3 张、单张上限 15MB。

**没跑这个 SQL 的话**，评价能写但带图会失败（提示「图片上传失败，检查存储桶是否建好」），文字评价不受影响。
## 已知限制

- 目前没有任何内置餐厅，所有内容都来自用户添加。
- 底图用高德 JSAPI 2.0 矢量渲染，需网络加载 webapi.amap.com；离线或加载失败时降级为纯列表模式。
- 默认本机模式，数据不互通；填了 Supabase 配置后才会共享。
- 市中心点位做了网格聚簇，算法在 `drawMarkers()` 里，迁到小程序可以直接复用。

## 后续计划

1. 接真实数据：高德 POI 搜索 API + 菜系映射表
2. 接后端：让上传和评价多端同步
3. 迁小程序：用 uni-app，地图页按 `map` 组件重写
