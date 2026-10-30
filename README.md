# 吃什么 · chishenme-map

> 按菜系、人均、评分筛选餐厅，地图上一眼看清。支持多城市切换、用户上传餐厅、补充评价。

单文件静态站点（`index.html`），无构建步骤、无依赖安装。

目前数据为空——六个城市都从零开始，等你来填。

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

三处改动，都在 `index.html` 里：

1. 准备数据数组，比如 `const DEMO_SZ = [...];`，每条餐厅不需要写 `city`（会自动挂上）。
2. 注册到 `CITY_DATA`：
   ```js
   const CITY_DATA = { "上海": DEMO_SH, "北京": DEMO_BJ, "杭州": DEMO_HZ, "成都": DEMO_CD, "深圳": DEMO_SZ };
   const CITY_VIEW = { ..., "深圳": { center: [22.5431, 114.0579], zoom: 13 } };
   const CITY_ABBR = { ..., "深圳": "深" };   // 左上角印章的字
   ```
3. 把 `DEMO_SZ` 也拼进 `const DEMO = [].concat(...)`。

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

### 配置高德 key（强烈建议）

不配也能用，但免费源对中文餐厅的覆盖有限，很多小店搜不到。

1. https://console.amap.com 注册，完成个人实名认证
2. 控制台 → 应用管理 → 创建新应用 → 添加 Key，服务平台选 **Web服务**
3. 把 key 填进 index.html：

```js
const AMAP_KEY = "你的key";
```

填上就自动走高德，代码不用改。个人开发者免费额度 5000 次/天。

> 高德返回的是 GCJ-02 坐标，代码里已经统一转成 WGS-84 再存，混用会导致点位偏移几百米。
## 已知限制

- 目前没有任何内置餐厅，所有内容都来自用户添加。
- 底图用高德瓦片直连（免 key），仅适合原型；正式运营需申请高德开放平台 key 并绑定域名。
- 数据只存在各自浏览器本地，不同人之间不互通。要多人共享需要接后端（Supabase / 微信云开发）。
- 市中心点位做了网格聚簇，算法在 `drawMarkers()` 里，迁到小程序可以直接复用。

## 后续计划

1. 接真实数据：高德 POI 搜索 API + 菜系映射表
2. 接后端：让上传和评价多端同步
3. 迁小程序：用 uni-app，地图页按 `map` 组件重写
