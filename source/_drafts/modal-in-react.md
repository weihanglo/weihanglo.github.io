---
title: 用 React 實作 Modal
draft: true
tags:
  - React
  - JavaScript
  - Front-End
---

最近開始玩 React，有些需求要做 Dialog Modal，赫然發現，在網頁前端實作 Modal 不若 iOS 使用 `presentViewController` 方便，常見的實作都是命令式（Imperative）DOM 操作。使用 React 這種聲明式（Declarative）前端框架來實作 modal 反而顯得礙手礙腳。本文將分析一些使用 React 實現 Modal 的開源 solution，了解如何在 React 操作 DOM。

_（撰於 2017-04-10，基於 React v16.0.0-alpha.3）_

## Modal Window

> 在正文開始之前，先讓我們了解 **Modal Window** 是什麼。

模態視窗（Modal window）是 UI 設計常用的作法。根據[維基百科][wiki-modal]的說法，**modal** 會讓程式進入一個特別狀態（[mode][wiki-mode]）：

- 阻止與主視窗的互動，彈出子視窗。
- 與子視窗進行一定互動後，才回到主視窗。

Modal 的應用非常廣，例如 iOS 熟悉的 `UIModalPresentationStyle`，desktop app 的儲存／開啟對話框，網頁前端的 `alert`，及 Bootstrap [Modal Dialog][bs-modal] 等，都是一種 Modal 設計。

Modal 可令用戶照預期流程走，便於管理用戶行為，但相對也會中斷當前操作流程，使用不當反而[無助於提升使用者體驗][modal-evil]。話說回來，modal 對一個 UX 概念薄弱的工程師如我，仍是快速實用方便（偷懶好物）。

## Goal of Implementation

在不違反 React 設計理念前提下，我認為 React 實作 Modal 應要有幾個特性：

- 最小化操作細節，開發者只知道 `show`／`close` 等重要 props。
- 在 render 中宣告，只要 modal 彈得出來，都會在 [stacking context][stacking-context] 最上層。
- 可高度客製化。

理想中的 Modal 元件調用情況如下：

```javascript
function ThisIsASubComponent() {
  return (
    <div>
      <Modal isShow={props.showModal}>
        <MyLoginForm />
      <Modal>
    </div>
  )
}
// `MyLoginForm` would pop up
```

不必知道要呼叫什麼 action，不必手動 toggle CSS class，只要在任何一處 declare `<Modal />` 元件，modal 就會奇蹟似的渲染。要符合 React declarative、component-based 的設計理念，這樣應仁至義盡。

## Traditional Solution

先來看看傳統作法，一般多為 DOM 操作的命令式（Imperative）實作，大致有兩種思路：


**第一種**：最快速明瞭，但也不太乾淨的作法

> 在 `document.body` 上 `appendChild`/`removeChild`，使 `modal` 覆蓋整個 viewport

實際上沒什麼技術點，只是 React 無法直接適用，必須透過 [Refs][react-refs] 或者 ReactDOM API 與 DOM 互動。程式碼約莫如下：

```javascript
// 將 click binding 至 button 等互動 element
function click() {
  const div = document.querySelector('.modal') || document.createElement('div')
  div.classList.toggle('modal')

  if (div.classList.contains('modal')) {
    document.body.appendChild(div)
  } else {
    document.body.removeChild(div)
  }
}
```

**第二種**：

> 預先 append 一個 top-level modal element，調用時再改變對應的 CSS（例如 `display`）

更簡單的實作，只需 toggle CSS class。但 React 單向資料流的架構下，最遙遠的距離就是 **inner component** 與 **outer component** 中間一層層的 **props**，mount 在最內層的子組件難與最外層的 modal 組件溝通。你說用 [Redux][redux] 解決就好了？ Redux 當然是這領域的佼佼者，事實上，也有開發者[分析許多種 modal 實作方式的優缺][medium-modals-in-react]，最後選擇使用 Redux + top-level modal component。

然而，我不認同使用 Redux 或其他 state management library 解決的方案，引入 Redux 等庫的會加深專案的複雜度，開發者需要在 `action` 註冊，才能渲染對應的 modal，而有不同的需求時，就要新增不同的 action。我認為這種方式比較瑣碎，不夠 declarative（但相對沒那麼 hacky）。

## Open-source Solution

Github 上早有許多開源實現，知名 React Bootstrap 的 [React Overlays][react-overlays]，ReactJS 社群的 [React-Modal][react-modal] 等都提供相對優質的解法。話不多說，直接參考 React Overlays 的 source code。

### What is a Portal

了解 Modal 實作之前，先來看看 [Portal][react-overlays-portal] 這一核心基礎元件。（以下基於演示，與實際 source 有些許不同）

**Portal** 有入口、大門、傳送門之意，是一種 [HOC（higher-order component）][hoc]，利用先前提到的 `document.body.appendChild` 的作法，將 `props.children` 傳送至 [stacking context][stacking-context] 最上層（最後一個 element）。`Portal` 主要任務如下：

- 不需渲染在宣告處。
- 將 `prop.children` 渲染在 [stacking context][stacking-context] 最上層。
- 可以 un-render 先前渲染的 `prop.children`。

首先，在 `render()` return `null`，防止在宣告處渲染：

```javascript
import React from 'react'   

class Portal extends React.Component {
  render() {
    return null
  }
}
```

接著，建立兩個 properties ，儲存 `appendChild()` 的 parent node 與 child node 資訊，以利後續存取。（使用 [ES7 Property Initializer][es7-property-initializer]）

```javascript
// ...import
class Portal extends React.Component {
  // ...

  // instance properties
  _overlayTarget = null // child node，Portal 的 children 會 mount 在這個 node 上
  _portalContainerNode = null // parent node，_overlayTarget mount 在這個 node 上
}
```

再來就是實作 `appendChild()`／`removeChild()` 的部分。

```javascript
// ...import
class Portal extends React.Component {
  // ...

  // 將新增的 div append 至 container 上，並儲存 target 與 container reference
  _mountOverlayTarget() {
    if (!this._overlayTarget) {
      this._overlayTarget = document.createElement('div')
      this._portalContainerNode = getContainer(this.props.container)
      this._portalContainerNode.appendChild(this._overlayTarget)
    }
  }

  // 移除 target node，並記得擦屁股（deference）
  _unmountOverlayTarget() {
    if (this._overlayTarget) {
      this._portalContainerNode.removeChild(this._overlayTarget)
      this._overlayTarget = null
    }
    this._portalContainerNode = null
  }
}
```

> 這裡用 [`getContainer()` helper function][react-overlays-getcontainer]，保留 target container 的彈性，也可以直接設置 `doucument.body`。

接下來，替 `Portal` 的 `props.children` 實作 **render**／**unrender**：

```javascript
import React from 'react'
import ReactDOM from 'react-dom' // 引入 react-dom 來操作 DOM

class Portal extends React.Component {
  // ...

  _renderOverlay() {
    if (this.props.children) {
      // 把 props.children 渲染到 _overlayTarget 上
      this._mountOverlayTarget()
      ReactDOM.unstable_renderSubtreeIntoContainer(
        this, this.props.children, this._overlayTarget
      )
    } else {
      // children === null，須呼叫 unrender
      this._unrenderOverlay()
    }
  }

  _unrenderOverlay() {
    // 如果沒有 children，要呼叫 unmountComponentAtNode 這樣 _overlayTarget 的
    // children 才會正確呼叫 component 的 life cycle，防止 memory leak
    this._overlayTarget && ReactDOM.unmountComponentAtNode(this._overlayTarget)
    this._unmountOverlayTarget()
  }
}
```

> `ReactDOM.unstable_renderSubtreeIntoContainer()` 是比較特殊的 API，暫時先把它當成 `ReactDOM.render()`，會產生獨立的 React render tree。之後會詳細解釋。

最後，決定呼叫 `_renderOverlay()` 渲染／反渲染的時機。

```javascript
// ...import
class Portal extends React.Component {
  // ...

  // 在 didMount 必須手動渲染
  componentDidMount() {
    this._renderOverlay()
  }

  // 在 didUpdate 時要記得重新渲染
  componentDidUpdate() {
    this._renderOverlay()
  }

  // 在 willUnmount 時記得清掉所有東西
  componentWillUnmount() {
    this._unrenderOverlay()
  }
}
```

基本上

create_portal????
https://github.com/reactjs/core-notes/blob/master/2016-12/december-01.md#dan

`renderSubtreeIntoContainer`

element v.s. component

`ReactInstanceMap`

Reconciliation

stack vs fiber

[wiki-mode]: https://en.wikipedia.org/wiki/Mode_(computer_interface)
[wiki-modal]: https://en.wikipedia.org/wiki/Modal_window
[bs-modal]: https://v4-alpha.getbootstrap.com/components/modal/#live-demo
[modal-evil]: http://stackoverflow.com/questions/361493/why-are-modal-dialog-boxes-evil
[react-refs]: https://facebook.github.io/react/docs/refs-and-the-dom.html
[medium-modals-in-react]: https://medium.com/@david.gilbertson/modals-in-react-f6c3ff9f4701#.z79iqpkoj
[redux]: https://github.com/reactjs/redux
[react-overlays]: https://github.com/react-bootstrap/react-overlays
[react-modal]: https://github.com/reactjs/react-modal
[react-overlays-portal]: https://github.com/react-bootstrap/react-overlays/blob/master/src/Portal.js
[stacking-context]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Positioning/Understanding_z_index/The_stacking_context
[hoc]: https://facebook.github.io/react/docs/higher-order-components.html
[es7-property-initializer]: https://babeljs.io/docs/plugins/transform-class-properties/

[react-overlays-getcontainer]: https://github.com/react-bootstrap/react-overlays/blob/master/src/utils/getContainer.js







[is-fiber-ready-yet]: http://isfiberreadyyet.com/
[react-fiber-commits]: https://github.com/facebook/react/commits/master/src/renderers/shared/fiber
[react-fiber]: https://github.com/acdlite/react-fiber-architecture
