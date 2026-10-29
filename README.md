# 美食地图

按菜系、人均、评分筛选餐厅，地图上一眼看清。支持多城市切换、用户上传餐厅、补充评价。

单文件静态站点（`index.html`），无构建步骤、无依赖安装。

当前收录：上海 38 家、北京 10 家、杭州 8 家、成都 8 家（均为演示数据）。

## 本地预览

直接双击 `index.html`，或在目录下起一个静态服务：

```bash
python -m http.server 8899
```

然后打开 http://localhost:8899

> 用 `file://` 打开也能跑，但 `localStorage` 在部分浏览器（如 Safari）的本地文件模式下受限，建议起服务或直接用线上地址。

## 目录

```
index.html    # 全部代码：结构 + 样式 + 逻辑 + 演示数据
README.md
```

## 部署

两种方式任选，仓库内容完全通用，不需要改代码。

### 方式 A：Cloudflare Pages（推荐）

1. 在 GitHub 建一个仓库（可以设为 Private），把本目录推上去。
2. 打开 https://dash.cloudflare.com → Workers & Pages → Create → Pages → Connect to Git。
3. 选中这个仓库，构建配置全部留空：
   - Framework preset: `None`
   - Build command: 留空
   - Build output directory: `/`
4. 点 Save and Deploy，等十几秒，拿到 `https://<项目名>.pages.dev`。

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

- 演示数据写死在 `index.html` 里，按城市分成 `DEMO_SH` / `DEMO_BJ` / `DEMO_HZ` / `DEMO_CD` 四个数组。
- 用户添加的餐厅存在 `localStorage` 的 `shmap.custom.v1`，评价存在 `shmap.reviews.v1`。
- **数据是按域名隔离的**：换域名（比如从 `xxx.pages.dev` 换成自己的域名）用户数据不会跟过去，会显示为空。所以域名定了就别再换。

## 已知限制

- 评分、人均、评价数、评价内容均为演示数据，非真实点评，页面内有标注。
- 底图用高德瓦片直连（免 key），仅适合原型；正式运营需申请高德开放平台 key 并绑定域名。
- 数据只存在各自浏览器本地，不同人之间不互通。要多人共享需要接后端（Supabase / 微信云开发）。
- 市中心点位做了网格聚簇，算法在 `drawMarkers()` 里，迁到小程序可以直接复用。

## 后续计划

1. 接真实数据：高德 POI 搜索 API + 菜系映射表
2. 接后端：让上传和评价多端同步
3. 迁小程序：用 uni-app，地图页按 `map` 组件重写
