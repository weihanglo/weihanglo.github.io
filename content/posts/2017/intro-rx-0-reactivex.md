---
title: Intro Rx - 0. ReactiveX
tags:
  - ReactiveX
  - Design Patterns
date: 2017-08-15T09:22:37+08:00
---

![](https://i.imgur.com/2oGARle.png)

聽過 Reactive Programming 嗎？ReactiveX（Rx）是近來火紅的技術，帶動函數響應式程式設計的熱潮。本系列將從 Rx 最原始的概念解釋起，一步步認識 Rx 巧妙的設計理念。期盼讀完後，人人心中都能有 Reactive 的思維！

_（撰於 2017-08-15）_

<!-- more -->

## Why use Rx

[狂熱驅動開發（Hype Driven Development）][hdd] 是當前軟體工程界的奇特現象，每當一個新概念新技術出來，不乏有人大力吹捧。這次，小弟同樣被狂熱驅動，要來吹捧 [ReactiveX（Rx）][reactivex]的設計理念，但在開始推坑之前，我們仍須問自己：「為什麼要用 Rx？Rx 想解決什麼問題？ 」知道一個技術的應用範圍，遠比只會拿著新玩具揮舞來得重要。

### Asynchronous: unified asynchronous APIs

時至今日，軟體工程越來越複雜，無論前端或後端工程、大量的非同步（asynchronous）操作散落於程式各處，各種不同的非同步 API 如 Promise、async／await、callback function 混雜在一起，讓開發一個穩定的非同步程式變得難上加難。若考慮例外捕捉／處理，非同步的程式就會更加複雜了。

如果採用的 Rx，一切的資料或事件都會轉換為 **Observable**，透過 Observable，就可以在**統一的 API 操作非同步的程式了**。這就是 ReactiveX 的核心價值：**An API for asynchronous programming with observable streams**。

### Declarative: better coding style

Rx 除了統一非同步程式的 API 之外，另外一大特色即是採用[聲明式程式設計典範（Declarative Programming Paradigm）][declarative-programming]，相較於傳統[命令式設計（Imperative Programming）][imperative-programming]，聲明式的程式設計更能專注於程式**要做什麼**（What to do），而非命令程式語言**該怎麼做**（How to do），也減少了許多人為因素的錯誤（例如忘記調用 `update` 導致頁面未更新）。

就拿網頁前端工程最熱門的兩大框架 [ReactJS][reactjs] 與 [VueJS][vuejs] 來說，都是 Declarative 的最佳實踐案例，也帶動整個軟體工程界對 Declarative 與 Imperative 程式設計的比較與反思。

### Ubiquitous: exists in major programming languages

Rx 並不是某個語言的函式庫，Rx 本質上是一個程式設計的思想，有人稱他為 [Reactive Programming][reactive-programming]，有人覺得 Rx 有函數式程式設計的味道，應該稱為 [Functional Reactive Programming][functional-reactive-programming]，我們姑且就稱他為 Rx。正因為 Rx 沒有語言上的限制，幾乎所有主流語言都有對應的實作，例如：

- [RxJava][rxjava] ![][rxjava-stars] 與他的夥伴 [RxAndroid][rxandroid] ![][rxandroid-stars]
- 以 TypeScript 開發的 [RxJS 5][rxjs5] ![][rxjs5-stars] 與舊版的 [RxJS][rxjs4] ![][rxjs4-stars]
- [RxSwift][rxswift] ![][rxswift-stars] 以及早期非常熱門的 [ReactiveCocoa][rac] ![][rac-stars]
- 其他諸如 Python、Ruby、C#、Kotlin、Go 等，族繁不及備載。

除了語言上沒有限制，從 backend 到 frontend，都可以是 Rx 的應用場景，是個名副其實的 fundamental library。

### Promising: more and more usage

ReactiveX 早先是由 Microsoft 開發的開源專案，越來越多語言支持後，也越來越多大型公司開始採用與開發，例如 RxJava 最早就是 [Netflix 的開源專案][rxjava-netflix]，Google 的 [Angular][angular] 也大量使用 RxJS。知名募資網站 Kickstarter 在其[開源 App 專案][kickstarter-github]中也廣用 ReactiveX 技術。其他諸如 Airbnb、Github、Trello 都有導入 Rx 的技術。再者，[Observable 的提案已經進入 Stage 1][observable-proposal]，我相信 Observable 終將納入 ECMAScript 標準中。

事實上，小弟並不擔心 Rx 這門技術走向盡頭與否，因為 Rx 是程式思維，而非單一函式庫，了解不同的寫作範式，對程式設計絕對有莫大幫助。

## Under the hood

Rx 揉合了許多程式設計思想，使得很多想法變得可能，例如：

- 統一同步非同步操作的例外／錯誤處理（unify exception handling）
- 事件、資料都以資料流（data stream）呈現，讓不同的來源可被重新組合（composable）
- 捨棄 stateful 的狀態管理，一切都是資料流（less statefull）

Rx 能實現這些想法，主要歸功於以下三個重要的核心概念：

- [Observer pattern][observer-pattern]
- [Iterator pattern][iterator-pattern]
- [Functional programming][functional-programming]

**Observer pattern** 替 Rx 提供了 Reactive programming 的基礎，監聽資料流的變化，推送給訂閱者。

**Iterator pattern** 則替 Observer pattern 加上兩個不可或缺的特性，

- 可通知訂閱者資料流已達末端，沒有資料了。
- 可通知訂閱者有錯誤發生。

這兩特性打造 Rx 最重要的概念「**Observable**」，Observable 類似一般的 **Iterable**，唯一的差異就是資料的流向，傳統 Iterable 是將資料 **pull** 下來，而 Observable 則是將資料 **push** 給訂閱者。除此之外，**任何 Iterable 上的操作，都可以在 Observable 上操作**。

最後，借助 **Functional Programming** 的典範，Rx 多樣化的 operators 就好比數學上的函式，可任意組合、轉換與重用相同的 data stream，並利用 operator chaining 串連所有的運算，讓程式邏輯不用再充斥著 temporary variable。

## Conclusion

本篇主要介紹 Rx 欲解決的問題域，並理解 Rx 三大核心概念。之後，我們會利用幾個篇幅，簡單介紹 Iterator Pattern、Observer Pattern，以及 Functional Programming。


[rac-stars]: https://img.shields.io/github/stars/ReactiveCocoa/ReactiveCocoa.svg?style=social&label=Star
[rac]: https://github.com/ReactiveCocoa/ReactiveCocoa
[rxandroid-stars]: https://img.shields.io/github/stars/reactivex/rxandroid.svg?style=social&label=Star
[rxandroid]: https://github.com/ReactiveX/RxAndroid
[rxjava-stars]: https://img.shields.io/github/stars/reactivex/rxjava.svg?style=social&label=Star
[rxjava]: https://github.com/ReactiveX/RxJava
[rxjs4-stars]: https://img.shields.io/github/stars/reactive-extensions/rxjs.svg?style=social&label=Star
[rxjs4]: https://github.com/Reactive-Extensions/RxJS
[rxjs5-stars]: https://img.shields.io/github/stars/reactivex/rxjs.svg?style=social&label=Star
[rxjs5]: https://github.com/ReactiveX/RxJS
[rxswift-stars]: https://img.shields.io/github/stars/reactivex/rxswift.svg?style=social&label=Star
[rxswift]: https://github.com/ReactiveX/RxSwift

[declarative-programming]: https://en.wikipedia.org/wiki/Declarative_programming
[imperative-programming]: https://en.wikipedia.org/wiki/Imperative_programming
[reactive-programming]: https://en.wikipedia.org/wiki/Reactive_programming
[functional-reactive-programming]: https://en.wikipedia.org/wiki/Functional_reactive_programming
[functional-programming]: https://en.wikipedia.org/wiki/Functional_programming
[iterator-pattern]: https://en.wikipedia.org/wiki/Iterator_pattern
[observer-pattern]: https://en.wikipedia.org/wiki/Observer_pattern

[rxjava-netflix]: https://www.slideshare.net/InfoQ/functional-reactive-programming-in-the-netflix-api
[kickstarter-github]: https://github.com/kickstarter
[observable-proposal]: https://tc39.github.io/proposal-observable/
[angular]: https://angular.io

[reactjs]: https://facebook.github.io/react/
[vuejs]: https://vuejs.org/

[reactivex]: reactivex.io
[hdd]: https://blog.daftcode.pl/hype-driven-development-3469fc2e9b22
