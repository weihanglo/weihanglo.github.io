---
title: Answers to Cherny's Interview Questions
tags:
  - Interview Questions
  - JavaScript
  - Front-end
date: 2017-07-26T20:48:30+08:00
---

這份面試題出自[於此][questions-source]，是從 [/r/Frontend/][reddit-frontend] 連結過去的，看到如此自豪的標題和簡介，便手癢來作答，結果寫完基礎概念篇，才發現這份題目在 reddit 上被批評得體無完膚，與現代前端技術棧相差頗大。不過，一些核心概念還是挺重要的，在此分享小弟的答案，有任何錯誤，請各位不吝賜教。

_（撰於 2017-07-26）_

<!-- more -->

## Concepts

Be able to clearly explain these in words (no coding):

## What is Big O notation, and why is it useful?

Big O notation 是用來分析演算法複雜度的漸近符號，可以簡單視為**運算成本（時間、空間）與輸入資料量的趨勢函數**，例如 f(x) = x^2 + 3x + 6。當輸入資料量增大時，函數的「最高次項」最具有決定性，因此可以之表示演算法在資料量夠大時，「最多」達到怎樣的趨勢（趨勢上界），例如上例的複雜度會是 f(n) = O(n^2)。（另有 Big-Theta、Big-Omega 分別描述「趨勢區間」與「趨勢下界」）

Big O 以宏觀的角度來分析演算法，並利用簡單的數學式表示，令演算法效率分析有簡明、客觀的基準。

## What is the DOM?

全名為「Document Object Model」，是 W3C 的標準之一，定義如何將文件（XML／HTML document 等）映射至一樹狀結構中，每個節點都是一個物件，並帶有操作此 DOM node 的 API。

## What is the event loop?

JavaScript 是單執行緒（單線程）的程式語言，任何龐大運算都可能阻塞整個程式，因此 JavaScript 設計了 **message queue** 配合一個不間斷的 **event loop** 來管理任務，當 call stack 沒有執行任何 task 時（程式閒置時），loop 便從 queue 中取第一個 message 至 call stack 調用。開發者可將 callback 加入 message queue 等待 loop 輪詢（polling），實現非同步程式，這就是 JavaScript event loop 的機制。

實際上 event loop 的概念並不僅限於 JavaScript，其他語言的 main loop 或像 iOS／macOS 的 `NSRunLoop` 都是建立在此概念之上。

## What is a closure?

在某些函式（function）為一等公民（可來傳遞、當作引數）的程式語言中，**閉包（closure）是「一種特殊的函式，會儲存／綁定該[詞法作用域（lexical scope）][lexical-scoping]下被引用的變數資訊」**，如綁定閉包內被引用的外部變數，讓 closure 可以使用這些變數，這種儲綁定外部變數的行為稱為 capture，被儲存的變數一般稱 [captured／free／bound variable][free-variable]。

由於這些外部變數被 closure 綁定，因此可以在這些變數宣告的作用域外執行 closure 並使用這些 variables，，所以 closure 廣泛應用於程式區塊間互相傳值／通訊，例如非同步常使用的 callback function，經常會是一個 closure。近幾年函數式程式設計（functional programming）當紅，高階函式（higher-order function）的函式參數（function parameter）也是一種常見的 closure。Functional programming 另一個技法 **currying**（將多參函式轉換為單參函式），同樣利用了 closure 捕獲 variables 的特性。當然，最常見的 `setTimeout`、`setInterval` 就是 closure 的最佳範例。

需注意的是，由於不同語言的記憶體管理方式有差異，binding free variable 的實作也不盡相同，目前記憶體管理方式，大致上分為 [Reference Counting（RC）][reference-counting]與 [garbage collection（GC）][garbage-collection]，若是以 RC 管理記憶體的語言（如 Swift、Objective-C），需注意 reference count 在 closure 內部可能會增加，部分語言需要手動 release reference。

[lexical-scoping]: https://en.wikipedia.org/wiki/Scope_(computer_science)#Lexical_scoping
[free-variable]: https://en.wikipedia.org/wiki/Free_variables_and_bound_variables
[reference-counting]: https://en.wikipedia.org/wiki/Reference_counting
[garbage-collection]: https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)

## How does prototypal inheritance work, and how is it different from classical inheritance?

JavaScript 的物件導向概念是基於「原型（prototype）」而設計，有別於其他基於類別（class）的語言，其中最大的差異就是 prototype-based 的物件導向並無 class 概念。我們可將傳統的 class-based 的 class 想像成藍圖，實例（instance）是依照此藍圖創造出來（實例化，instantiation）；而 prototype 則較接近桃莉羊，概念類似於從已知實例創造出新的實例，共享（或複製）原始來源的特性。

Prototype-based 的語言雖沒有真正的 class，但會有類似建構子（constructor）的方法／函式，創建實例是，同時將原型物件的屬性／方法（property／method）複製或引用一份。例如 JavaScript 中每個物件皆有 `prototype` 這個原型物件，**所有透過建構子實例化的實例，都可以從自身的屬性，取得該原型物件的同名的屬性**。要注意的是，有些實例的屬性可能是一個引用（reference），直接指向原型物件對應的屬性，修改可能會使其他實例受影響。比較常見的做法是**繼承建構子**，或是**複製整個原型物件**。

> ES2015 提供以傳統物件導向語法 `class extends` 完成繼承的語法糖，本質上仍是 prototypal inheritance，但相對門檻較低，程式碼也比較直觀。

## How does `this` work?

當一段 code 被 JavaScript 執行時，會創建新的執行語彙環境（execution context），在創建之初就會綁定 `this` 的值（還有變數與作用域鍊），接下來才執行程式碼。要知道 function 的 `this` 指向何者，就要了解創建 context 時是 function 如何被調用。一般來說，以下幾種狀況便可涵蓋大多數的情境。

| 情境                        | `this` 指向                  |
| :------------------------- | :--------------------------- |
| 在全域直接調用一個 function   | `window` 或 `global`（node）  |
| 調用物件的方法 `obj.method`  | 該物件                        |
| function.call／bind／apply  | 被綁定的物件                  |
| 透過 `new` 調用 constructor  | 新創建的物件                  |
| ES6 arrow function         | 該詞法作用域下的 `this`（較直觀）|   


## What is event bubbling and how does it work?

JavaScript DOM Event 的傳遞會經過三個階段：

- **capture phase**
- **target phase**
- **bubbling phase**

當一個事件觸發時，會從 `window` 往 DOM tree 傳遞，從 tree root（document）往下找，直到監聽該事件的 Event target，這個階段就是 **capture phase**，到達 Event target 則稱之 **target phase**。在這之後，event 會像冒泡泡板開始往上傳遞，傳遞到 `window` 為止，這就是 **bubbling phase**。JavaScript 的 Event listener 預設是在 bubbling phase 捕捉事件，所以當 Event Listener 沒有終止事件傳遞（`Event#stopPropagation`），其父元素若有監聽事件，就有機會捕捉到該事件。

## Describe a few ways to communicate between a server and a client. Describe how a few network protocols work at a high level.

_（這問題有點太廣，要怎麼回答⋯⋯）_

伺服器與客戶端之間的通訊，有許多大大小小的概念與方法，以下介紹幾個前端常見的：

### HTTP

HTTP 網路上最常見的 protocol 之一，屬 OSI 第七層 Application layer。概念是**用戶端發起請求（request），伺服器端根據請求，回應（response）對應的狀態與資源**。用戶端可發送不同的 request method（GET、POST 等），以不同的方式操作資源。伺服器端則可根據 request method、body、headers、session 等資訊，決定該回應什麼狀態（例如 302 Temporarily Moved）以及 response message、headers 等。

### Network Socket & WebSocket

**Network Socket** 為一個提供程式（更精確的說是 process）間雙向溝通的網路通訊接口，通常會綁定（bind）在一個 port 上，讓 Transport Layer（TCP／UDP）與 Application Layer 得以互相辨識溝通，其他程式則透過 TCP 層，再經由 socket 實例與該 process 交換資料。也可以視 socket 為 TCP 層的封裝。  
受 Unix「一切皆檔案」的哲學影響，socket 通常會提供 `open`、`write`、`close` 等 API，甚至實作上就是一個實際檔案，因此，通常將 socket 視為 OSI 第五層 Session Layer，負責管理每個 session 對話。

> 可比喻成「給予 process 專屬信箱（socket），讓其他 process 透過地址（IP）傳信給它」。

[WebSocket][websocket] 則是一個全雙工（full duplex）的通訊協議，目前已是 W3C 與 IETF 的標準之一，主要提供但不限於 web browser 與 web server 間的通訊。由於傳統的 HTTP 協議只能利用 polling 的方法模擬雙工，效能不佳，透過將 HTTP 協議升級（Upgrade）為 WebSocket，讓許多實時（realtime）的需求得以實現。  
目前各大主流瀏覽器皆已實作 WebSocket API，也有許多函式庫（如 [Socket.io][socketio]）可以選用。

**WebSocket** 與 **Network Socket** 雖然都稱作 socket，但差距不小，Network Socket 如前所述，是封裝 TCP 層，讓 process 有專屬接口，與 TCP 溝通，屬 Session Layer，並非一種協議，而是類似於 API 的存在； WebSocket 則是從 HTTP 協議升級的一個完整全雙工協議，有標準的 API，屬 Application Layer。

[websocket]: https://www.websocket.org/
[socketio]: https://socket.io/

### WebRTC

_（先聲明，這不是 client-server 的通訊方法，但卻是近年很重要的一個 Web 標準。）_

[**WebRTC**][webrtc] 是一些 API 與協議的集合，提供瀏覽器透過 plugin-free 的 P2P 連線（browser-to-browser），達成 Real-Time Communications（RTC）的功能，也就是說，瀏覽器間可不透過伺服器，直接穿透 firewall 交換訊息。WebRTC 推行多年，直到今年 Apple 才在 2017 WWDC 宣告下一版本的 Safari／iOS Safari 將全面支援 WebRTC，因此，可大膽預測 WebRTC 會逐漸取代傳統 P2P 視訊底層的技術，甚至[有望成為直播技術選擇][zhihu-webrtc-streaming]之一。

WebRTC 除了傳送音訊與視訊，也可傳送**任意資料**，場景看似與 WebSocket 重複，實際上仍有差異。從傳輸協議來看，WebSocket 封裝 TCP，丟失封包會重傳；WebRTC 底層為 RTP，可接受封包丟失。從對話架構來看，WebSocket 為 client-server 主從式的通訊架構；WebRTC 則是 P2P、client-to-client 的實時通訊。

[webrtc]: https://webrtc.org/
[zhihu-webrtc-streaming]: https://www.zhihu.com/question/25497090

### TCP/IP

TCP 與 IP 是兩個不同的通訊協議，TCP 為 OSI Transport Layer 的協議，主要負責**提供可靠、錯誤校正的傳輸資料，封包若丟失，TCP 會嘗試重傳**；IP 則是位於 Network Layer 的協議，主要功能為**尋找主機位置，封裝資料，再從來源路由（routing）到目標主機**。  

由 TCP／IP 等網際網路協議組成的網路架構通常稱為 **Internet protocol suite**，被視為簡化版的 OSI 模型，也是目前最主流的網路架構。

## What is REST, and why do people use it?

_（聲明：本人錯過 SOAP 的年代，實務上只使用過 RESTful 架構）_

**REST**，全名為 **REpresentational State Transfer**，是眾多網路軟體架構中的一種，以結構清晰簡潔著稱，目前主流的網路服務都以此風格架設，大致實作概念為：

- 所有資源以 URI 表示。（resource-oriented）
- 資源可以不同的形式表現（例如 XML 或 JSON），取決於客戶端環境、headers 設定等。
- 使用標準 HTTP request method（GET、POST、PUT、DELETE 等）對資源進行不同的操作。

由於透過標準 HTTP protocol 實現 RESTful 架構，一切 request 都是無狀態（stateless），因此有許多優點：

- stateless，可以利用 cache 機制。
- stateless，容易用各種工具調試（如 [cURL][curl]、[httpie][httpie]）。
- 每個 request 都獨立，耦合性低。
- 利用 URI，統一 API 接口定義。

> 因為 RESTful 以資源為導向的風格，後端常會為了日益增長的需求，開發了許多大同小異的 API，新興的 [GraphQL][graphql] 就是為了對付這類問題，日益發展起來。

[curl]: https://curl.haxx.se/
[httpie]: https://httpie.org/
[graphql]: graphql.org

## My website is slow. Walk me through diagnosing and fixing it. What are some performance optimizations people use, and when should they be used?

_（講一個 slow 是能看出什麼毛喔⋯⋯）_

所謂網頁很慢，有兩大類別，一是 client 端效能的問題，最容易觀察到的現象就是**動畫掉幀**；另一個則是**網路請求太久**。我們先談動畫掉幀。

### 動畫掉幀

**動畫掉幀** 就是指動畫 FPS 未達到人眼視覺暫留的時間間隔，一般以 60 FPS 為分水嶺，低於 60 FPS 就會產生卡頓的感覺。究其原因，不外乎運算量過大，擠壓到動畫觸發的時間點，瀏覽器自動 skip 到下一個 frame。一般有兩個思考方向：

1. 是否觸發過多的 reflow（layout）？
1. 動畫相關的的 JavaScript code 效能是否低落，太多複雜運算？

關於 **減少 reflow（layout）**，這裡有幾個關於 CSS 的小撇步：

- 儘量使用 `transform` 替代操作 `width`、`top` 等 style，減少 reflow。
- 若必需更改到 `width` 等 style，可嘗試使用絕對座標 `position: absolute`。
- 適量使用 `will-change` 通知瀏覽器準備動畫所需資源
- 觸發 GPU 運算加速渲染（通常添加 `transform: translateZ(0)` 來觸發）。
- 不要任意更改 flex item 的寬高與座標，會增添非常多額外的運算。
- 善用瀏覽器開發者工具檢視動畫在哪裡掉幀，並即時更改 styles，預覽修正結果，降低迭代成本。

很多時候，reflow，和 **JavaScript code performance** 脫離不了干係，我們仍有許多法門提升程式碼效能。

- 首先，當然是檢視演算法本身有沒有優化空間，能不能降低複雜度，是否允許以空間換時間。
- 經常觸發的動畫或運算（例如 window resizing），是否可以設置 throttle／debounce。
- 承上，善用 `requestAnimationFrame` 讓與動畫直接相關的程式碼之觸發間隔與動畫同步。
- 合併 DOM 操作（batch），降低 DOM tree 改變次數（例如 React 的 Virtual DOM）。
- 將 synchronous 的運算改為 asynchronous（需注意架構與維護性）。
- 若是必要的龐大運算（如加解密），可放置到 web worker，將 main thread 留給 UI。
- 一定要了解[哪些行為會造成 reflow][what-forces-layout]。

### 網路請求

上述動畫掉幀的「慢」，較屬使用者互動的 UI 層，Web App 另一個瓶頸是網路請求（request），舉凡下載圖片，請求 CSS JavaScript 等等與 request 相關的操作，很容易因為資源取得過慢，造成使用者觀感欠佳。解決的方法不少，重點大多在減少 request 數量，以及善用快取，以下舉一些常見作法。

- JavaScript CSS 最小化與打包。（已有許多構建工具可用，例如 `gulp`、`webpack` 或 `rollup`）
- 按需加載（on-demand loading），例如滾動到 visible area 才下載圖片，或需要時再載入 script。
- 以 sprite 的方式組合 assets，減少 request 數量。
- 善用 browser cache、local storage 等技術，讓資料可即時取得。
- 開啟 [HTTP/2 server push][server-push] 等機制。
- 多利用 placeholder／thumbnail 等 UI 設計，降低要求資源的等待感。

其實還有非常多優化效能的作法與手段，這裡暫時打住。

[what-forces-layout]: https://gist.github.com/paulirish/5d52fb081b3570c81e3a
[server-push]: https://en.wikipedia.org/wiki/HTTP/2_Server_Push

## What frameworks have you used? What are the pros and cons of each? Why do people use frameworks? What kinds of problems do frameworks solve?

很抱歉，本人的前端資歷沒這麼深厚，backbone、Angular 1／2／4 都沒深入研究，只用過 Facebook 出品的 React。以下針對 React 簡單分析。

### Pros

- **生態**
  - 大公司出品，該公司主要的產品皆採用之（Facebook、Instagram），不易突然終止。
  - 廣受業界泛用，是近幾年新產品的主流框架。
  - 社群蓬勃，生態豐富，文檔甚多，甚至有不少 Conference 專門討論 React。
- **程式**
  - 組件化開發，讓不同專案的元素複用變可能。
  - Virtual DOM 架構，減少不必要的 DOM manipulation。
  - One-way binding 的資料流，容易設計架構清楚的 app。
  - 利用 JSX 與 ES6，釋放 JavaScript 最大能量，不必與蹩足的模板引擎溝通。
  - Renderer 與 React Core 分離，**Learn once, write any where** 不再是夢（例如 React Native）。
  - 有完整豐富的生命週期函式供調用。

### Cons

- 開發環境建構複雜，不易上手。（社群有許多 configure-free 的 starter kit／boilerplate 可選用）
- Component-based 的概念顛覆傳統 template 的思維，需要較多學習成本。
- One-way binding 也非傳統前端開發人員熟悉的架構。
- 偏向函數式程式設計的理念讓 OOP 開發者較吃不消。
- 組件化的架構造成某些 data source 需層層傳遞，才能到達實際呈現資料的 component，距離過遙。
- 承上，社群提供許多 State management 供選擇（Redux、Flux、MobX 等），但都是額外的學習成本。

人們使用框架的理由很多，可能是習慣這個開發流程、覺得很潮，或是真的能提升生產力。但在導入框架之前，真的完全理解「框架」是什麼嘛？所謂框架（Framework），和函式庫（Library）的差異可一言以蔽之：

> **With great power comes great responsibility.**
> <!-- -->
> \- _Ben Parker_

一個強大的函式庫如 jQuery、RxJS，不會有太多限制，如同一間圖書館，靜待人們去了解、學習，而後應用。而框架就好比設計完善的課程，按部就班即可有不錯的成果，倘若欲突破框架限制，仍要自己去發掘知識。本人認為兩者思維上的差異就是 **Responsibility**，以 React 來說，設計者不希望開發者直接操作太多 DOM tree ，所以 access DOM tree 便須透過麻煩的 `ref`，降低開發者濫用 DOM tree 的機會，React 因此可好整以暇地管理 DOM tree，權責分明。

引入一個框架，最大的好處就是**開發會遵循明確的規範**，雖然可操作空間被限制了，但也相對責任也輕許多，只要了解該框架，大致上就能理解專案的邏輯，可讀性提昇不少。對我來說，成功的框架，必定有明確清楚的規範，同時也釋放權力給勇於自己負擔責任的開發者，這就是框架最核心的價值之一（當然，效能、延伸性、發展性等等也很重要），也是我們期許臺灣教育能達到的高度。

## Thoughts after completion

這份面試題花了不少時間撰寫，著實問到許多基礎觀念，但並沒有完全切中前端工程的核心或是趨勢，畢竟前端學習點太多了，每個專案碰到的技術可能大相逕庭，例如做 Web Game 的 很懂WebGL，但 CSS 可能不熟。因此，我認為好的題目不僅要能檢核面試者的實力，更要能體現其對前端領域的熱情，例如下列題目：

- 如何實現 SPA 的 router？（理解瀏覽器如何處理 URL，或是有熱情去理解開源的 router library）
- 什麼是 Critical rendering path？HTML 文件如何被解析渲染？（熟悉瀏覽器解析渲染的途徑，並知道如何優化）
- Webpack、Rollup 這些構建工具如何影響前端工程？和 Gulp、Grunt 有啥差異？（知道如何選擇工具，而非追流行）
- 如何管理維護 CSS 命名，並相容不同瀏覽器？（知道目前各大主流管理 CSS 的方式，畢竟 CSS 很容易變成一坨屎）
- 何謂 CORS？何謂 CSRF？（對網路資安至少有點基礎知識）
- 什麼是 Web Components？為什它沒有像 Vue 或 React 一樣火熱？（理解 Web 技術動態，並瞭解流行框架的優勢）
- 如何實現簡單的 Offline web app？介紹一下相關的技術？（知道並能應用 localStorage 等相關知識）

其實上述題目小弟我有些也是一知半解，但我認為面試就是要找**未來**能合作的夥伴，工作熱忱、對未來的洞察力，是否能愉快合作，遠比當下的實力來得重要。感謝讀完這篇文章，希望能對各位有幫助，如果有什麼錯誤，歡迎寄信或~~開炮~~直接留言！

[questions-source]: https://performancejs.com/post/hde6d32/The-Best-Frontend-JavaScript-Interview-Questions-(written-by-a-Frontend-Engineer)
[reddit-frontend]: https://www.reddit.com/r/Frontend/comments/6knex6/the_best_frontend_javascript_interview_questions/
