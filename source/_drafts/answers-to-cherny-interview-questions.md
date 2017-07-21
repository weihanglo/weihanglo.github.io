---
title: Answers to Cherny's Interview Questions
tags:
  - Interview question
  - JavaScript
  - Front-end

---

# Answers for **The Best Frontend JavaScript Interview Questions - Concepts**

這份面試題出自[於此][questions-source]，是從 [/r/Frontend/][reddit-frontend] 連結過去的，看到如此自豪的標題和簡介，便手癢來作答。結果寫完基礎概念篇，才發現這份題目在 reddit 上被慘烈地批評，與現代前端技術棧相差頗大，不過，還是考到一些核心概念。在此分享我的答案，有任何錯誤，請各位大大不吝賜教。

_（撰於 2017-07-21）_

## Concepts

Be able to clearly explain these in words (no coding):

#### What is Big O notation, and why is it useful?

Big O notation 是用來分析演算法複雜度的漸近符號，可以簡單視為**運算成本（時間、空間）與輸入資料量的趨勢函數**，例如 f(x) = x^2 + 3x + 6。當輸入資料量增大時，函數的「最高次項」最具有決定性，因此可以之表示演算法在資料量夠大時，「最多」達到怎樣的趨勢（趨勢上界），例如上例的複雜度會是 f(n) = O(n^2)。（另有 Big-Theta、Big-Omega 分別描述「趨勢區間」與「趨勢下界」）

Big O 以宏觀的角度來分析演算法，並利用簡單的數學式表示，令演算法效率分析有簡明、客觀的基準。

#### What is the DOM?

全名為「Document Object Model」，是 W3C 的標準之一，定義如何將文件（XML／HTML document 等）映射至一樹狀結構中，每個節點都是一個物件，並帶有操作此 DOM node 的 API。

#### What is the event loop?

JavaScript 是單執行緒（單線程）的程式語言，任何龐大運算都可能阻塞整個程式，因此 JavaScript 設計了 **message queue** 配合一個不間斷的 **event loop** 來管理任務，當 call stack 沒有執行任何 task 時（程式閒置時），loop 便從 queue 中取第一個 message 至 call stack 調用。開發者可將 callback 加入 message queue 等待 loop 輪詢（polling），實現非同步程式，這就是 JavaScript event loop 的機制。

實際上 event loop 的概念並不僅限於 JavaScript，其他語言的 main loop 或像 iOS／macOS 的 `NSRunLoop` 都是建立在此概念之上。

#### What is a closure?

在某些函式（function）為一等公民（可來傳遞、當作引數）的程式語言中，**閉包（closure）是一種特殊的函式，會儲存／綁定該詞法作用域（lexical scope）下被引用的變數資訊**，如綁定閉包內被引用的外部變數，讓 closure 可以使用這些變數，這種儲綁定外部變數的行為稱為 capture，被儲存的變數一般稱 captured／free／bound variable。

由於這些外部變數被 closure 綁定，因此可以在這些變數宣告的作用域外執行 closure 並使用這些 variables，，所以 closure 廣泛應用於程式區塊間互相傳值／通訊，例如非同步常使用的 callback function，經常會是一個 closure。近幾年函數式程式設計（functional programming）當紅，高階函式（higher-order function）的函式參數（function parameter）也是一種常見的 closure。Functional programming 另一個技法 **currying**（將多參函式轉換為單參函式），同樣利用了 closure 捕獲 variables 的特性。當然，最常見的 `setTimeout`、`setInterval` 就是 closure 的最佳範例。

需注意的是，由於不同語言的記憶體管理方式有差異，binding free variable 的實作也不盡相同，目前記憶體管理方式，大致上分為 reference counting（RC）與 garbage collection（GC），若是以 RC 管理記憶體的語言（如 Swift、Objective-C），需注意 reference count 在 closure 內部可能會增加，部分語言需要手動 release reference。

#### How does prototypal inheritance work, and how is it different from classical inheritance? (this is not a useful question IMO, but a lot of people like to ask it)

JavaScript 的物件導向概念是基於「原型（prototype）」而設計，有別於其他基於類別（class）的語言，其中最大的差異就是 prototype-based 的物件導向並無 class 概念。我們可將傳統的 class-based 的 class 想像成藍圖，實例（instance）是依照此藍圖創造出來（實例化，instantiation）；而 prototype 則較接近桃莉羊，概念類似於從已知實例創造出新的實例，共享（或複製）原始來源的特性。

Prototype-based 的語言雖沒有真正的 class，但會有類似建構子（constructor）的方法／函式，創建實例是，同時將原型物件的屬性／方法（property／method）複製或引用一份。例如 JavaScript 中每個物件皆有 `prototype` 這個原型物件，**所有透過建構子實例化的實例，都可以從自身的屬性，取得該原型物件的同名的屬性**。要注意的是，有些實例的屬性可能是一個引用（reference），直接指向原型物件對應的屬性，修改可能會使其他實例受影響。比較常見的做法是**繼承建構子**，或是**複製整個原型物件**。

> ES2015 提供以傳統物件導向語法 `class extends` 完成繼承的語法糖，本質上仍是 prototypal inheritance，但相對門檻較低，程式碼也比較直觀。

#### How does `this` work?

當一段 code 被 JavaScript 執行時，會創建新的執行上下文（execution context），在創建之初就會綁定 `this` 的值（還有變數與作用域鍊），接下來才執行程式碼。要知道 function 的 `this` 指向何者，就要了解創建 context 時是 function 如何被調用。一般來說，以下幾種狀況便可涵蓋大多數的情境。

| 情境                        | `this` 指向                  |
| :------------------------- | :--------------------------- |
| 在全域直接調用一個 function   | `window` 或 `global`（node）  |
| 調用物件的方法 `obj.method`  | 該物件                        |
| function.call／bind／apply  | 被綁定的物件                  |
| 透過 `new` 調用 constructor  | 新創建的物件                  |
| ES6 arrow function         | 該詞法作用域下的 `this`（較直觀）|   


#### What is event bubbling and how does it work? (this is also a bad question IMO, but a lot of people like to ask it too)

JavaScript DOM Event 的傳遞會經過三個階段：

- **capture phase**
- **target phase**
- **bubbling phase**

當一個事件觸發時，會從 `window` 往 DOM tree 傳遞，從 tree root（document）往下找，直到監聽該事件的 Event target，這個階段就是 **capture phase**，到達 Event target 則稱之 **target phase**。在這之後，event 會像冒泡泡板開始往上傳遞，傳遞到 `window` 為止，這就是 **bubbling phase**。JavaScript 的 Event listener 預設是在 bubbling phase 捕捉事件，所以當 Event Listener 沒有終止事件傳遞（`Event#stopPropagation`），其父元素若有監聽事件，就有機會捕捉到該事件。

#### Describe a few ways to communicate between a server and a client. Describe how a few network protocols work at a high level (IP, TCP, HTTP/S/2, UDP, RTC, DNS, etc.)

#### What is REST, and why do people use it?

（聲明：本人錯過 SOAP 的年代，實務上只使用過 RESTful 架構）  

**REST（REpresentational State Transfer）**是眾多網路軟體架構中的一種，以結構清晰簡潔著稱，目前主流的網路服務都以此風格架設，大致實作概念為：

- 所有資源以 URI 表示。（resource-oriented）
- 資源可以不同的形式表現（例如 XML 或 JSON），取決於客戶端環境、headers 設定等。
- 使用標準 HTTP request method（GET、POST、PUT、DELETE 等）對資源進行不同的操作。

由於透過標準 HTTP protocol 實現 RESTful 架構，一切 request 都是無狀態（stateless），因此有許多優點：

- stateless，可以利用 cache 機制。
- stateless，容易用各種工具調試（如 cURL、httpie）。
- 每個 request 都獨立，耦合性低。
- 利用 URI，統一 API 接口定義。

> 因為 RESTful 以資源為導向的風格，後端常會為了日益增長的需求，開發了許多大同小異的 API，新興的 [GraphQL](graphql.org) 就是為了對付這種問題，日前漸漸發展起來。

#### My website is slow. Walk me through diagnosing and fixing it. What are some performance optimizations people use, and when should they be used?

（講一個 slow 是能看出什麼毛喔⋯⋯）

看 Request 多打包


#### What frameworks have you used? What are the pros and cons of each? Why do people use frameworks? What kinds of problems do frameworks solve?

React

[questions-source]: https://performancejs.com/post/hde6d32/The-Best-Frontend-JavaScript-Interview-Questions-(written-by-a-Frontend-Engineer)
[reddit-frontend]: https://www.reddit.com/r/Frontend/comments/6knex6/the_best_frontend_javascript_interview_questions/
