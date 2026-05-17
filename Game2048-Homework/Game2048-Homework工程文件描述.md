# HarmonyOS 2048 工程文件描述

## 一、工程简介

本次作业选择 `harmonyos-games` 作为基础开源工程，并以其中的 2048 小游戏作为主要分析对象。该工程是一个基于 HarmonyOS SDK 和 ArkTS 开发的小游戏集合项目，工程中包含 2048、变色方块、推箱子等游戏入口。

本次作业已完成基础工程导入、依赖同步、模拟器运行和基础运行效果录屏。基础运行效果视频位于：

```text
Game2048-Homework/videos/video1_base_run.mp4
````

本工程的核心特点是采用 HarmonyOS 应用常见的模块化结构，将应用入口、公共组件和具体游戏功能拆分到不同模块中，便于后续维护和功能扩展。

---

## 二、工程运行环境

* 开发工具：DevEco Studio
* 开发语言：ArkTS
* 运行平台：HarmonyOS 模拟器
* 运行设备：Huawei Phone 模拟器
* 基础工程目录：`Game2048-Homework/harmonyos-games`
* 主要分析功能：2048 数字合并游戏

工程配置中使用 HarmonyOS 运行环境，项目的主要模块包括 `entry`、`number` 和 `basic`。其中 `entry` 是应用入口模块，`number` 是 2048 数字游戏功能模块，`basic` 是公共基础模块。

---

## 三、工程总体目录结构

本次作业所使用的工程目录位于：

```text
Game2048-Homework/
└─ harmonyos-games/
   ├─ AppScope/
   ├─ commons/
   │  └─ basic/
   ├─ docs/
   │  └─ images/
   ├─ entry/
   ├─ features/
   │  └─ number/
   ├─ hvigor/
   ├─ build-profile.json5
   ├─ hvigorfile.ts
   ├─ oh-package.json5
   ├─ oh-package-lock.json5
   ├─ README.md
   └─ LICENSE
```

各目录和文件作用如下。

---

## 四、主要目录与文件说明

### 1. `AppScope/`

`AppScope` 是应用作用域目录，用于存放应用级别的配置与资源文件。该目录中的内容作用于整个应用，而不是某个单独页面或单独功能模块。

一般来说，`AppScope` 中会包含应用图标、应用名称、全局资源和应用级配置等内容。

---

### 2. `entry/`

`entry` 是工程的入口模块，也是应用启动后首先加载的模块。该模块负责应用主界面、页面路由以及对其他功能模块的调用。

在本工程中，`entry` 模块提供小游戏列表页面，用户可以从主页面选择进入 2048、变色方块、推箱子等不同游戏。

---

### 3. `entry/src/main/module.json5`

`module.json5` 是 `entry` 模块的配置文件，用于描述模块名称、模块类型、入口 Ability、支持设备类型、页面配置等内容。

该文件中可以看到：

* 模块名为 `entry`
* 模块类型为 `entry`
* 主入口为 `EntryAbility`
* 支持设备类型包括 phone、tablet、2in1
* 页面列表由 `main_pages.json` 管理

该文件决定了应用启动时从哪个 Ability 进入，以及该模块包含哪些页面。

---

### 4. `entry/src/main/ets/entryability/EntryAbility.ets`

`EntryAbility.ets` 是应用入口 Ability 文件。HarmonyOS 应用启动时，会通过该 Ability 创建窗口、加载页面并进入应用主界面。

它相当于整个应用运行流程的入口控制文件，负责应用生命周期相关逻辑。

---

### 5. `entry/src/main/ets/pages/`

`pages` 目录用于存放应用页面文件。本工程中该目录包含以下主要页面：

```text
About.ets
ColorBlocks.ets
Index.ets
NumberGame.ets
```

各页面作用如下：

| 文件                | 作用           |
| ----------------- | ------------ |
| `Index.ets`       | 应用首页，展示小游戏列表 |
| `NumberGame.ets`  | 2048 游戏入口页面  |
| `ColorBlocks.ets` | 变色方块游戏页面     |
| `About.ets`       | 关于页面         |

其中，`Index.ets` 是用户进入应用后看到的主界面，页面中通过列表展示不同小游戏入口。用户点击“2048”后，会跳转到 `NumberGame.ets` 页面。

---

### 6. `entry/src/main/ets/pages/Index.ets`

`Index.ets` 是工程首页页面文件。该页面定义了一个小游戏列表，并使用路由跳转进入不同游戏页面。

页面中定义了 `GameItem` 类，用于描述每个游戏入口的信息，包括：

* 游戏名称
* 游戏图标
* 跳转路径

在游戏列表中，2048 对应的跳转页面是：

```text
pages/NumberGame
```

因此，用户点击首页中的 2048 游戏入口后，会进入 2048 游戏页面。

---

### 7. `entry/src/main/ets/pages/NumberGame.ets`

`NumberGame.ets` 是 2048 游戏的页面入口文件。该文件本身并不直接实现全部游戏逻辑，而是引入 `features/number` 模块中的 `NumberGameComp` 组件，并在页面中进行显示。

其核心作用可以概括为：

```text
NumberGame.ets 负责页面承载
NumberGameComp 负责具体 2048 游戏界面和逻辑
```

这种写法体现了页面入口与功能组件分离的设计思路。

---

### 8. `entry/src/main/resources/`

`resources` 目录用于存放 `entry` 模块所需的资源文件，例如图片、颜色、字符串、页面配置等。

其中比较重要的目录包括：

```text
resources/base/element
resources/base/media
resources/base/profile
```

各目录作用如下：

| 目录        | 作用               |
| --------- | ---------------- |
| `element` | 存放字符串、颜色等基础资源    |
| `media`   | 存放图片、图标等媒体资源     |
| `profile` | 存放页面配置、备份配置等配置文件 |

---

### 9. `entry/src/main/resources/base/profile/main_pages.json`

`main_pages.json` 是页面配置文件，用于声明当前模块中可访问的页面列表。

本工程中配置的页面包括：

```text
pages/Index
pages/About
pages/NumberGame
pages/ColorBlocks
```

因此，应用可以通过路由跳转到这些页面。

---

### 10. `features/number/`

`features/number` 是 2048 数字游戏的功能模块，也是本次作业分析的重点模块。

该模块独立于 `entry` 模块，主要负责 2048 游戏组件、游戏逻辑、数据处理和状态管理。`entry` 模块通过导入该模块中的组件来显示 2048 游戏。

该模块目录结构大致如下：

```text
features/number/
├─ src/
│  └─ main/
│     └─ ets/
│        ├─ numberability/
│        ├─ services/
│        └─ views/
├─ BuildProfile.ets
├─ Index.ets
├─ build-profile.json5
├─ hvigorfile.ts
├─ oh-package.json5
└─ obfuscation-rules.txt
```

---

### 11. `features/number/Index.ets`

`Index.ets` 是 `number` 模块的对外导出文件。它将模块内部的 `NumberGameComp` 组件导出，供其他模块引用。

在本工程中，`entry/src/main/ets/pages/NumberGame.ets` 就是通过该导出入口使用 2048 游戏组件。

---

### 12. `features/number/oh-package.json5`

`oh-package.json5` 是 `number` 模块的包配置文件，用于声明模块名称、版本、入口文件和依赖关系。

其中，`number` 模块名称为：

```text
@mygames/number
```

入口文件为：

```text
Index.ets
```

同时，该模块依赖公共基础模块：

```text
@mygames/basic
```

这说明 2048 游戏模块并不是完全孤立的，而是复用了工程中的公共基础组件。

---

### 13. `features/number/src/main/ets/views/NumberGameComp.ets`

`NumberGameComp.ets` 是 2048 游戏的核心界面组件文件，是本次工程分析中最重要的代码文件之一。

该文件主要负责：

* 显示 2048 游戏标题
* 显示“新游戏”按钮
* 显示当前分数
* 显示最高分
* 绘制 4×4 游戏棋盘
* 响应用户上下左右滑动手势
* 根据游戏状态显示胜利或失败界面

组件中使用了多个状态变量，例如：

```text
won：是否胜利
lost：是否失败
board：当前棋盘对象
score：当前分数
bestScore：最高分
boardCellsArray：棋盘格子数据
```

这些状态变量会影响页面显示。当用户滑动棋盘时，组件会调用 `Board.move()` 方法更新棋盘数据，并通过 `updateGameStatus()` 更新分数、胜利状态和失败状态。

---

### 14. `features/number/src/main/ets/services/helper.ets`

`helper.ets` 是 2048 游戏的核心逻辑文件，主要定义了 `Tile` 和 `Board` 两个类。

#### `Tile` 类

`Tile` 表示棋盘中的一个数字方块，主要属性包括：

* `value`：方块数值
* `row`：当前行位置
* `column`：当前列位置
* `oldRow`：移动前行位置
* `oldColumn`：移动前列位置
* `mergedInto`：合并目标方块
* `id`：方块编号

`Tile` 类主要用于记录单个方块的位置、数值和移动状态。

#### `Board` 类

`Board` 表示整个 2048 棋盘，是游戏逻辑的核心类。它主要负责：

* 初始化 4×4 棋盘
* 随机生成新方块
* 处理方块移动
* 处理相同数字合并
* 计算当前分数
* 判断是否合成 2048
* 判断游戏是否失败

其中，`move(direction)` 方法用于处理用户滑动方向。方向参数含义为：

```text
0：向左
1：向上
2：向右
3：向下
```

为了复用向左移动的合并逻辑，代码中通过旋转棋盘的方式，将不同方向的移动统一转换为 `moveLeft()` 处理。这种写法减少了重复代码。

---

### 15. `features/number/src/main/ets/services/PreferencesUtil.ets`

`PreferencesUtil.ets` 用于封装首选项数据读写逻辑，主要通过 HarmonyOS 的 preferences 机制实现本地数据持久化。

该文件中包含以下主要方法：

| 方法                            | 作用        |
| ----------------------------- | --------- |
| `getPreferencesFromStorage()` | 获取首选项存储实例 |
| `putPreference()`             | 写入指定键值数据  |
| `getPreference()`             | 读取指定键值数据  |
| `deletePreferences()`         | 删除首选项实例   |

在 2048 游戏中，该工具类可用于保存最高分等本地数据。

---

### 16. `commons/basic/`

`commons/basic` 是公共基础模块，用于存放可以被多个功能模块复用的组件或基础能力。

在 2048 游戏页面中，`NumberGameComp.ets` 引入了：

```text
HdNav
```

该组件来自：

```text
@mygames/basic
```

说明 2048 页面顶部导航栏不是在游戏模块中重复实现的，而是复用了公共基础模块中的组件。

---

### 17. `docs/images/`

`docs/images` 目录用于存放项目文档中的图片资源，例如 README 中展示的游戏运行截图。

该目录主要服务于项目说明文档，不直接参与游戏逻辑实现。

---

### 18. `build-profile.json5`

根目录下的 `build-profile.json5` 是整个 HarmonyOS 工程的构建配置文件，用于声明工程产品配置、运行环境、SDK 版本和模块组成。

本工程中主要包含三个模块：

```text
entry
number
basic
```

其中：

* `entry` 对应应用入口模块
* `number` 对应 2048 数字游戏模块
* `basic` 对应公共基础模块

该文件对 DevEco Studio 的同步、编译、打包和运行过程具有重要作用。

---

### 19. `oh-package.json5`

根目录下的 `oh-package.json5` 是工程依赖配置文件，用于管理工程依赖和模块信息。DevEco Studio 在同步工程时，会根据该文件和相关模块配置安装依赖。

---

### 20. `hvigorfile.ts` 与 `hvigor/`

`hvigorfile.ts` 和 `hvigor` 目录与 HarmonyOS 工程构建系统有关。DevEco Studio 执行构建、打包、运行等任务时，会使用这些文件和目录中的配置。

---

## 五、2048 游戏运行流程分析

本工程中 2048 游戏的基本运行流程如下：

```text
应用启动
↓
进入 entry 模块
↓
加载 EntryAbility
↓
显示 Index.ets 首页
↓
用户点击 2048 游戏入口
↓
路由跳转到 pages/NumberGame
↓
NumberGame.ets 加载 NumberGameComp 组件
↓
NumberGameComp 初始化 Board 棋盘对象
↓
用户滑动棋盘
↓
Board.move(direction) 更新棋盘状态
↓
页面根据最新状态重新渲染
```

从该流程可以看出，`entry` 模块主要负责应用入口和页面跳转，`features/number` 模块负责具体的 2048 游戏逻辑。

---

## 六、2048 游戏核心逻辑分析

### 1. 棋盘初始化

游戏开始时，`NumberGameComp` 创建新的 `Board` 对象。`Board` 初始化 4×4 棋盘，并随机生成两个初始数字方块。

### 2. 用户滑动操作

游戏棋盘通过手势识别用户的滑动方向。用户可以向左、向右、向上、向下滑动棋盘。

不同方向对应的移动参数为：

```text
左：0
上：1
右：2
下：3
```

### 3. 方块移动与合并

移动逻辑由 `Board.move(direction)` 处理。对于不同方向的移动，程序先通过旋转棋盘，将其转换为向左移动，再调用 `moveLeft()` 统一处理。

在 `moveLeft()` 中，程序会：

1. 遍历每一行；
2. 提取非空数字方块；
3. 将相同数字的相邻方块合并；
4. 更新合并后的方块数值；
5. 更新游戏分数；
6. 判断是否产生 2048 方块。

### 4. 新方块生成

每次有效移动后，程序会在空白位置随机生成一个新的数字方块。

新方块通常为 2，也有一定概率生成 4。

### 5. 胜利判断

当合并后的方块数值达到 2048 时，程序将 `won` 状态设置为 true，页面显示胜利相关界面。

### 6. 失败判断

当棋盘没有空白位置，并且上下左右相邻方块都无法继续合并时，游戏判定为失败，页面显示 game over 相关界面。

### 7. 分数显示

每次发生数字合并时，分数会增加。页面中会显示当前分数和最高分区域。

---

## 七、工程运行效果

本工程已经成功在 DevEco Studio 中完成导入、同步、构建和模拟器运行。

基础运行效果包括：

* 应用可以正常启动；
* 首页可以显示小游戏列表；
* 点击 2048 后可以进入 2048 游戏页面；
* 棋盘可以正常显示；
* 用户可以通过上下左右滑动移动方块；
* 相同数字方块可以合并；
* 当前分数可以随游戏过程变化。

基础运行效果视频已保存为：

```text
Game2048-Homework/videos/video1_base_run.mp4
```

---

## 八、工程分析总结

通过对该 HarmonyOS 工程的分析，可以看出该项目采用了较清晰的模块化组织方式。

`entry` 模块负责应用启动、首页展示和页面跳转；`features/number` 模块负责 2048 游戏的核心界面和业务逻辑；`commons/basic` 模块提供可复用的公共组件；`resources` 目录负责管理图片、颜色、字符串、页面配置等资源文件；`build-profile.json5` 和 `oh-package.json5` 则负责工程构建和依赖管理。

本次分析使我初步了解了 HarmonyOS 应用工程的基本结构，也熟悉了 ArkTS 页面组件、模块导入、路由跳转、状态变量、手势交互和本地数据存储等开发内容。后续将在该基础工程上继续新增功能，并通过新增功能说明文档和第二个运行录屏展示二次开发效果。


