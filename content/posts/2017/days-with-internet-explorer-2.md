---
title: 與 IE 相處的日子二：淺談網頁相容性 
tags:
  - Internet Explorer
  - Front-end
  - JavaScript
  - Web Compatibility
  - Web Access Right
date: 2017-12-09T18:48:48+08:00
cover:
  image: build-websites-for-web.png
  caption: Modified from Webcompat.com
  style: wide
---

還記得之前整理的 [IE 相容性][days-with-internet-explorer] 一文嗎？筆者最近參與公司新版 Web App 架構規劃與開發，又遇到許多相容性的問題，連新版瀏覽器也無法倖免。就讓我們再次探討瀏覽器相容性吧！

_（撰於 2017-12-09，基於各種莫名其妙的狀況)_

<!-- more -->

> 對相容性問題細節沒興趣的朋友，可直接跳到「我能為網頁相容性做什麼」這個章節。

## 目錄

- [相容性問題一覽](#相容性問題一覽)
- [我能為網頁相容性做什麼](#我能為網頁相容性做什麼)
  - [如果你是網頁使用者](#如果你是網頁使用者)
  - [如果你是網頁開發者](#如果你是網頁開發者)
- [結語](#結語)

## 相容性問題一覽

這邊列出這段紀錄的相容性問題：

- [語意化 HTML5 標籤](#語意化-html5-標籤)
- [不支援 `const` 宣告](#不支援-const-宣告)
- [沒有 `append` 和 `prepend` convenience methods](#沒有-append-和-prepend-convenience-methods)
- [XHR 不支援 JSON](#xhr-不支援-json)
- [CustomEvent 沒有建構函式](#customevent-沒有建構函式)
- [flex-grow 需要 absolute height](#flex-grow-需要-absolute-height)
- [`<button>` 上的 `text-align` 沒作用](#button-上的-text-align-沒作用)
- [Element 連結到 DOM 前 getComputedStyle 沒有預設值 style](#element-連結到-dom-前-getcomputedstyle-沒有預設值-style)
- [Computed Style 行為不一致](#computed-style-行為不一致)
- [iframe 不支援 Data URI](#iframe-不支援-data-uri)
- [iframe 不支援 width 與 height style](#iframe-不支援-width-與-height-style)
- [SCRIPT70: Permission denied](#script70-permission-denied)
- [TypedArray 少了些高階函式](#typedarray-少了些高階函式)
- [不支援 custom namespace attribute selector](#不支援-custom-namespace-attribute-selector)
- [`scrollWidth` 與 `scrollHeight` 搞反了](#scrollwidth-與-scrollheight-搞反了)
- [Multi-column layout 需給定 absolute `column-width`](#multi-column-layout-需給定-absolute-column-width)
- [過時的 `writing-mode` 標準](#過時的-writing-mode-標準)
- [不穩定的 scrollWidth 與 scrollHeight](#不穩定的-scrollWidth-與-scrollHeight)


### 語意化 HTML5 標籤

- **Issue**：不支援語意化 tag 就算了，部分 tag 如 `<main>`、`<article>` 還會變成 inline elements
- **Platform**：IE 11

先來個簡單的 issue。 這個 bug 默默記在心上就好，在 IE 仍苟延殘喘的年代，如要使用 semantic element，記得加上 `display: block` 吧！

### 不支援 `const` 宣告

- **Issue**：iOS 9 不支援 `const` 宣告變數
- **Platform**：iOS 9 Safari

實際上來說，這不是 bug，也跟開發的 source code 無關，而是 [Webpack Dev Server 的 Caveats][dev-server-caveats]，Webpack Dev Server 2.8.0 以上只支援瀏覽器支持 `const` 的環境，如果你升級 Dev Server 後遇到麻煩，請把版號固定在 **2.7.1** 吧！

### 沒有 `append` 和 `prepend` convenience methods

- **Issue**：不提供 `append`／`prepend` 這些類似 jQuery 的 DOM 操作方法
- **Platform**：IE 11

2006 年釋出的 [jQuery][jquery]，現在仍被廣泛使用，其 API 設計規範如 event delegation、on/off，和其他 DOM manipulation 深深影響近代 JavaScript Library 的設計流。

以下這幾個 DOM manipulation convenience methods 很明顯看出影響甚鉅：

- `ChildNode.before`
- `ChildNode.after`
- `ChildNode.replaceWith`
- `ParentNode.prepend`
- `ParentNode.append`

講這麼多都沒用，這些 method 在 IE 11 完全不支援！當然，肯定有 [polyfill][dom4-polyfill]，這裡也示範一下怎麼利用 DOM3 的 API 達到 `ParentNode.prepend` 的效果。

```javascript
// Add <base> tag for dynamic base URL modification
const base = document.createElement('base')
base.setAttribute('href', baseURL)
const head = doc.documentElement.querySelector('head')
head.insertBefore(base, head.firstElementChild) // IE has no `prepend` method.
```

> 在導入 polyfill 之前，記得先想清楚專案的環境，別導入一整包卻只用到一兩個 method。

### XHR 不支援 JSON

- **Issue**：IE 不支援 `XMLHttpRequest` v2 使用 JSON 作為 `responseType`
- **Platform**：IE 11

Ajax 技術中最有代表性的概念就是 **XHR**（`XMLHttpRequest`），非同步的技術讓 web content 可以動態更新，這可算是 Microsoft 對 web 貢獻之一（雖然最後是 [Mozilla Gecko 引擎先在 browser 實作][xhr-history]了）。我們很感謝 IE 不辭辛勞付出，但不代表能不遵從 web standard。IE 至今（2017/11）仍未完全實作 XHR v2 的 spec（請參考 [XHR Living Standard][xhr-living-standard]，沒辦法支援 JSON as returning value。

就算未來 client request 會逐漸被 [fecth API][fetch-api] 取代，我們仍該好好處理瀏覽器向下相容性，畢竟 fetch API 目前只能透過 [AbortController][web-abortcontroller] 取消 request，而且只有 Firefox 57 和 Edge 16 有實作，這時候就凸顯出 `xhr.abort` 的重要性。

如果想要 XHR 支援 IE 11 又要回傳 JSON，解法就是全部都用 `response` 再從 `responseType` 判斷需不需要 parse JSON。簡單作法如下：

```javascript
function request ({ method = 'GET', responseType = 'arraybuffer', uri, body, }) {
  const xhr = new XMLHttpRequest()
  xhr.open(method, uri)
  // IE 11 does not support `json` as `responseType`.
  // We must parse json text manually.
  const asJson = responseType === 'json'
  xhr.responseType = asJson ? 'text' : responseType
  xhr.onload = function (ev) {
    const body = asJson ? JSON.parse(this.response) : this.response
    console.log(body)
  }
  body
    ? xhr.send(body)
    : xhr.send()
}
```

### CustomEvent 沒有建構函式

- **Issue**： CustomEvent 沒有 constructor
- **Platform**：IE 11

IE 11 上不能透過 `new CustomEvent` 建構新的 CustomEvent，只能從透過 `document.createEvent`，再從 `event.initCustomEvent` 建構。MDN 上簡單的 [constructor polyfill][mdn-custom-event] 可以解決這個小問題。

```javascript
// CustomEvent Polyfill for IE
(function () {
  if (typeof window.CustomEvent === 'function') {
    return
  }
  function CustomEvent (event, params) {
    params = params || { bubbles: false, cancelable: false, detail: undefined }
    var evt = document.createEvent('CustomEvent')
    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail)
    return evt
  }
  CustomEvent.prototype = window.Event.prototype
  window.CustomEvent = CustomEvent
})()
```

### flex-grow 需要 absolute height

- **Issue**：flex item 沒設定 absolute height，chilNode 長不出來
- **Platform**：IE 11／Safari 11

某些情況，我們並不知道 flex container 有幾個的 flex item，會希望 item 寬高自動增減。但當 `flex-direction` 設置為 `column` 時，若 flex item 內的 childNode 需要佔滿 parent 100% 的高度，此時會找不到 parent（flex item）可參考的 height，因此渲染出 `height: auto` 的樣式。

[這個 stackoverflow 詳細解釋上述的情況][chrome-safari-not-filling-100-height-of-flex-parent]。這邊總結它提供的幾種解法：

**1. 將所有 parent element 都設置絕對高度 （absolute height）**

這應該不用解釋了，完全正確，幾乎沒什麼相容性問題。

**2. parent element 設置為相對位置；child 設為絕對位置佔滿 parent 的空間**

- parent ➡ `position: relative`
- child ➡ `top: 0; left: 0; right: 0; bottom: 0`

**3. 移除多餘的 HTML container** 👍

有時候 layout 會錯，就是因為嵌套太多層不必要的 `<div>`，其實只要適時移除部分 container，重新組織，通常都能輕鬆解決問題。

**4. 直接使用多層 flex container** 👍

將沒有 absolute height 的 flex item 設置為 `display: flex`，`align-items` 會自動設為 `stretch`，child node 自己就會擴張到 100% height 了。

### `<button>` 上的 `text-align` 沒作用

- **Issue**：`<button>` 不吃 `text-align` CSS
- **Platform**：iOS 11 Safari

這應該是一個 bug，快速的解法就是給他一個 container。

**HTML**

```html
<div>
  <button class="not-centered">Not Centered</button>
  <button class="centered">
    <span>Centered</span>
  </button>
</div>
```

**CSS**

```css
.not-centered {
  text-align: center;
}

.centered > span {
  display: inline-block;
  text-align: center;
}
```

### Element 連結到 DOM 前 getComputedStyle 沒有預設值 style

- **Issue**：在 Element connect（append） 到 DOM 之前，使用 `getComputedStyle` 取得的 style 只會是空字串。
- **Platform**： Webkit-based browsers

這是一個蠻有趣的小差異，Webkit-based browsers（Chrome、Safari）在 element append 到 DOM 之前，computedstyle 的每一個 property 都是空字串；而 Gecko 和 Trident／EdgeHTML 這些 engine 都會有 default value。

筆者並沒有深入研究哪一家的實作比較符合符合 CSSOM 的規範，這個差異可以謹記在心就好。實務上最好「**避免在 element append 到 DOM 之前存取 computed style**」。

### Computed Style 行為不一致

- **Issue**： `getComputedStyle` 回傳的 `CSSStyleDeclaration` 行為不一致。
- **Platform**：IE 11／Edge 15

IE／Edge 對 CSSStyleDelclaration 下每一個 style 的處理方法似乎不盡相同，尤其是使用 JavaScript 操作 shorthand style 最容易出問題。例如：`getComputedStyle(el).backgroundPositionX` 這種直接存取 style 的方法不穩定，使用 `getComputedStyle(el).getPropertyValue('background-position-x')` 比較能取得有效的值。但是 `getComputedStyle(el).getPropertyValue('border-width')` 或是 `getComputedStyle(el).borderWidth` 只能取到空字串。WTF。

除此之外，假設我們現在有一個 element，要取得 background position 就算畫面已經渲染了，只要你**使用 keyword value 賦值**，IE 還是取到前一個設定值，這實在是蠻神奇的，情境如下：

```javascript
// 使用 keyword value 設定
div.style.backgroundPosition = 'bottom 20px left'
getComputedStyle(div).backgroundPosition
// Other: "0% calc(-20px + 100%)
// IE: "0% 0%"
```

總之，在 IE／Edge 的世界裡，別太相信 `getComputedStyle` 會自動更新這種鬼話。

### iframe 不支援 Data URI

- **Issue**：`iframe.src` 不支援 data URI 作為參數
- **Platform**：IE 11／Edge 15／Chrome on iOS

根據 [MSDN 文件][msdn-data-protocol]指出，微軟出品的瀏覽器的 Data URI 只支援下列 elements 與 attributes：

- `<object>` (images only)
- `<img>`
- `<input>` type=image
- `<link>`
- 會用到 URL 的 CSS style，例如 `background`、`backgroundImage`

由於某些需求，筆者需要在 HTML document 傳入 iframe 前做些處理，再利用 **BlobURL** 的方式傳入 `iframe.src`，但顯然 iframe 根本不在上列中。實力堅強的讀者也許會說：「不能用 `src` 那就用 `srcdoc` 傳參吧！」可惜的是 `srcdoc` [連 Edge 17 都不支援][caniuse-iframe-srcdoc]。

如果你同樣要處理 HTML document，推薦一個相容 IE 的作法「**使用 `document.write`**」。

```javascript
// ❌ Original implmentation
const blob = new Blob(
  [doc.documentElement.outerHTML],
  { type: 'text/html' }
)
const src = URL.createObjectURL(blob)
iframe.src = src

// 👌 Compatible implementation
iframe.contentDocument.open()
iframe.contentDocument.write(doc.documentElement.outerHTML)
iframe.contentDocument.close()
```

就是這麼噁心。

> Chrome on iOS 實際上應該有支援 blob URL。筆者在開發時發現 iOS 11 下 Chrome 62 無法支援 blob URL，不過 iOS 11 的 Mobile Safari 可行。因此猜測是，與 Chrome 使用 WKWebView 一些 config 相牴觸，觸發 CSP 或 CORS 等等設定錯誤。

### iframe 不支援 width 與 height style

- **Issue**： iOS Safari 上 iframe 不支援 percentage width/height style。

- **Platform**：iOS Safari

事實上，iOS Safari 支援 `min-height`，`min-width` 使用百分比寬高。我們暫時的解法就是先給 iframe 一個絕對的長度，再利用最小寬高達成目的。

```css
 /* 給 1px，再設置 min-width 讓 iframe 長到 100% */
iframe {
  width: 1px;
  min-width: 100%;
}
```

真是謝了 Safari。

### SCRIPT70: Permission denied

- **Issue**：IE／Edge 無法注入部分 script 到 iframe。
- **Platform**：IE 11／Edge 15

Stackoverflow 上都說這是 IE 最惡名昭彰的嚴格規定，會產生 SCRIPT70 的原因不少，最常見的是：**ifame 與 main frame 不同 Domain，但注入 iframe 的 script 試圖修改 main frame 的資料。**

筆者遇到 Script70 的情境是把 `iframe.contentDocument` 丟進 react-redux 的 container component 中，剛好 `ifame.src` 又是一個 Blob URL，不知道 IE 底層怎麼判斷的，反正這個 blob URL 被當作 cross domain，甚至[修改 `document.domain` 也沒有作用][stackoverflow-script70]。
其他直接 query/append/modify iframe DOM 都沒有遇到上述的問題。

Workaround 就是**檢查每一個 iframe 是否為 same origin**，如果有其他更好的方法，歡迎大家提供。

### TypedArray 少了些高階函式

- **Issue**：不支援 TypedArray 高階函式，例如 map、reduce、filter
- **Platform**：IE 11／Edge 15

基本上，導入 Babel 轉譯應該可以順利解決，但某些 context 下我們並不會導入 Babel 轉譯，如 web worker thread 或是 iframe content。尤其是 web worker 很容易被拿來操作 binary data，更要將這個缺失牢記在心。

簡單的 polyfill 如下：

```javascript
// IE does not support TypedArray#map. Do it ourself.
// We polyfilled for only Uint8Array#map here.
if (Array.prototype.hasOwnProperty('map') &&
    !Uint8Array.prototype.hasOwnProperty('map')) {
  Uint8Array.prototype.map = function (f) {
    return new Uint8Array([].map.call(this, f))
  }
}
```

### 不支援 custom namespace attribute selector

- **Issue**：不支援 Custom namespace attribute selector（常見於 XML 操作）
- **Platform**：IE 11／Edge 15

我們都知道 XML 可以說是「嚴格版」的 HTML，XML 有許多 HTML 沒有的特點，例如現在要介紹的 custom namespace attribute。

在 `Document` 中，要取得含有特定 attribute 的 element，我們會使用 [CSS attribute selector][attr-selector]。

```javascript
// Fetch <a href></a> element
document.querySelector('a[href]')
```

當這個 document 是 `XMLDocument` 時，element 或 attribute 可以有 [namespace][xml-namespace]，如

```xml
<nav epub:type="toc" id="toc"></nav>`
```

我們會很直覺地把 `epub:type` 當作 attribute name 去 query，但這樣是行不通的，需要 escape `:`，但試了幾次之後發現，下列四種方法都沒有完整的相容性，。

```javascript
// ❌ Not work
document.querySelector('nav[epub:type="toc"]')
// ❌ Not work
document.querySelector('nav[epub|type="toc"]')
// ❌ Not work in IE and Edge (glob namespace selector )
document.querySelector('nav[*|type="toc"]')
// ❌ Not work in IE and Edge (escaping)
document.querySelector('nav[epub\\:type="toc"]')
```

最後的解法就是把所有 element 取出來，再判斷有沒有對應的 attribute。

**以下程式碼可能引發胸悶、頭暈、血壓驟升，呼吸困難，有程式碼潔癖者請斟酌觀賞。**

```javascript
let toc = document.querySelector(`nav[epub\\:type="toc"]`)
// Fallback to use manual assignment for browsers not supporing custom
// namespace attribute selector. (IE and Edge. LOL)
if (!toc) {
  const tocs = this._dom.querySelectorAll('nav')
  const pattern = /toc/i
  for (let i = 0; i < tocs.length; i++) {
    if (pattern.test(tocs[i].getAttribute('epub:type'))) {
      toc = tocs[i]
      break
    }
  }
}
```

### `scrollWidth` 與 `scrollHeight` 搞反了

- **Issue**：在 `writing-mode` 為 `vertical-lr` 或 `vertical-rl` 下，Edge 把 `scrollWidth` 和 `scrollHeight` 搞反了。
- **Platform**：Edge 15

**⬅⬅ 閱讀方向 ⬅⬅**

<div style="writing-mode: vertical-lr;writing-mode: tb; height: 300px;">
如果你想要以直書的方式呈現網頁內容，我們會使用 CSS 3 的 <code>writing-mode</code> 這個 property。效果就會像看紙本書一樣。將 <code>writing-moode</code> 改為 <code>vertical-lr</code> 或 <code>vertical-rl</code> 有一個特別的 caveat 要注意：「<b>element overflow 方向會改變，scrollHeight 與 scrollWidth 互換</b>」。
</div>

其實這個 scrollWidth scrollHeight 互相調換很符合邏輯，預設橫式書寫的 content flow 是上下，一行寫滿，content 會繼續往下長，所以 `scrollWidth` 會不斷增加；而直式書寫正好相反，是往左右增長，所以 `scrollHeight` 會持續成長。

然而，Edge 15 卻在直式書寫時忘記將 `scrollWidth` 與 `scrollHeight` 角色互換。解法就是自己判斷 User Agent 再換回來。

```javascript
const verticalPattern = /vertical|^tb-|-lr$|^bt-/i
const writingMode = window.getComputedStyle(el).writingMode
const scrollWidth = detectEdge() && verticalPattern.test(writingMode)
  ? el.scrollHeight
  : el.scrollWidth
```

### Multi-column layout 需給定 absolute `column-width`

- **Issue**：一定要給定 absolute `column-width`，CSS multi-column 才有作用
- **Platform**：Safari 11／iOS 11 Safari

這是一個很神奇的 issue，根據 [CSS Multi-column layout 的標準定義][css-multicol]，當 `column-width: auto` 是，欄數會由其他屬性如 `column-count` 決定。但實際上在 Webkit 上給 `column-count` 一個整數欄數是沒有效果的。

幸好，`column-count` 除了可以決定欄數，當 `column-width` 也是一個非 `auto` 的長度值時，`column-count` 代表最大欄數。我們可以利用這個特性 work around。解法就是加一個 1px 的 `column-width`。

```css
.multi-column {
  column-width: 1px;
  column-count: 2;
}
```

這樣就可以正確分頁分欄了！

### 過時的 `writing-mode` 標準

- **Issue**：仍只支持舊版的 `writing-mode` 標準
- **Platform**：IE 11／Edge 15

[`writing-mode`][mdn-css-writing-mode] 這種冷僻的 CSS property，除了開發電子書（或閱讀器），以及特殊的設計需求，一般開發者大概一輩子都不會碰到。好巧不巧筆者的工作就是前者。

`writing-mode` 會改變 block level content flow direction，意思就是 block element 會朝不同的方向堆疊（預設是 top-down），而 block container 內的 inline-level content 也會以這個方向排列。CSS 3 總共定義 3 個 keyword value，語意非常直白。

- `horizontal-tb`：inline content 以水平方向排列，block content 由上而下流動。
- `vertical-rl`：inline content 以垂直方向排列，block content 由右至左流動。
- `vertical-lr`：inline content 以垂直方向排列，block content 由左至右流動。

![](https://mdn.mozillademos.org/files/12201/writing-mode-actual-result.png)

可惜的是， IE 和 Edge 兩個活寶對新的標準支援有限，只能繼續使用 `lr` `lr-tb` `rl` `tb` `tb-rl` 這些舊 spec。相容的寫法就是新舊兩種都寫進去吧！

```css
.vertical-content {
  -ms-writing-mode: tb-rl;
  writing-mode: tb-rl;
  -webkit-writing-mode: vertical-rl;
  writing-mode: vertical-rl;
}
```

其實 writing mode 蠻有趣的，現在 Firefox 甚至實作 CSS 4 最新的 `sideways` 標準，大家可以玩玩看！

### 不穩定的 scrollWidth 與 scrollHeight

- **Issue**：不穩定的 scrollWidth／scrollHeight，會因 position 變動而改變
- **Platform**：Safari 11／iOS 11 Safari

一個 element 的 `scrollWidth` 與 `scrollHeight`，依照 CSSOM 中的 [scrolling area][scrolling-area] 定義，以 element 的 padding edges 或是 descendant（child node）的 border edges 為依據計算。當 element 本身與其 children 的 edges 不變，理論上改變座標位置移動 element，**scrolling area** 並不會變動。

很可惜的是 Safari 的實作出了包。當你變動一個 positioned element 的 `left`、`top` 這些 positioning properties 時，`scrollWidth` 與 `scrollHeight` 是會變動的。

如果你需要在 position 變動之後對 scrolling area 做些計算，可以「**先移動回初始位置**」，再存取 `scrollWidth` 或 `scrollHeight`，這是使 scrolling area 資料正確最保險的作法。

> Safari 11 能有這種 issue 真的很厲害！

## 我能為網頁相容性做什麼

### 網頁相容性是什麼

我們可能會很好奇，為什麼手機 App 需要針對 iOS、Android 分別開發，而且開發流程、工具大相逕庭，而網頁卻不需要針對每個瀏覽器重頭開發？這是因為在網際網路後面，有許多人致力於訂定各種網路標準，例如 W3C 與 IETF 等組織。而各大網路瀏覽器廠商就針對這些標準開發自家的產品，讓人們可以無痛地使用各式各樣的瀏覽器暢遊網路。

但標準何其多？各家廠商挑選對自己有利的標準來實作。對標準實作程度不一，就產生了相容性的問題，A 網站用 Chrome 可以正確顯示，但可能在 Firefox 排版歪了一邊。而許多網頁開發商為了節省成本，決定「西瓜偎大邊」，只針對某些特定的瀏覽器最佳化，犧牲小眾瀏覽器使用者的使用權。例如這些[只針對 Google Chrome 最佳化的事件][build-weebsite-for-web]，連 Chrome 的開發者自己都看不下去了。而這些事件累積起來，消費者只會看見某些瀏覽器的好像相容性不好，有些網頁開不了，而強勢瀏覽器就強者越強。

完全錯了！網路的初衷不該是這樣，使用網路就像基本人權一樣，沒有人應該被限制只能用特定的方式瀏覽特定的網頁，沒有人應該被剝奪網路使用權。而這正是為什麼我們需要致力於消弭各瀏覽器間的差異，提高網頁相容性的原因。

能幫助提升網頁相容性的方法很多，以下簡單分享一些方法。

### 如果你是網頁使用者

你可以到一個網站 [Webcompat.com][webcompat] 回報網頁錯誤。Webcompat.com 是一個志願者開發的網站，致力於搜集所有網站，所有使用者，所有瀏覽器的網頁相容性問題。Webcompat.com 搜集到問題之後，會先**診斷問題的源頭**，再根據診斷結果找到對應的開發商（可能是瀏覽器開發商或是網頁開發商）。你可以直接到 Webcompat.com 按下 **Report Bug** 回報你遇到的問題，也可以在各主流瀏覽器的 addons 市集找到相對應的附加元件，更快速地回報臭蟲。

如果說你對特定網站情有獨鍾，你可以自行聯絡該網站開發商，請他們檢查並修正你發現的網頁臭蟲，這個方法其實就是 Webcompat.com 的第三個步驟「**Site Outreach**」。

另外，你還可以選擇[相對小眾的瀏覽器][firefox]，減低部分廠商獨佔市場的現象，這就像人們開始會採購小農的生鮮蔬果和農產品一樣自然，讓市場更多元，更有生命力。這種方法的技術門檻相對較低，很適合關心網頁相容性以及瀏覽器獨佔問題，但不懂技術的民眾。

最後，請記得升級瀏覽器，確保自己用的瀏覽器正確實作網頁標準，讓每個舊版過時的產品能夠安全退場。這不僅是為了確保網頁相容性，也可以降低網路資安事件的發生，更能解放開發者的生產力，把產能專注在改善人類生活，而不是對舊式的瀏覽器修修補補。（拜託不要再用 IE 了！）

### 如果你是網頁開發者

身為一個住在自由地區的網頁開發者，要有一種使命感：

> **A person should be able to use the Web with any devices and browsers.**
> — Mozilla Wiki

對筆者來說，這句話就是網路相容性的終極目標。在開發網頁時，需時時刻刻測試網頁在主流的瀏覽器的體驗是否一致，在行動載具或筆電上是否皆能正確執行。這不是為了觸及更多使用者賺更多錢（雖然老闆應該是這樣想），是為了讓不同族群能夠無礙的使用網頁。如果把網頁視為人類的知識累積，那這些珍貴的知識就不應該只讓少數人把持。

大多開發者想像中的網頁相容性可能是 CSS 相容啊，有沒有支援 ES6 語法啊，需不需要裝 Promise polyfill 等等。但很多人不知道，**Accessbility** 也是網頁相容性的一環。對身心不方便的朋友，我們更需要照顧到他們的需求，讓這些朋友能夠跟無畏的使用網路。Wendell Liu 這一篇 [A11y 的文章][forchu-web-accessibility] 寫得非常清楚，不妨花時間讀一讀，肯定會收穫滿滿！。

最後，同樣是 Accessiblity，**偏鄉網路存取權**也是常被漠視的一環。在政府大力推行 E 化政策之下，透過網路學習或辦公對年輕一代已是稀鬆平常的事情，但對某些沒有網路或是網路訊號不好的地區，在網路上傳或下載資料都是一件很痛苦的事情，開發商應該好好評估網路頻寬，減少不必要的封包傳輸，提升網站的效能。並在必要時提供訊號不佳的地區一個替代方案（例如 Facebook Lite 這種作法）。Mozilla 的 IRL Podcast 就有[一期在介紹網路存取權][irl-episode6]，大家都知道網路存取權在這個時代可謂基本人權，那「**迅速有效的網路存取，是奢侈品，還是百姓的權利呢？**」我認為這個議題非常值得思考。

> 題外話：IRL 這個 podcast 在探討網路與生活間交互作用，主軸就是 _Our online life is real life_，內容有趣又不失深度，對英文廣播有興趣的朋友可以參考。

## 結語

網頁相容性對前端開發來說非常重要，但也相對繁雜，許多人避之唯恐不及。筆者經手開發的軟體之受眾剛好是圖書館，而圖書館又是許多缺乏網路存取管道的朋友接觸網路的一個窗口，網路存取權與相容性更顯重要。雖然支援舊版瀏覽器真的很惱人（看那精美的 issue list），但仍要不斷提醒自己：

<p style="color: red;"><b>任何人都有權利使用任何裝置任何瀏覽器暢遊網路</b></p>

這就是身為前端工程師的使命。

[attr-selector]: https://developer.mozilla.org/docs/Web/CSS/Attribute_selectors
[build-weebsite-for-web]: https://thenextweb.com/dd/2017/11/28/please-build-websites-web-not-just-google-chrome/
[caniuse-iframe-srcdoc]: https://caniuse.com/#feat=iframe-srcdoc
[chrome-safari-not-filling-100-height-of-flex-parent]: https://stackoverflow.com/questions/33636796/
[css-multicol]: https://drafts.csswg.org/css-multicol/
[days-with-internet-explorer]: https://weihanglo.github.io/posts/2017/days-with-internet-explorer/
[dev-server-caveats]: https://github.com/webpack/webpack-dev-server#caveats
[dom4-polyfill]: https://github.com/WebReflection/dom4
[fetch-api]: https://developer.mozilla.org/docs/Web/API/Fetch_API
[firefox]: https://www.mozilla.org/firefox/
[forchu-web-accessibility]: https://medium.com/frochu/回歸初心-一探web-accessibility-baaa4d22f4a7
[irl-episode6]: https://irlpodcast.org/episode6/
[jquery]: https://jquery.com/
[mdn-css-writing-mode]: https://developer.mozilla.org/docs/Web/CSS/writing-mode
[mdn-custom-event]: https://developer.mozilla.org/docs/Web/API/CustomEvent/CustomEvent
[msdn-data-protocol]: https://msdn.microsoft.com/library/cc848897(v=VS.85).aspx
[scrolling-area]: https://www.w3.org/TR/cssom-view-1/#scrolling-area
[stackoverflow-script70]: https://stackoverflow.com/a/10471154/8851735
[web-abortcontroller]: https://developer.mozilla.org/docs/Web/API/AbortController
[webcompat]: https://webcompat.com
[xhr-history]: https://wikipedia.org/wiki/XMLHttpRequest#History
[xml-namespace]: https://wikipedia.org/wiki/XML_namespace
[xhr-living-standard]: https://xhr.spec.whatwg.org/
