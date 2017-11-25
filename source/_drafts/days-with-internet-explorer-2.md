---
title: Days With Internet Explorer 2
tags: 
  - Internet Explorer
  - Edge
  - Safari
  - Chrome
  - Front-end
  - JavaScript
  - Webcompat.com
---

還記得之前整理的 [IE 相容性][days-with-internet-explorer] 一文嗎？筆者最近參與公司新版 Web App 架構規劃與開發，又遇到許多相容性的問題，連新版瀏覽器也無法倖免。就讓我們再次探討瀏覽器相容性吧！

_（撰於 2017-11-25，基於各種莫名其妙的狀況)_

<!-- more -->

## 目錄

- 相容性問題一覽
- 我能為網頁相容性做什麼

## 相容性問題一覽

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

### iframe 不支援 width/height style

- **Issue**： iOS Safari 上 iframe 不支援 width/height style。
- **Platform**：iOS Safari

### IE 最安全了 iframe 不讓你修改

IE/Edge script error 70 iframe cross domain issue（但 document.domain 明明一樣）

- **Issue**：
- **Platform**：IE 11／Edge 15

### TypedArray 少了些高階函式

- **Issue**：不支援 TypedArray 高階函式，例如 map、reduce、filter
- **Platform**：IE 11／Edge 15

基本上，導入 Babel 轉譯應該可以順利解決，但某些 context 下我們並不會導入 Babel 轉譯，如 web worker thread 或是 iframe content。尤其是 web worker 很容易被拿來操作 binary data，更要將這個缺失牢記在心。

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

### IE 討厭 XHR + JSON

- **Issue**：IE 不支援 `XMLHttpRequest` v2 使用 JSON 作為 `responseType`
- **Platform**：IE 11

### 不支援 custom namespace attribute selector

- **Issue**：不支援 Custom namespace attribute selector（常見於 XML 操作）
- **Platform**：IE 11／Edge 15

### 只能取得 compuated shorthand style 第一個值

IE/Edge 透過 解析兩個 value 以上的 computedStyle (e.g. background-position)，只會取到第一個值，需透過 例如 getPropertyValue('background-position-x') 來取值，而且若是塞 'center' 這種 literal，取到的 value 會是 ‘center'.................

- **Issue**：
- **Platform**：IE 11／Edge 15

### Element 連結到 DOM 之前沒有預設的 computed style property

- **Issue**：在 Element connect（append） 到 DOM 之前，使用 `getComputedStyle` 取得的 style 只會是空字串。
- **Platform**： Webkit-based browsers

這是一個蠻有趣的小差異，Webkit-based browsers（Chrome、Safari）在 element append 到 DOM 之前，computedstyle 的每一個 property 都是空字串；而 Gecko 和 Trident／EdgeHTML 這些 engine 都會有 default value。

筆者並沒有深入研究哪一家的實作比較符合符合 CSSOM 的規範，這個差異可以謹記在心就好。實務上最好「**避免在 element append 到 DOM 之前存取 computed style**」。

### flex-grow 需要 absolute height

- **Issue**：flex-grow 沒設定 absolute height，childrenNode 長不出來
- **Platform**：IE 11／Safari 11

https://stackoverflow.com/questions/33636796/chrome-safari-not-filling-100-height-of-flex-parent

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

### `scrollWidth` 與 `scrollHeight` 搞反了

- **Issue**：在 `writing-mode` 為 `vertical-lr` 或 `vertical-rl` 下，Edge 把 `scrollWidth` 和 `scrollHeight` 搞反了。
- **Platform**：Edge 15

### 不支援 `const` 宣告

- **Issue**：iOS 9 不支援 `const` 宣告變數
- **Platform**：iOS 9 Safari

實際上來說，這不是 bug，也跟開發的 source code 無關，而是 [Webpack Dev Server 的 Caveats][dev-server-caveats]，Webpack Dev Server 2.8.0 以上只支援瀏覽器支持 `const` 的環境，如果你升級 Dev Server 後遇到麻煩，請把版號固定在 **2.7.1** 吧！

### 沒有 `append`／`prepend` convenience methods

- **Issue**：不提供 `append`／`prepend` 這些類似 jQuery 的 DOM 操作方法
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
head.insertBefore(base, head.firstElementChild) // IE have no `prepend` method.
```

> 在導入 polyfill 之前，記得先想清楚專案的環境，別導入一整包卻只用到一兩個 method。

### 過時的 `writing-mode` 標準

- **Issue**：仍只支持舊版的 `writing-mode` 標準
- **Platform**：IE 11／Edge 15

### Multi-column layout 需給定 absolute `column-width`

- **Issue**：一定要給定 absolute `column-width`，CSS multi-column 才有作用
- **Platformi**：Safari 11／iOS 11 Safari

### 語意化 HTML5 標籤

- **Issue**：不支援語意化 tag 就算了，部分 tag 如 `<main>`、`<article>` 還會變成 inline elements
- **Platform**：IE 11

這個 bug 也默默記在心上就好，在 IE 仍苟延殘喘的年代，如要使用 semantic element，記得加上 `display: block` 吧！

### `<button>` 上的 `text-align` 沒作用

- **Issue**：`<button>` 不吃 `text-align` CSS
- **Platform**：iOS 11 Safari

We add span wrappers to achieve this effect.

### 不穩定的 scrollWidth／scrollHeight

- **Issue**：不穩定的 scrollWidth／scrollHeight，會因 position 變動而改變
- **Platform**：Safari 11／iOS 11 Safari

一個 element 的 `scrollWidth` 與 `scrollHeight`，依照 CSSOM 中的 [scrolling area][scrolling-area] 定義，以 element 的 padding edges 或是 descendant（child node）的 border edges 為依據計算。當 element 本身與其 children 的 edges 不變，理論上改變座標位置移動 element，**scrolling area** 並不會變動。

很可惜的是 Safari 的實作出了包。當你變動一個 positioned element 的 `left`、`top` 這些 positioning properties 時，`scrollWidth` 與 `scrollHeight` 是會變動的。

如果你需要在 position 變動之後對 scrolling area 做些計算，可以「**先移動回初始位置**」，再存取 `scrollWidth` 或 `scrollHeight`，這是使 scrolling area 資料正確最保險的作法。

> Safari 11 能有這種 issue 真的很厲害！

## 我能為網頁相容性做什麼

[days-with-internet-explorer]: https://weihanglo.github.io/2017/days-with-internet-explorer/
[msdn-data-protocol]: https://msdn.microsoft.com/en-us/library/cc848897(v=VS.85).aspx
[caniuse-iframe-srcdoc]: https://caniuse.com/#feat=iframe-srcdoc
[mdn-custom-event]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
[scrolling-area]: https://www.w3.org/TR/cssom-view-1/#scrolling-area


[dev-server-caveats]: https://github.com/webpack/webpack-dev-server#caveats


[jquery]: https://jquery.com/
[dom4-polyfill]: https://github.com/WebReflection/dom4
