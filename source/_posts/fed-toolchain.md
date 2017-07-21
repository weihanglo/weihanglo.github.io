---
title: Front End Development Toolchain
date: 2017-03-10 15:36:46
tags:
  - NodeJS
  - JavaScript
  - Front-end
---

![React Tech Stack]( https://leanpub.com/site_images/reactspeedcoding/tech-stack-w820.jpg)

在大前端的時代，開發 Web app 不再像以前使用一個 jQuery 的 CDN 這麼容易，從 html 模板的抉擇，css 預處理器的挑選，Javascript 模組化的方法，自動化工具的使用等等，都是一門學問。本文將從建置基本的前端開發環境起頭，簡單介紹~~個人愛用~~現代常用的前端開發工具。

_（撰於 2017-03-10）_

<!-- more -->

## Contents

- [Node.js](#Node-js)
  - [安裝 Node.js](#安裝-Node-js)
  - [Node.js 內建模組、變數](#Node-js-內建模組、變數)
  - [Node.js 版本管理工具](#Node-js-版本管理工具)
- [NPM 套件模組管理工具](#NPM-套件模組管理工具)
  - [package.json](#package-json)
  - [NPM 常用指令](#NPM-常用指令)
- [預處理器／轉譯器](#預處理器／轉譯器)
  - [CSS 預處理器](#CSS-預處理器)
  - [CSS 後處理器](#CSS-後處理器)
  - [ES6+／Babel](#ES6-／Babel)
- [自動化工具／打包工具](#自動化工具／打包工具)
  - [Gulp](#Gulp)
  - [Webpack](#Webpack)
- [程式碼品質](#程式碼品質)
  - [測試](#測試)
  - [靜態程式語法檢查](#靜態程式語法檢查)
- [小結](#小結)
- [Reference](#Reference)

（以下環境皆以 macOS 為例）

## Node.js

[Node.js][nodejs] 是一個 Javascript 的運行環境，基於 Google V8 Engine。在 Node.js 尚未出現前，Javascript 只能運行在瀏覽器客戶端，功能受限於瀏覽器沙盒（sandbox）與廠商實作。Node.js 推出後，Javascript 程式碼可以在伺服器端運行，模組（module）和套件（package）的觀念和生態圈也隨之建立。程式碼的交流／複用更為便利。

### 安裝 Node.js

在 macOS 安裝 Node.js 非常簡單，在終端環境輸入指令來安裝最新版的 [Node.js][nodejs]：

```bash
# The latest version of Node.js
brew install node

# 檢查是否安裝成功（成功則顯示最新版本版號）
node -v
### v7.7.1

```

同時 Node.js 也附帶如同 **python**、**irb** 的直譯式互動環境（[REPL][repl]）可快速測試／開發一些功能。

```bash
# 進入 REPL 環境
node

# -- REPL 環境 --
> 1 + 2
### 3
> 'cat,mouse,dog'.split(/,/)
### [ 'cat', 'mouse', 'dog' ]
```

### Node.js 內建模組、變數

Node.js 提供豐富的原生模組，可以操作 filesystem、socket、os 等系統層的 API，讓 Javascript 躋身至與 Python、Ruby 之流同樣地位，成為流行的腳本語言（[scripting language][scripting-language]）。這裡列出前端開發者較常使用的幾個模組：

- `os`：作業系統相關的操作與資訊
- `fs`：檔案系統的操作（移動／刪除／新增／檔案監控）
- `path`: 路徑相關工具模組（path resolve/join/pase/normalize）
- `assert`：斷言模組，通常與其他測試框架配合
- `child_process`：產生[子行程（進程）][child-process]的模組，開發較複雜的自動化工具才會用到。

另外，Node.js 同時提供許多重要的全域（Global）物件與函式，在全域下（Global Scope）皆可取得。

- `global`：node 運行環境最上層的物件，類似瀏覽器端 `window` 的存在。
- `process`：記錄當前 node 運行環境的所有資訊。一般配合設置 `NODE_ENV` 環境變數來區別不同的開發階段。
- `__dirname`：模組所在目錄的名稱。實際上非全域物件，而是各模組皆有的變數。
- `__filename`：模組的檔案名，Node.js 世界，**一個檔案為一個模組**。實際上非全域物件，而是各模組皆有的變數。
- `require()`：用來引入（import）其他模組的函式。實際上非全域物件，而是各模組皆有的 method。
- `module`：Node.js 遵循 [CommonJS][commonjs] 定義的「模組」模組，最常用到 `module.exports` 變數，這個變數會指向欲 export 的物件。

> Node.js 模組 import／export 稍微複雜，可以參考[用法教學][module-sitepoint]、[深入講解 require][require-ruanyf]，或是直接閱讀[官方文件][node-module]。

<!-- -->
> 模組化的實作規範在 Javascript 界可謂群魔亂舞，所以 ECMA 2015 (ES6) 提出新的模組化 API（[imports][es6-imports]／[exports][es6-exports]），未來甚至可在瀏覽器端使用。目前可透過 Babel 轉譯器的[外掛][es6-modules-commonjs]搶先體驗。

### Node.js 版本管理工具

蓬勃社群使得 Node.js 不斷精進，但也帶來軟體工程最痛苦的「版本相容」問題。許多時候，我們需要在最新的 Node 版本中測試新功能，但仍需要維護依賴舊版的專案。在不同 Node 版本環境間切換成本不低，幸虧有牛人寫了易用的版本管理工具 [`nvm`][nvm] 與 [`n`][n]，讓版本切換變得輕鬆愉快。

以下主要介紹 `nvm` 的特色、安裝與簡易用法。`nvm` 的特色如下：

- 使用 shell script 寫成，無其他相依模組／環境。
- 每個不同版本的 node 有自己的 global modules 環境，不互相影響。
- 更新至新版時，一行指令就可以重新安裝相同的 global packages。

**總之，先開啟你的終端機吧！**

```bash
# 透過 homebrew 安裝 nvm（macOS）
brew install nvm

# 在使用者家目錄下，新增一個 .nvm 的工作目錄
mkdir ~/.nvm

# 使用預設編輯器開啟 ~/.bash_profile
$EDITOR ~/.bash_profile
```

在你預設（或者你最喜愛）的編輯器裡，將下列兩行設定加入 .bash_profile 中：

```bash
# 將下列設定加在 .bash_profile 中，讓 shell 讀取 nvm 設定
export NVM_DIR="$HOME/.nvm"
. "/usr/local/opt/nvm/nvm.sh"
```

離開編輯器，回到終端機畫面。

```bash
# 檢查設定是否正確
echo $NVM_DIR
### /Users/weihanglo/.nvm

# 重新讀取 .bash_profile，讓剛剛的設定生效
source ~/.bash_profile
```

現在可以開始安裝不同版本的 node 了！

```bash
# 安裝最新版的 Node.js
nvm install node

# 安裝／移除特定版本
nvm install v6.9.0
nvm install v7.6.0
nvm uninstall node

# 設定預設使用的版本
nvm alias default v7.6.0

# 切換至其他版本
nvm use v7.6.0
# or
nvm use default

# 列出 local 已經安裝的版本
nvm ls
###         v6.9.0
### ->      v7.6.0
### default -> v7.6.0

# 安裝新版 Node.js，並從其他版本安裝相同的 packages／modules
nvm install v7.7.1 --reinstall-packages-from=v7.4.0
```

> 使用 **nvm** 至今，個人唯一詬病的是 script 體積較大，拖慢 shell startup time，社群有人發現此問題，並提出[解法][nvm-lazy-reddit]。我稍作修改，去蕪存菁，只讀取 default version 的 binary，略提升 startup 時間（畢竟敝人的 `.bashrc` 已不瘦了），[這段 script 提供大家參考][nvm-lazy-mine]。

## NPM 套件模組管理工具

常言道，成功的程式語言背後，有個支持它的生態圈。Python／R 透過科學與統計的模組生態，在資料科學界中獨霸一方；Docker 把 Go 語言從鬼門關前救回，Go 因此成為 Container 界的王者；Node.js／Javascript 則是藉由方便易用的 [`npm`][npm]，讓才華洋溢的~~宅男~~工程師們盡情交流，創造出成千上萬個模組。

以下列出 npm 的特色：

- 為 Node.js 預設的套件管理工具，安裝 Node.js 會一併安裝 npm。
- **npm, Inc** 提供套件伺服器 [npm Registry][npm-registry] 供開發者上傳／下載套件。（截止 2017.3.9 有 43 萬餘套件）。
- 提供 `package.json` 供使用者管理專案的相依模組／套件。
- 根據 `package.json` 的設定，進行更複雜的任務，如 test runner、build tool、watch file changes。

### package.json

`package.json` 是一個 Node.js 模組最重要的檔案，記錄與此模組相關的設定，部分第三方套件的配置文件也可以寫在 `package.json` 裡，減少 project 設定檔過多的問題（例如：babel、browserslist）。

合法的 `package.json` 除了要是一個 [JSON][json] 格式檔案之外，還**必須包含**下列兩個重要的 fields：

- `name`：模組名稱，也是import 模組時的名稱。在 npm Registry 通常是以相同或近似的名稱註冊，命名慣例以`-`（hyphen）取代 camelCase。
- `version`：模組目前的版號，npm 遵循[語意化版號][semver]的標準，減少套件更新異動造成的問題。

其他重要且建議填寫的 fields 有：

- `main`：程式進入點，也是模組進入點（該檔案的 `module.exports`），慣例為 `index.js` 或 `main.js`。
- `devepdencies`：該模組直接相依的第三方模組。規範採用[語意化版號][semver]標準。
- `devDependencies`： 該模組開發時會使用到相依模組，例如**測試模組、打包模組**。規範採[語意化版號][semver]標準。
- `scripts`：自定義的 shell 腳本。可透過 `npm run <command>` 執行。
- `license`：模組的授權條款，建議填寫。
- `bin`：若模組有提供指令列程式，需在此配置指令名稱與對應檔案。

在此概述常用的版號語法：

- `1.2.3`：指定使用版號 1.2.3
- `>1.2.3`：接受版號大於 1.2.3
- `>=1.2.3`：接受版號大於等於 1.2.3
- `~1.2.3`：接受 patch version，同義於 `>=1.2.3 <1.3.0`
- `^1.2.3`：只接受 minor version 或 non-breaking changes，同義於 `>=1.2.0 <2.0.0`
- `*`：接受任何版號。

> `~`（tilde）與 `^`（caret）, 在版號寫法不同時，有不同結果，請參考 [node-semver 官方文件][node-semver]。

一個合法的 `package.json` 範例：

```javascript
{
  "name": "electron-react-demo", // 模組名稱，以 hyphen 取代 camelCase
  "version": "0.0.1", // 當前版號
  "description": "A Electron Demo with React", // 模組簡介
  "main": "main.js", // 程式進入點／模組進入點
  "scripts": { // 自定義腳本
    "start": "electron ." // 輸入 `npm run start` 或 `npm start` 時會執行的腳本
  },
  "author": "Weihang Lo", // 作者欄位
  "license": "MIT", // 授權／版權條款
  "dependencies": { // 直接相依的模組
    "react": "~15.4.1", // 使用 patch version 的 react
    "react-dom": "~15.4.1"
  },
  "devDependencies": { // 開發用的模組
    "babel-preset-es2015": "^6.18.0", // 版號 >= 6.18.0 但小於 < 7.0.0
    "babel-preset-react": "^6.16.0",
    "electron": "1.4.12", // 使用指定版號的 electron
    "mocha": "*", // 使用最新／任意版本。
    "chai": "*"
  }
}
```

還有許多沒介紹到的 `package.json` 設定，在 [npm 官方文件][npm-packagejson] 裡應有盡有！

### NPM 常用指令

npm 的指令列程式提供許多功能，其中最重要的兩類即是**模組**和**執行腳本**相關的指令。

**安裝／移除／更新／列出 相依模組**

- `npm install [--global] [--save] [--save-dev]`
- `npm uninstall [--global] [--save] [--save-dev]`
- `npm ls [--global] [--depth=<number>]`
- `npm update [--global]`

開始介紹前，先了解 npm 安裝模組的模式，分為 **全域模式（globally）** 與 **本地模式（locally）**

- 全域模式 `--global`：安裝的模組通常是常用的指令列程式，例如 npm 本身。
- 本地模式：用來安裝與 project 相依的模組，會在 project 根目錄產生一個 `node_modules` 存放相依模組。

```bash
# 創建一個 npm 模組環境（互動式產生 package.json）
npm init

# 尋找同目錄下的 `package.json`，安裝該檔案內記錄的相依套件
npm install

# 安裝 axios 套件，不儲存相依關係。
npm install axios

# 安裝 bluebird 套件，並將相依版號寫入 `package.json` 的 `dependencies` field 中
npm install bluebird --save

# 安裝 mocha、chai 套件，並將相依版號寫入 `package.json` 的 `devDependencies` field 中（開發用套件）
npm install mocha chai --save-dev

# 安裝 Globally 的套件，在任何目錄都可直接使用該模組的指令列程式
npm install --global yarn

# 移除 bluebird 套件，並從 `package.json` 中移除相依關係
npm uninstall bluebird --save

# 列出 locally（project-wide） 的套件到第一階層（專案的相依套件的相依套件）
npm ls --depth=2

# 列出全域安裝的套件（只列出 user 直接安裝的套件）
npm ls --global --depth=0

# 更新 bluebird 套件至 package.json 內的指定版號
npm update bluebird

# 更新 package.json 記錄的套件至指定版號
npm update

# 更新所有全員安裝的套件
npm update --global
```

> Facebook、Google 幾個大頭在 2016 年 10 月 開源了新一代的 Node.js 套件管理工具 [Yarn][yarn]，在速度、體驗、介面上皆略勝 npm 一籌。Yarn 也會自動產生 `yarn.lock` 檔案，精確記錄相依模組的版號，在套件管理上更安全安心，有興趣的童鞋可嘗試看看。

**執行自定義腳本**

- `npm run <command> [-- <args>...]`

用來執行 `package.json` 的 `scripts` field 中的自定義腳本。在執行開始前，`npm run` 會在既有的 [PATH][path] 環境變數加上 `node_modules/.bin`，許多套件提供的 binary 執行檔可以直接執行，不需要再加上 `./node_modules/.bin/a-command` 等冗長的相對路徑。因此，`npm run` 常作為 task/test runner、build tools 的入口。

```bash
# 在 `package.json` 裡
{
  "scripts": {
    "start": "echo 'Start my node.js app'",
    "fail": "echo \"Oops! Failed on $1\"",
    "serve": "serve"
  }
}

# 回到終端環境，先安裝相依套件
npm install serve

# 等同於執行 `./node_modules/.bin/serve`，開啟一個 local http server
npm run serve
### Serving!

# `--` 可傳入參數等，同執行 `echo 'Oops! Failed $1`
npm run fail -- Example
### Oops! Failed on Example

# `start`、`test`、`restart` 等 script 可不透過 `run`，直接使用簡寫執行
npm run start
### Start my node.js app

npm start
### Start my node.js app
```

除了上述 npm 還有許多功能，族繁不及備載，詳情請參考 [npm - Cli Commands][npm-cli-doc]。有關 `npm run-script`，也可以瞧瞧[這篇教學][ruanyf-npm-run]。

## 預處理器／轉譯器

雖然 Node.js／npm 為 Javascript 生態圈帶來前所未有的繁榮盛況，但前端的世界還是處處充滿危機，不同瀏覽器廠商的實作參差不齊，開發者常搞不清楚[可以用哪些 CSS 與 Javascript 的 features][caniuse]，開源社群為了消弭這些惱人的問題，開發出許多協助開發者的[預處理器][github-css-pre]／[轉譯器（transpiler）][transpiler]。

> 預處理器／轉譯器屬於 [source-to-source compiler][transpiler]，雖然可以加速開發，但也需要引入 build tools 協助轉換語法，有關 build tools／task runner，會在[自動化工具／打包工具](#自動化工具打包工具)與各位分享。

### CSS 預處理器

CSS 對程序猿來說，沒有繼承，沒有函式，沒有變數，全部的設定都在 global scope，完全符合設計不良的語言特性。有志青年打造了許多[類似 CSS 的語言][github-css-pre]，提供變數、函式、[mixin][mixin]，再 compile 成 vanilla CSS，讓寫 CSS 能夠更輕鬆，更能專注商業邏輯。這些方便的工具我們通稱 **CSS Preprocessor**。

目前主流的 **CSS Preprocessor** 有 [Less][less]、[Sass][sass]，以及 [Stylus][stylus] 等，每一套都有各自的擁護者，在此簡單比較 **Sass** 與 vanilla CSS，給客倌看看。

**Vanilla CSS（同一個 nav 下的元素要分為三個 block 撰寫，且相同的 padding 要寫兩次）**

```css

nav ul {
  margin: 0;
  padding: 0;
  list-style: none;
}

nav li {
  padding: 6px 12px
  display: inline-block;
}

nav a {
  display: block;
  padding: 6px 12px;
  text-decoration: none;
}
```

**Sass（SCSS syntax）支援 [variable][sass-var] 與 [nested element selector][sass-nested]**

```scss
$my-vertical-padding: 6px;
$my-horizontal-padding: 12px;

nav {
  ul {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  li {
    display: inline-block;
    padding: $my-vertical-padding $my-horizontal-padding;
  }

  a {
    display: block;
    padding: $my-vertical-padding $my-horizontal-padding;
    text-decoration: none;
  }
}
```

> Sass 是 Ruby 社群發展出來的 CSS 預處理器，在 Javascript 界通常使用 [node-sass][node-sass] 做 CSS transform。Sass 是個人非常喜愛的 CSS 預處理器。

### CSS 後處理器

對前端開發者來說，最痛苦的莫過於在 Chrome 切好 layout，卻在 Safari 跑版。在 Firefox 做 css animation，卻在 Safari 動彈不得。這些問題來自於各瀏覽器實作不同，添加的 [vendor prefix][vendor-prefix] 也不一樣，我們可以透過 [Sass 的 mixin 來解決 prefix 問題][sass-prefix-mixin]，但這不夠 fancy，CSS 後處理器概念營運而生，最有名的莫過於 [postcss][postcss] 的 Plugin [autoprefixer][autoprefixer]，在 CSS 預處理器 compile 完成之後，需要的 property 加上 vendor prefix，完全不需要再寫一丁點 mixin。

> 順水推舟，[postcss][postcss] 是個生態豐富的 css transforming plugin system，許多瀏覽器未實作的 feature，透過 plugin 轉換，就可以使用各種 feature了。

### ES6+／Babel

Javascript 從出生到現在，一直是個被人嫌棄的語言，弱型別，隱式轉換，缺乏真正物件導向概念（只有 prototype oriented），變數可重複宣告，[`this` 的語意][how-does-this-work]更讓人摸不著頭緒。近年來，ECMAScript 的標準不斷往前走，加入了 [作用域變數 scope variable（`let`）][es6-let]、[常數宣告 constant declaration（`const`）][es6-const]，自動綁定 `this` 的 [arrow function][es6-arrow-function]，甚至原生的 [class][es6-class] 等語言新特性。徹底改造整個 Javascript 的生態圈。

可惜又面臨同個問題，目前的瀏覽器／Node.js 環境不一定支援。社群又跳出來，寫了名為 [`Babel`][babel]（借用巴別塔的典故）的 transpiler，將最新的 Javascript 語法，轉換成當前瀏覽器相容的語法。透過 [Babel][babel]，我們可歡樂地使用 ES6 的 class，不必擔心 IE 會 crash 了！

以下介紹 Babel 的簡易設定：

```bash
# 在你的專案目錄底下安裝 babel 套件
npm install --save-dev babel-cli babel-preset-env

# 使用預設編輯器開啟 .babelrc（Babel 設定檔）
$EDITOR ~/.bash_profile
```

在你預設（或者你最喜愛）的編輯器裡，將下列設定加入 `.babelrc`（Babel 設定檔） 中：
```bash
# 在 .babelrc 中加入下列設定
{
  "presets": ["env"]
}
```

接下來利用你喜愛的 task runner，把你的 code compile 成瀏覽器相容的 javascript 吧！

> Babel 提供許多不同的預處理器（presets），例如 es2015、es2017，`env` 是目前 Babel 官方推薦的 presets，可以透過設定 [`browserslist`][browserslist]，依據不同生產環境決定哪些語法需要轉換，**autoprefixer** 與 **eslint** 同樣也支援 `browserslist`。

<!-- -->
> 另一個有名且有前景的轉譯器是微軟出品的 [TypeScript][typescript]，支援繼承、抽象介面、裝飾器、型別檢查等 features，現代語言該有的應有盡有。由於是 Javascript 的 superset，在 TypeScript 裡寫 Javascript 完全合法，且 Google 的 [Angular][angular] Framework，以及有名的 Reactive Programing Libary [RxJS][rxjs] 也都採用 TypeScript。值得一試！

## 自動化工具／打包工具

使用這麼多預處理器／轉譯器／自定義腳本，如果每次都需要自己 `npm run compile`、`babel script.js` 豈不麻煩？為了減少重複性的任務（task），Javascript 生態圈發展出數套實用的 build tool／system，老牌的 [Grunt][grunt] 與較年輕的 [Gulp][gulp]，這裡選擇使用 [Gulp][gulp]。

另外，當我們想使用 npm 上的各種模組，卻很難直接在瀏覽器端引入這些 dependencies。打包工具如 [`Browserify`][browserify] 與 [Webpack][webpack] 提供我們將這些散落各處的 .js、.css、.html 打包起來的方法，便於 import 到瀏覽器客戶端。這裡主要介紹 [Webpack][webpack]。

### Gulp

[Gulp][gulp] 是一個直觀易懂的 build system，其概念是利用 Node.js 的 [stream][node-stream] API，有如 [pipeline][pipeline] 般將檔案傳遞到每個 plugin／transformer 中做對應的任務。而 Gulp 也有豐富的 plugin 生態系，提供許多主流預處理器的 plugin，讓結果如同 stream 一樣容易產出。

以下簡單示範 gulp 安裝與用法：

```bash
# 1. 首先先安裝 Global gulp command-line tool
npm install --global gulp-cli

# 2. 接著在 project 將 gulp 安裝為 devDependencies
npm install --save-dev gulp

```

在 project root 新增 gulpfile.js，並寫入這些設定：

```javascript
// 3. gulpfile.js at project root
var gulp = require('gulp');

gulp.task('default', function() {
  // 你的預設 task
});
```

回到終端環境：

```bash
# 4. 輸入 `gulp`，執行預設的 task：
gulp
### [14:20:30] Using gulpfile ~/Documents/gulp-demo/gulpfile.js
### [14:20:30] Starting 'default'...
### [14:20:30] Finished 'default' after 361 μs
```

Gulp 本身的 [API 不多][gulp-api]，語法也很簡單，這邊舉例並說明 `gulpfile.js` 實例：

```javascript
// 確認有先安裝相依的 babel 套件 與 del 套件
// `npm install --save-dev gulp-babel babel-preset-env del`

var gulp = require('gulp');             // import gulp 套件（必須）
var babel = require('gulp-babel');      // import gulp-babel 插件
var del = require('del');               // import del 套件（用來 cleanup output）

gulp.task('babel', function () {        // 建立一個叫做 babel 的任務
  gulp.src('src/**/*.js')               // `gulp.src` 會讀取給定路徑（src 下所有 js 檔）的檔案
    .pipe(babel({ presets: ['env'] }))  // 將上一步的檔案 pipe 給 babel plugin 處理
    .pipe(gulp.dest('dist'));           // 將上一步的檔案透過 `gulp.dest` 輸出到給定路徑（dist）
});

gulp.task('clean', function () {        // 建立一個叫做 clean 的任務
    del(['dist']);                      // 使用 `del` 套件，刪除輸出的目錄 (dist)
});

gulp.task('default', ['clean'], function () { // 建立預設任務，並設 clean 為相依任務（在該任務執行前執行）
  gulp.watch('src/**/*.js', ['babel']); // 使用 `gulp.watch` 監視檔案異動，有異動就執行 babel 任務
});
```

在終端環境下，我們這樣做：

```bash
# 先寫一個假的 ES6 js file
mkdir src
echo " (() => console.log('Hello, world!'))() " > src/demo.js

# 執行 babel 任務
gulp babel
### [14:42:23] Using gulpfile ~/Documents/gulp-babel-demo/gulpfile.js
### [14:42:23] Starting 'babel'...
### [14:42:23] Finished 'babel' after 9.31 ms

# 測試是否正確 compile 成功
node src/demo.js
### Hello, world!

# 清除輸出檔案
gulp clean
### [14:56:18] Using gulpfile ~/Documents/gulp-babel-demo/gulpfile.js
### [14:56:18] Starting 'clean'...
### [14:56:18] Finished 'clean' after 4.34 ms

# 測試是否正確清除 `dist` 目錄
ls
### gulpfile.js  node_modules package.json src

# 執行 `gulp`，會先執行 clean（相依任務），再執行 default（預設任務）
gulp
### [14:48:30] Using gulpfile ~/Documents/gulp-babel-demo/gulpfile.js
### [14:48:30] Starting 'clean'...
### [14:48:30] Finished 'clean' after 12 ms
### [14:48:30] Starting 'default'...
### [14:48:30] Finished 'default' after 9.36 ms
```

欲了解其他 Plugin／用法，可直接 [Gulp 官網][gulp]，或直接搜尋 `gulp + <something>`，神人都幫你做好了。

### Webpack

[Webpack][webpack] 是近幾年來最熱門的打包工具，透過解析模組之間的相依關係，可以

- 把專案中 js、css、和其他靜態 assets 打包到同一個檔案中
- 將不同頁面／模組的[程式碼分離（code splitting）][webpack-code-splitting]
- 透過 [loader system][webpack-loader]，轉換／編譯 Sass、Babel、TypeScript 甚至圖片等不同檔案 （多數情況下能取代 Gulp、Grunt 等工具）
- 運用不同的 Plugins，組合出適合自己的 Webpack 流程與設定。

Webpack 最簡單的設定，就是在 project root 新增一個 `webpack.config.js` 檔案，以下範例取自 [Webpack 的核心觀念][webpack-concepts]（使用 Webpack 2）：

```javascript
// in `webpack.config.js`

const webpack = require('webpack'); //to access built-in plugins
const path = require('path');

module.exports = {
  entry: './path/to/my/entry/file.js',      // 1. 程式進入點設定
  output: {                                 // 2. 打包輸出設定
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  module: {                                 // 3. loaders（轉換檔案 -> Javascript）
    rules: [
      { test: /\.jsx?$/, use: 'babel-loader' }
    ]
  },
  plugins: [                                // 4. 其他有用的 plugins
    new webpack.optimize.UglifyJsPlugin(),
  ]
};
```

Webpack 的簡易運作流程如下：
```
找到 entry file
-> 解析相依模組
-> 符合 test rules 的模組由 loaders 轉換處理
-> 將所有處理完成的檔案打包成 output 的 js 檔
```

其中，在 `webpack.config.js` 設定檔中，最核心四個概念如下：

**`entry`**

程式進入點，webpack 會從這個（些）檔案開始解析所有相依（require／import）的模組、CSS、圖片（沒錯，Webpack 可以 import 圖片，將圖片視為模組）。一個可以有多個 entries。

**`output`**

打包完成的 `.js` 輸出的路徑設定，可根據多個 entries 輸出對應的 output。也可以利用內建的 `CommonsChunkPlugin` 來分離不同區塊／模組／套件的 output js 檔案。

**`loaders`**

任何使用 import／require 等關鍵字的 dependencies 都會被 webpack 解析，但 webpack 只認得 Javascript，所以需要許多 loaders 協助轉換，例如 `sass-loader`、`css-loader`、`babel-loader` 等。 每條 `rules` 利用 Regex 的 `test` 來區分哪些檔案使用哪些 loaders 處理，`use` field 則是指定對應的 loader，可以串連多個 loaders。

**`plugins`**

使用其他 plugins 來客製化 webpack 的打包結果，例如範例中內建的 `UglifyJsPlugin` 則是壓縮混淆最終輸出的 bundle.js，也有類似 [`extract-text-webpack-plugin`][webpack-extract-text] ，將 CSS 檔從 bundle.js 中分離等實用的 plugins。

<!--  -->
Webpack 近幾年風生水起，生態系也應運而生。礙於篇幅，不少非常實用設定，以及 loaders 與 plugins 例如 `style-loader`、`url-loader`、`HtmlWebpackPlugin` 等，在此無法一一贅述，有興趣可以參考[這個教學][ruanyf-webpack]，也別忘了 [Webpack 2 最新的官網][webpack]。

## 程式碼品質

一份好的程式碼，除了可以正確無誤的執行，更要讓人易讀易維護，本節將介紹

- 如何使用現代化的 JS 測試框架，讓你不再害怕自己寫的程式碼。
- 選擇一個好用的靜態語法檢查器，提高可讀性，減少人為失誤。

### 測試

所有工程師都知道測試的好處，也了解測試的必要性，但卻很少人主動寫測試。傳統 [TDD（~~Trump-driven~~ Test-driven development）][tdd]的先寫測試，再寫程式的流程較不直觀，且易淪為為測試而測試，脫離現實。隨後崛起的 [BDD（Behavior-driven development）][bdd]則漸趨主流，強調測試只應在「程式行為不符預期時失敗」，是測「程式做了什麼」，而不是「程式如何做這些事」。

一些 BDD 的測試框架與 BDD 斷言庫也順勢產生，透過語意化的 API，讓測試員更能了解程式到底「幹了啥事」，增添寫測試的樂趣。這裡主要介紹 [Mocha][mocha] 測試框架，配合 [Chai][chai] 斷言庫，達成「快樂寫測試，寫測試快樂」的最高境界。

[`mocha`][mocha] 與 [`chai`][chai] 安裝與使用方法如下：

```bash
# 安裝 mocha、chai 兩個套件
npm install --save-dev mocha chai

# 建立一個 test 目錄
mkdir test

# 使用預設編輯器開啟 test/test.js（第一個測試檔案）
$EDITOR test/test.js
```

在你預設（或者你最喜愛）的編輯器裡，將下列測試加入 test/test.js

```javascript
const chai = require('chai'); // 引入 `chai`（提供 asset／expect／should 風格斷言）

chai.should(); // 使用 should 前，需先執行 `chai.should()`，將 should 加到每個 Object

describe('Array', function() {          // Test Suite
  describe('#indexOf()', function() {   // mocha 可嵌套 Test Suite，讓意圖更清晰
    it('should include 2', function() { // 實際的 Test Case
      const array = [1,2,5];
      array.should.include(2);          // 使用 should 風格進行斷言
    });
  });
});
```

回到終端環境，執行以下指令：

```bash
# 使用 mocha 模組的 command-line tool，進行測試
./node_modules/.bin/mocha test/test.js
###  Array
###    #indexOf()
###      ✓ should include 2
###
###  1 passing (10ms)
```

> 若希望直接執行 `mocha` 來測試，不想每次都加上模組路徑，可以
  1. 在全域安裝 `mocha` 套件 `npm install --global mocha`
  2. 在 `package.json` 加入一個 run-script
    ```javascript
    "scripts": {
      // ...
      "test": "mocha path/to/your/test/dir/"
    }
    ```

如果想建立 TDD 式的 `setUp`、`tearDown` hooks，可以如下設計：

```javascript
describe('hooks', function () {
  before(function() {
    // 在這個 block 內所有 test case 之前執行
  });
  after(function () {
    // 在這個 block 內所有 test case 之後執行
  });
  beforeEach(function () {
    // 在這個 block 內每個 test case 之前執行
  });
  afterEach(function () {
    // 在這個 block 內每個 test case 之後執行
  });
});
```

有需要非同步（異步）的測試，請

1. 在 test case 的 function params 加入 `done` 參數。
2. 成功則調用 `done()`。
3. 失敗則調用 `done(err)`，並加入 error 作為引數（argument）。

這裡以 `Promise` 為例：

```javascript
describe('Async Tests', function () {
  it('should complete in the furture', function (done) { // 加入 done 參數
    someAsyncPromiseTest()  // 一個異步的 Promise
    .then((result) => {
      assert.ok(result);    // 測試斷言
      done();               // 調用 done，通知 test runner 成功執行 async task
    })
    .catch(err, (err) => {
      done(err);            // 調用 done 並傳入 error，通知 test runner 執行異常
    })
  });  
});

// 由於 `done` 是一個函式，上式也可簡寫成
describe('Async Tests', function () {
  it('should complete in the furture', function (done) {
    someAsyncPromiseTest()
    .then((result) => {
      result.should.equal('well done');
      done();          
    })
    .catch(done); // 直接傳入 done！
  });  
});
```

> 如果需要非同步的 hooks，同樣加入 `done` 參數，並調用 done。

其他相關 mocha 語法 API，[mocha 網站][mocha]寫得非常清楚。有關斷言的寫法，也可直接參考 [chai 官網][chai]。

### 靜態程式語法檢查

使用[整合開發環境（IDE）][ide]的童鞋，想必對[靜態語法檢查][lint]有深刻體會。使用靜態語法檢查，會對程式碼撰寫的風格有所限制，但同時可以可防止許多 [bad code smell][code-smell]，例如：

- [一定要處理 error][eslint-handle-callback-err]
- [避免修改以 const 宣告的變數][eslint-no-const-assign]
- [不要用 `(` `/` `.` `,` 等符號當開頭][eslint-no-unexpected-multiline]（不寫分號唯一會遇到的問題！）

Javascript 的 linter 有非常多套，這裡選用目前最流行、客製化程度最高的 [ESLint][eslint] 作範例。

```bash
# 安裝 eslint
npm install --save-dev eslint

# 互動式建置 `.eslint.js` 配置文件
./node_modules/.bin/eslint --init

# 之後就可以直接用 eslint 來檢查你的程式碼了
./node_modules/.bin/eslint path/to/your/file.js
```

> 同樣地，可以在 `package.json` 加入一個 run-script，方便隨時 lint
  ```javascript
  "scripts": {
    // ...
    "lint": "eslint .; exit 0;" // 有錯誤的話 eslint exit code 是 1， 我們手動 exit 0 以避免 npm 報錯。
  }
  ```

<!--  -->

> 有些檔案不需要 linter 檢查（例如 test spec、其他套件的 config），可在 project root 加入 `.eslintignore` 忽略這些檔案（[寫法同 `.gitignore`][eslint-eslintignore]）。

通常我們會用一些大廠的設定，簡化我們的 Linter config，例如使用 [Airbnb Javascript style][eslint-config-airbnb]，如果需要客製化 linter 可以參考 [ESLint 如何配置][eslint-configuring]。

許多文字編輯器有整合的 eslint 的 plugin（如 [Atom][eslint-atom]、[Visual Studio Code][eslint-vscode]），可即時查看 lint 結果，讓開發者更容易檢查語法錯誤。

## 小結

本想簡單介紹如何建置一個前端開發環境，無奈前端之龐大，初出茅廬的我，完全無法收斂文章內容。本文已盡量點到為止，在重要之處皆留下關鍵連結，給有興趣的人們挖了些坑，希望看倌透過這篇文章，能對前端工程紛擾的世界有所了解，也不吝指教交流！

## Reference

- [Node.js API Documentation][node-doc]
- [NVM - Node Version Manager][nvm]
- [NPM - Node Package manager][npm]
- [NPM Cli Commands][npm-cli-doc]
- [NPM package.json spec][npm-packagejson]
- [Mozilla Developer Network][mdn]
- [Gulp - The streaming build system][gulp]
- [Webpack - A bundler for javascript and friends][webpack]
- [Mocha - Feature-rich Test Framework][mocha]
- [Chai - BDD/TDD Assertion Library][chai]
- [ESLint - Pluggable JavaScript Linter][eslint]


[nodejs]: https://nodejs.org/
[node-doc]: https://nodejs.org/api/
[nvm]: https://github.com/creationix/nvm
[npm]: https://www.npmjs.com/
[npm-packagejson]: https://docs.npmjs.com/files/package.json
[npm-cli-doc]: https://docs.npmjs.com/getting-started#cli
[mdn]: https://developer.mozilla.org/
[gulp]: http://gulpjs.com/
[webpack]: https://webpack.js.org/
[mocha]: https://mochajs.org/
[chai]: http://chaijs.com/
[eslint]: http://eslint.org/

[repl]: https://en.wikipedia.org/wiki/Read–eval–print_loop
[n]: https://github.com/tj/n
[scripting-language]: https://en.wikipedia.org/wiki/Scripting_language
[child-process]: https://en.wikipedia.org/wiki/Child_process
[commonjs]: https://en.wikipedia.org/wiki/CommonJS
[module-sitepoint]: https://www.sitepoint.com/understanding-module-exports-exports-node-js/
[require-ruanyf]: http://www.ruanyifeng.com/blog/2015/05/require.html
[node-module]: https://nodejs.org/api/modules.html
[es6-imports]: http://www.ecma-international.org/ecma-262/6.0/#sec-imports
[es6-exports]: http://www.ecma-international.org/ecma-262/6.0/#sec-exports
[es6-modules-commonjs]:https://www.npmjs.com/package/babel-plugin-transform-es2015-modules-commonjs
[nvm-lazy-reddit]: https://www.reddit.com/r/node/comments/4tg5jg/lazy_load_nvm_for_faster_shell_start/d5ib9fs/
[nvm-lazy-mine]: https://github.com/weihanglo/dotfiles/blob/master/.bashrc#L97-L122
[npm-registry]: https://docs.npmjs.com/misc/registry
[json]: http://www.json.org/
[semver]: http://semver.org/
[node-semver]: https://docs.npmjs.com/misc/semver#tilde-ranges-123-12-1
[path]: https://en.wikipedia.org/wiki/PATH_(variable)
[yarn]: https://yarnpkg.com/
[ruanyf-npm-run]: http://www.ruanyifeng.com/blog/2016/10/npm_scripts.html
[caniuse]: http://caniuse.com/
[github-css-pre]: https://github.com/showcases/css-preprocessors
[transpiler]: https://en.wikipedia.org/wiki/Source-to-source_compiler
[mixin]: https://en.wikipedia.org/wiki/Mixin
[less]: http://lesscss.org/
[sass]: http://sass-lang.com/
[stylus]: http://stylus-lang.com/
[sass-var]: http://sass-lang.com/documentation/file.SASS_REFERENCE.html#variables_
[sass-nested]: http://sass-lang.com/documentation/file.SASS_REFERENCE.html#nested_rules
[vendor-prefix]: https://developer.mozilla.org/en-US/docs/Glossary/Vendor_Prefix
[sass-prefix-mixin]: https://www.sitepoint.com/sass-mixins-kickstart-project/
[postcss]: http://postcss.org/
[autoprefixer]: https://github.com/postcss/autoprefixer
[how-does-this-work]: http://stackoverflow.com/questions/3127429/how-does-the-this-keyword-work
[node-sass]: https://github.com/sass/node-sass
[es6-let]: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Statements/let
[es6-const]: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Statements/const
[es6-arrow-function]: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Functions/Arrow_functions
[es6-class]: https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Classes
[babel]: http://babeljs.io/
[browserslist]: https://github.com/ai/browserslist
[typescript]: https://www.typescriptlang.org/
[angular]: https://angular.io/
[rxjs]: https://github.com/ReactiveX/rxjs
[grunt]: https://gruntjs.com/
[browserify]: http://browserify.org/
[node-stream]: https://nodejs.org/api/stream.html
[pipeline]: https://en.wikipedia.org/wiki/Pipeline_(Unix)
[gulp-api]: https://github.com/gulpjs/gulp/blob/master/docs/API.md
[webpack-code-splitting]: https://webpack.js.org/guides/code-splitting/
[webpack-loader]: https://webpack.js.org/concepts/loaders/
[webpack-concepts]: https://webpack.js.org/concepts/
[webpack-extract-text]: https://github.com/webpack-contrib/extract-text-webpack-plugin/blob/master/README.md
[ruanyf-webpack]: https://github.com/ruanyf/webpack-demos
[tdd]: https://en.wikipedia.org/wiki/Test-driven_development
[bdd]: https://en.wikipedia.org/wiki/Behavior-driven_development
[ide]: https://en.wikipedia.org/wiki/Integrated_development_environment
[lint]: https://en.wikipedia.org/wiki/Lint_(software)
[code-smell]: https://en.wikipedia.org/wiki/Code_smell
[eslint-handle-callback-err]: http://eslint.org/docs/rules/handle-callback-err
[eslint-no-const-assign]: http://eslint.org/docs/rules/no-const-assign
[eslint-no-unexpected-multiline]: http://eslint.org/docs/rules/no-unexpected-multiline
[eslint-eslintignore]: https://git-scm.com/docs/gitignore#_examples
[eslint-config-airbnb]: https://github.com/airbnb/javascript/tree/master/packages/eslint-config-airbnb
[eslint-configuring]: http://eslint.org/docs/user-guide/configuring
[eslint-atom]: https://atom.io/packages/linter-eslint
[eslint-vscode]: https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint
