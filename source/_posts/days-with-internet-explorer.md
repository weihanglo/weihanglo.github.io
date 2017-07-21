---
title: 與 IE 相處的日子
tags:
  - Internet Explorer
  - Edge
  - Front-end
  - JavaScript
  - Browser Testing
date: 2017-07-15 11:36:04
---

![](http://i.imgur.com/VEgmWpv.jpg)

近幾年來，JavaScript 可謂風生水起，從後端到前端，從 mobile 到 desktop，各種 module 滿天飛，信手拈來就是一個 web app。不過，**「沒碰過 IE，別說你會做前端」**，本人從超新手的角度出發，整理最近修正 IE 相容性遇到的坑與解法，給自己日後留個參考。

_（撰於 2017-07-15，基於 IE 11／Edge 15）_

<!-- more -->

## Contents

- [Issues][issues]
  - [Fullscreen breaks my layout!][issue-fullscreen]
  - [Can an image fit its container with aspect ratio?][issue-object-fit]
  - [Do you know your `id`?][issue-xml-id]
  - [Where are my `children`?][issue-xml-children]
  - [Give me some animated SVG][issue-smil-anim]
  - [How an element removes itself?][issue-el-remove]
  - [Same CSS, weird flexbox behavior][issue-flexbox]
  - [(EXTRA) Read the fxxking standard before using custom elements][issue-custom-el]
- [Tools for dealing with compatible issues][tools]
  - [Compatible tables][tool-tables]
  - [Cross browser testing services][tool-services]
  - [Virtual machines][tool-vm]
- [Conclusion][conclusion]

[issues]: #Issues
[issue-fullscreen]: #Fullscreen-breaks-my-layout
[issue-object-fit]: #Can-an-image-fit-its-container-with-aspect-ratio
[issue-xml-id]: #Do-you-know-your-id
[issue-xml-children]: #Where-are-my-children
[issue-smil-anim]: #Give-me-some-animated-SVG
[issue-el-remove]: #How-an-element-removes-itself
[issue-flexbox]: #Same-CSS-weird-flexbox-behavior
[issue-custom-el]: #EXTRA-Read-the-fxxking-standard-before-using-custom-elements

[tools]: #Tools-for-dealing-with-compatible-issues
[tool-tables]: #Compatible-tables
[tool-services]: #Cross-browser-testing-services
[tool-vm]: #Virtual-machines
[conclusion]: #Conclusion

## Issues

### Fullscreen breaks my layout!

- Issue：使用 Web fullscreen API 放大至全螢幕時，整個 document 寬度剩不到一半。
- Platform：IE 11

第一個先來簡單的 fullscreen API！雖然 [fullscreen API 還沒有去掉 prefix][fullscreen]，不過這個 bug 說實在也太大了！沒關係，加個 width 解決，簡單明瞭！

```css
html {
  min-width: 100%;
}
```

[fullscreen]: http://caniuse.com/#feat=fullscreen

### Can an image fit its container with aspect ratio?

- Issue：沒實作 `object-fit`、`object-position` 這兩個 CSS feature。
- Platform：[IE 11／Edge 15（據說 Edge 16 實作了？）][object-fit]

IE 沒支援一直是 `object-fit` 的一大硬傷，許多 polyfill 也做得不是很完全，但我們還有歷久不衰的 `background` style，善用 `background-size` 與 `background-position` 就可以做到這些效果。

需注意的是，`background` options 並沒有 `onload` 的 callback，許多 progressive image loading 效果可能無法使用。我們可以利用一個 detached `<img>` element 先讀取圖檔至 memory， `onload` 時再 assign 到 `backgroundImage` 中，雖然這樣有點醜，反正你都要 call `onload` 了，是有差醜這點喔 XD

```javascript
var preload = new Image()
preload.onload = function () {
  var real = document.querySelector('img')
  real.backgroundImage = `url("${preload.src}")`
}
preload.src = 'uri/to/a/large/image'
```

[object-fit]: http://caniuse.com/#feat=object-fit

### Do you know your `id`?

- Issue：`XMLDocument` 缺乏 `Element#id` 的 API。
- Platform：IE 11／Edge 15

也就是說，`id` attribute 對 IE 們來說，並非特殊的 property，僅為普通的 attribute，所以 **ID selector** `#someid`，或是 `someElement.id` 這類 API 通通不能用。

解法嗎？用 attribute 代替啊！

```css
image#myid { display: none; }
/* become */
image[id="myid"] { display: none; }
```

```javascript
document.querySelector('img').id
/* become */
document.querySelector('img').getAttribute('id')
```

### Where are my `children`?

- Issue：`XMLDocument` 缺乏 `Element#children` 的 getter API。
- Platform：IE 11／Edge 15

這 Issue 滿討厭的，通常我們只想取得 `Element`，在 IE 卻被迫遍歷 `childNodes` 過濾出 `nodeType === 1` 的 node。MDN 上有可用的 [polyfill][children-polyfill]，但本人每次跑 mocha 測試都會拋出 `Illegal Invocation`，看起來是 `this.childNodes` getter 的 `this` binding 錯誤？有點莫名，只好稍微繞點路修改一下，反正都做 polyfill 了，不差這些醜 code。以下做個參考：

```javascript
// Node#children/Element#children polyfill (for Edge 15, IE 11)
//
// From: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode/children
// Overwrites native 'children' prototype.
// Adds Document & DocumentFragment support for IE9 & Safari.
// Returns array instead of HTMLCollection.
;(function (constructor) {
  function childNodesProp (prototype) {
    return Object.getOwnPropertyDescriptor(prototype, 'childNodes')
  }
  if (constructor &&
    constructor.prototype &&
    !constructor.prototype.hasOwnProperty('children')) {
    Object.defineProperty(constructor.prototype, 'children', {
      get: function () {
        var i = 0
        var node
        var nodesProp = childNodesProp(constructor.prototype) ||
          childNodesProp(Object.getPrototypeOf(constructor.prototype))
        var nodes = nodesProp.get.call(this)
        var children = []
        while (node = nodes[i++]) {
          if (node.nodeType === 1) {
            children.push(node)
          }
        }
        return children
      }
    })
  }
})(/* window.Node || */ window.Element) // 加 `Node` 是給 SVG 使用，on demand 囉
```

[children-polyfill]: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode/children#Polyfill

### Give me some animated SVG

- Issue：IE 們沒有實作 SVG SMIL animation。
- Platform：[IE 11／Edge 15][svg-smil]

雖然說被偉大的 Google 給 [deprecate][svg-smil-deprecation] 了，但也遭受不少反彈聲音，在 Web animation API 還沒普及之前，我們可以利用 **inline css animation** 來實現簡單的動畫效果。例如無腦的的 loading（首次親手寫 SVG，獻醜了）。

> 順便提一下，Edge/IE 的 [CSS transform 並不支援 SVG][css-transform2d]，僅能透過 transform attribute 來達成效果。Poor IE！

```svg
<svg x="0px" y="0px" width="24px" height="30px" viewBox="0 0 20 20">
  <style type="text/css">
    rect {
      transform-origin: center center;
      animation: 0.5s animate infinite ease-in-out alternate;
    }
    rect:nth-of-type(2) { animation-delay: 150ms; }
    rect:nth-of-type(3) { animation-delay: 300ms; }

    @keyframes animate {
      from { opacity: 0.2; transform: scaleY(1); }
      to { opacity: 0.8; transform: scaleY(2); }
    }
  </style>
  <rect x="0" y="5" width="4" height="10" fill="#333" opacity="0.2"></rect>
  <rect x="8" y="5" width="4" height="10" fill="#333"  opacity="0.2"></rect>
  <rect x="16" y="5" width="4" height="10" fill="#333"  opacity="0.2"></rect>
</svg>
```

[svg-smil]: http://caniuse.com/#feat=svg-smil
[svg-smil-deprecation]: https://groups.google.com/a/chromium.org/forum/#!topic/blink-dev/5o0yiO440LM%5B126-150%5D
[css-transform2d]: http://caniuse.com/#feat=transforms2d

### How an element removes itself?

- Issue：IE 的 DOM Node 缺乏 `remove` method，無法自殺（**自殺不能解決問題，珍惜生命，遠離 IE**）
- Platform：IE 11

這個坑大大的掛在 [Can I use][childnode-remove] 裡，但也只有用到才會發現，如果你是 Mac 用戶，調試 IE 很辛苦，最後發現是這種狗屎 bug，這輩子鐵定再也不碰任何 M 社出品的玩意兒（結果卻用 VS Code 打這篇文章 XD）。

解法很簡單，如果 codebase 不大的話，將 `el.remove()` 改成 `el.parentNode.removeChild(el)` 即可輕鬆解決。如果你想本人一樣，最近工作上使用 [Web Components][web-components]，必須 import [Custom Elements][whatwg-custom-elements] 的 polyfill，寫了 support IE 11，卻[偷偷調用 `remove` API][custom-elements-childnode]，你玩我嗎？

既然[官方沒有任何要修改的動靜][custom-elements-issue-103]，自己加個 Polyfill 總行了吧？

```javascript
// Element#remove polyfill (for IE 11)
// (MUST import before custom-elements polyfill)
// from:https://github.com/jserz/js_piece/blob/master/DOM/ChildNode/remove()/remove().md
// Issue discussion:https://github.com/webcomponents/custom-elements/issues/103
;(function (arr) {
  arr.forEach(function (item) {
    if (item.hasOwnProperty('remove')) { return }
    Object.defineProperty(item, 'remove', {
      configurable: true,
      enumerable: true,
      writable: true,
      value: function remove() { this.parentNode.removeChild(this) }
    })
  })
})([Element.prototype, CharacterData.prototype, DocumentType.prototype])
```

[web-components]: https://www.webcomponents.org/
[childnode-remove]: http://caniuse.com/#feat=childnode-remove
[whatwg-custom-elements]: https://html.spec.whatwg.org/multipage/scripting.html#custom-elements
[custom-elements-childnode]: https://github.com/webcomponents/custom-elements/blob/master/src/Patch/Interface/ChildNode.js#L104
[custom-elements-issue-103]: https://github.com/webcomponents/custom-elements/issues/103

### Same CSS, weird flexbox behavior

- Issue：各種 flexbox 的 bug
- Platform：IE 11

眾所週知，IE 的 **flexbox** 實現有許多 bug，本人也遇到不少，幸好碼農們也整理出 [bug list][flexbugs] 供大家避坑，這裡就不多做解釋了。

[flexbugs]: https://github.com/philipwalton/flexbugs

### (EXTRA) Read the fxxking standard before using custom elements

- Issue：在 custom elements connected 前，不要對他操作 DOM（appendChild、setAttribute）。
- Platform：Chrome 54+

這其實不算是 bug，而是一個標準，Chrome 實實在在地做出來了，**polyfill** 卻沒有檢查這些 requirements。根據 [Custom elements constructor 的標準][custom-element-conformance]，

> The element must not gain any attributes or children, as this violates the expectations of consumers who use the `createElement` or `createElementNS` methods.

我們不能在 constructor 中有任何 attribute／childNodes 的操作，也不應涉及設計 render 相關動作，官方標準建議可以在 `constructor` 中做：

- Setup event listeners.
- Setup default/initial values.
- Setup **shadow root**.
- Truly one-time initializaiton.（因為 `connectedCallback` 很可能跑不只一次）

實務上，大部分的工作都會延遲到 `connectedCallback`，尤其當這個 elements 以互動／呈現為主，`constrcutor` 反而僅剩加 flag 防止二次渲染，以及一些 private field 的設定。

其實 web components 的 polyfill 坑也不少，希望未來有一天能夠普及（但 attribute 不能傳遞 function context 就難受想哭）。

[custom-element-conformance]: https://html.spec.whatwg.org/multipage/custom-elements.html#custom-element-conformance

## Tools for dealing with compatible issues

為了相容各大瀏覽器，前端工程比想像中更加複雜，往往設計好一些 feature，卻因為相容性問題，被迫對架構做出修正。如果你手上的專案不需要支援這些老舊的瀏覽器，恭喜你，這種機遇不是人人都有！如果你跟本人同樣不幸，只能為了需求妥協，這邊推薦幾個好物參考用，希望能節省各位的加班費。

### Compatible tables

有時候不知道某個 feature 在各平台上支援程度如何，一般我們會看兩個網站：

- [Can I use... Support tables for HTML5, CSS3, etc](https://caniuse.com/)
- [ECMAScript 6 compatibility table](https://kangax.github.io/compat-table/es6/)

前者專注在 Browser support 的 Web API，許多 CSS 或 DOM 的 feature 都有詳細的資訊，不過有時關鍵字搜尋不易找到。當然還有[各種 Plugin][google-caniuse-plugin] 或 [commandline tool][caniuse-cmd] 可以安裝。

後者就比較陽春一點，沒有實用的搜尋功能，但一些 JavaScript 基礎語法就要靠它了解支援程度。例如 Array 的各種 fuctional methods，我從來都不記得哪個在哪裡有實作。（不過 Babel／TypeScript 大火，還有人在管 JS 相容性嗎 XD）

[google-caniuse-plugin]: https://www.google.com.tw/search?q=caniuse+plugin
[caniuse-cmd]: https://github.com/sgentle/caniuse-cmd

### Cross browser testing services

跨瀏覽器測試是前端工程最為複雜惱人的部分之一，各家瀏覽器在每個平台上都有不同的表現，一般企業很難有齊全的測試環境，所以就有許多 **cross browser testing services** 興起，比較有名的幾家如：

- [SauceLabs](https://saucelabs.com/)
- [BrowserStack](https://www.browserstack.com)

透過這些跨平台測試工具，可以全面檢測自家的 codebase，減少建置 infrastructure 的負擔，加上他們都有豐富的 API 與文件，整合 CI／CD 更為方便，價格有不會太貴，個人認為開發前端的公司考慮一下。

> 因為 Mozilla 與 Microsoft 有跟 BrowserStack 合作，目前測試 Edge、Firefox 都完全免費，所以本人就像牆頭草一樣選擇 BrowserStack 了。

### Virtual machines

如果買不起上面的 testing services，這邊有個省錢（但很累人）的方法，就是使用 **VirtualBox** + **Windows 10 Insider Preview** 測試 Edge 和 IE，Insider Preview 只要註冊就可以用了！

因為怕被黑，細節就不多講，還是建議大家直接使用正版，或是買別人的測試服務吧。

## Conclusion

俗諺有云：「IE 是前端工程的墳墓」，與 IE 交往，切勿急躁，想清楚，多溝通，有時候她鬧點彆扭就讓著吧，不要疾病亂投 polyfill，破壞~~你與 IE 之間的愛~~架構絕對更痛苦。

往後若有其他 IE 相容性的 Issue，本文會再繼續更新。
