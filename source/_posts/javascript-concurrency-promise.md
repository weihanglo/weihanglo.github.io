---
title: Modern Concurrency in JavaScript - Promises
tags:
  - JavaScript
  - Concurrency
  - Promise
  - Front-end
date: 2017-06-12 23:02:43
---

![](https://cdn.rawgit.com/promises-aplus/promises-spec/master/logo.svg)

所謂良好的使用者體驗，有個基本要求：「能即時回饋使用者的互動」。在 Mobile Native，常利用多線程（Multi-threading）分散主線程（main thread）的負擔，讓其能即時響應使用者點擊等事件。反觀 web 端的霸主 JavaScript，卻是易被阻塞的單線程（single-threaded）語言，不過藉由 Event Loop 的設計，仍可達成非同步操作，線程不至完全阻塞，或多或少彌補了單線程的不足。

眾所周知，[Concurrency is hard！][concurrency-joke]設計不良的非同步程式，絕對會讓你痛不欲生。本文將簡單介紹 **Promise** 這個現代 JavaScript Concurrency Features，讓 JS 新標準帶你從地獄回到~~另一個煉獄~~人間。

_（撰於 2017-06-12，基於 ECMAScript 6+）_

<!-- more -->

## Definition

Promise 是一個非同步操作的代理物件（proxy object），表示這個非同步操作在未來終將實現（或產生錯誤），並同時取得該操作的結果值。Promise 並不侷限在 JavaScript 中，它是一個概念，有時候又稱為 Deferred、Future，[維基百科][wiki-promises]有詳盡的介紹。

## Features

Promise 是 ES6 引入的標準之一，主要實踐了 [Promise/A+][promisesaplus] 組織訂定的標準，該標準平息了社群長期對 Promise 實作的爭論，使得各家的非同步操作終於有了相同的 API。以下是個人認為 ES6 Promise 的幾個重要特色：

- 截止當前（2017.6），Promise 在瀏覽器的支援程度[已接近 90%][caniuse-promise]。（主流瀏覽器僅 IE 11 不支援）
- 統一、可預期的 callback 調用與 error handling 流程。
- callback 定義清楚完善，沒有重複調用或改變狀態的疑慮。
- 將有序的 promises 串連起來（promise chaining），解除 callback hell 問題。
- 可自由組合多個 promises（promise composition)，實作 sequential 或 paralleling 的 promise chain。

## Terminology

開始之前，先了解 Promise 相關的術語：

- **promise**：一個 object 或 function，帶有符合 [Promise/A+][promisesaplus] 規範中的 `then` method。
- **thenable**：有 `then` method 的 object 或 function。
- **value**：任何合法的 JavaScript 值（`undefined`, **thenable**, **promise** 皆為合法的 value）。
- **reason**： promise 被 reject 的理由所包含 value，通常是 `Error` object。

## Promise States

Promise 字面上的意思為「承諾」，實際上就是一種「保存非同步操作結果」的 object。一個 Promise 建構完成後，必為下列三種狀態之一：

- **pending**
  - 狀態未定，之後狀態會轉移至 **fulfilled** 或 **rejected**。
- **fulfilled**
  - 狀態已定，無法再轉移至其他狀態。
  - 必須帶有一個 identity immutable 的 value（`===` 相等）。
- **rejected**
  - 狀態已定，無法再轉移至其他狀態。
  - 必須帶有一個 identity immutable 的 reason。

另外有個常提及的狀態，其實是個集合名詞：

- **settled**/**resolved**
  - 狀態已定，可能是 **rejected** 或是 **fulfillled**。

> Promise 的 state 一旦 resolved／settled，就無法再次改變狀態，這是 promise 非常重要的核心概念，也是給開發者安心的一個承諾。

## Give Me a Promise

了解 Promise 物件有什麼 state 之後，我們來學習如何建構一個 Promise。一個標準的 Promise 結構大致如下。

```javascript
const promise = new Promise((resolve, reject) => {
  // if success
  resolve(value)
  // else failure
  reject(someReason)
})
```

Promise 的建構式僅需一個 function parameter，而這個 function param 則帶有兩個 callback 性質的 function params（`resolve`、`reject`），這兩個 function params 的作用是「將 Promise 的 state 從 pending 轉移至 resolved／rejected」，主動調用時機如下：

- 當操作成功執行...
  - 主動調用 `resolve` 並傳入合法的 value。
  - 該 promise 狀態轉移至 **fulfilled**。
- 若失敗或出現例外...
  - 主動調用 `reject` 並傳入失敗的 reason。
  - 該 promise 狀態轉移至 **rejected**。

於是，可以很容易將傳統的 callback XHR 改寫成 promise 版本。

```javascript
// The old way
  const xhr = new XmlHttpRequest()
  xhr.open('GET', someURL)
  xhr.onload = () => response(xhr.responseText)
  xhr.onerror =  () => error(new Error (xhr.statusText))
  xhr.send()
}

// Promise version
const promise = new Promise((resolve, reject) => {
  const xhr = new XmlHttpRequest()
  xhr.open('GET', someURL)
  xhr.onload = () => resolve(xhr.responseText) // 調用 resolve，狀態變為 resolved
  xhr.onerror =  () => reject(new Error (xhr.statusText)) // 狀態變為 rejected
  xhr.send()
})
```

慣例上，會將 promise 包在一個 factory function 中，方便建構新的 promise。

```javascript
// 簡單的 http GET request promise version
function get (url) {
  return new Promise((resolve, reject) => {
    const xhr = new XmlHttpRequest()
    xhr.open('GET', url)
    xhr.onload = () => resolve(xhr.responseText)
    xhr.onerror =  () => reject(new Error (xhr.statusText))
    xhr.send()
  })
}
```

乍看之下，Promise 似乎比較複雜，但經過這些包裝後，再利用即將介紹的 `then` method ，產生可預期的非同步結果，promise 對調用者來說 ，絕對比起傳統 callback 更為穩健。

## The `then` method

Promise 的 `then` 是 promise 最核心的元素，本質上就是「替 promise instancestate 添加 state 改變時的 callback function」。 method signature 如下

```javascript
// return a Promise instance
promise.then(onFulfilled, onRejected)
```

其中 `onFulfilled`、`onRejected` 為兩個 callback，執行時機為 state 轉移：

- **pending -> fulfilled**: `onFulfilled`
- **pending -> rejected**: `onRejected`

利用上一節透過 promise 包裝後的 XHR，實際看看 `then` 該如何用

```javascript
get('http://httpbin.org/get').then(
  // promise state 轉換為 fulfilled 時，執行 onFulfilled callback
  value => { // value 為 promise 建構時，由 resolve(value) callback 傳入
    console.log('I am resolved :)', value)
  },
  // promise state 轉換為 rejected 時，執行 onRejected callback
  error => { // error 為 promise 建構時，由 reject(error) callback 傳入
    console.log('I am rejected :(', error)
  }
)
```

另外，`onFulfilled` 與 `onRejected` 兩個 callback 皆為 optional，我們可以只處理 success 的 case，也可以單純 handle errors。

```javascript
// 忽略 error
get('http://httpbin.org/get')
  .then(console.log)

// 只處理 error
get('http://httpbin.org/get')
  .then(null, console.error)

// 只處理 error 也利用 `.catch` syntax sugar
get('http://httpbin.org/get')
  .catch(console.error) // === .then(null, console.error)
```

> `Promise#catch` 同義於 `then` 的第一個參數傳入 `null` -> `Promise#then(null, onRejected)`

## Promise Chaining

[Promise/A+][promisesaplus] 規範中，明確定義 `then` method 必須回傳一個 **promise** instance，使得 promise 可透過類似 functional programming 的鏈式操作，減少不必要的變數，讓程式碼一氣呵成，增加可讀性。

```javascript
const promise = new Promise((resolve, reject) => { // 1
  // heavy computation...

  resolve(1)
  // reject(new Error())
})

const promise2 = promise // 2
  .then(value => {
    console.log(`newValue === ${value}`)
    // newValue === 1
    return newValue + 1
  })

promise2.then(newValue => { // 3
  console.log(`newValue === ${newValue}`)
  // newValue === 2
})
```

> - 上例（1）中，我們創建了一個 promise instance，經過負責運算，value `resolve` 為 1，狀態變為 fulfilled。
> - 在（2），我們調用該 promise 的 `then` method，將 `newValue` + 1 並回傳，這個 `newValue + 1` 將成為下一個 chained promise 在 `onFulfilled` callback 會取得的 value。
> - 在（3）又串連一個（2）回傳的 `promise2`，並將取得的 `newValue` log 出來，得到 `2`。


我們可以看見，promise chaining 的 value 是透過 `return` keyword 來傳遞。以下講解不同的情況：

**當 promise 執行成功**
- 若 `onFulfilled` 回傳一個 value，
  - `then` 回傳由該 value fulfilled 的 promise。
- 若 `onFulfilled` 回傳一個 `thenable` 或 `promise`，
  - 將嘗試 resolve 該 `thenable` 或 `promise`，取得其 result 並回傳由該 value fulfilled 的 promise。
- 若 `onFulfilled` 執行發生錯誤，
  -  `then` 回傳的 promise 會被該 error reason rejected。

**當 promise 執行失敗**
- 若 `onRejected` 回傳一個 value，
  - `then` 回傳由該 value fulfilled 的 promise，**錯誤不繼續傳遞**，也稱為 promise  recovery。
- 若 `onRejected` 回傳一個 `thenable` 或 `promise`，
  - 將嘗試 resolve 該 `thenable` 或 `promise`，取得其 result 並回傳由該 value fulfilled 的 promise。
- 若 `onRejected` 執行發生錯誤，
  -  `then` 回傳的 promise 會被該 error reason rejected。

在這附上 MDN 的流程圖示：

![](https://mdn.mozillademos.org/files/8633/promises.png)

> 簡之，`onFulfilled`、`onRejected` 這兩個 callback 若有 return value，皆回傳帶有該 value 的 fulfilled promise。
>
> 若執行過程中有 Exception，無論是否為自行拋出，皆回傳的 rejected promise，並帶有該 Exception。


我們再看一個複雜一點的例子，利用 [MDN fetch API][mdn-using-fetch] 來解釋

```javascript
fetch('flowers.jpg') // 0 (first async)
  .then(response => { // second async
    if(response.ok) { // 1
      return response.blob() // 2
    }
    throw new Error('Network response was not ok.') // 3
  })
  .then(blob => { // third async
    var objectURL = URL.createObjectURL(blob) // 4
    myImage.src = objectURL
  })
  .catch(err => { // first catch
    console.log(`Your fetch operation failed: ${error.message}`) // 5
  })
  .then(() => { // final async
    console.log('All done!') // 6
  })
```

（0）`fetch` 這個 function 傳入 URI，回傳一個 promise

（1）若執行成功，`then` 接受到 fulfilled 的 value（response），並檢驗 response 的 status。

（2）若 status 為 ok，嘗試透過 `blob` method 將 response 轉換為 blob（回傳一個 promise resolved with blob）。

（3）如果 status 檢驗不成功，則直接拋出錯誤，該 `then` 回傳一個被該錯誤 rejected 的 promise 。

（4）若第一個 `then` fulfilled，執行這個 then 的 `onFulfilled` callback，並將 blob 轉換為 url。

（5）若上述任一步驟出錯，error 會繼續往下傳遞，直到被實作 `onRejected` callback 的 handler 捕捉。（本例為（5）的 `catch`)。

（6）若沒有錯誤，最終將執行這個 callback；由於（5）的 catch 回傳了一個 recoverable promise（回傳 `undefined`，無 throw error），因此就算（5）的 catch 有捕捉到 error ，仍然會執行（6）的 callback。

<img src="promise-flow.png" height="300px" />

### Promise Chaining Flow

這裡參考 [Google Web Fundamentals - Promises][google-promises] 一章的範例，作為 Promise Chaining 的總結，圖中的紅色箭頭代表 rejected，藍色代表 fulfilled（recovery），碼、圖和著看，非常清楚。

有幾點再次提醒：

- 若 return 一個 `thenable` 或 `promise`，則等待該 value 被 resolve（類似 sequential promise composition）。
- 只要沒有 handler 實作 `onRejected` callback，promise 就會不斷往後傳遞 error。
- 任何 code block 拋出 Exception 例外，都會造成該 promise 被 reject。
- 任何 code block 成功 return 一個 value，都會使得該 promise 被 fulfill。

```javascript
asyncThing1().then(function() {
  return asyncThing2()
}).then(function() {
  return asyncThing3()
}).catch(function(err) {
  return asyncRecovery1()
}).then(function() {
  return asyncThing4()
}, function(err) {
  return asyncRecovery2()
}).catch(function(err) {
  console.log("Don't worry about it");
}).then(function() {
  console.log("All done!");
})
```

<img src="google-promises.png" height="600px" />

> `Promise#catch` V.S. `Promise#then(null, onRejected)`
>
> 還記得 `then` method 第二個參數是 `onRejected` callback 嗎？這個參數其實比較少用，大部分都會透過 `.catch` 這個 syntax sugar 做 error handling。因為 `onRejected` 僅在當該 promise 被 reject 時，才能捕捉到錯誤，並無法捕捉到同一個 `.then` 的 `onFulfilled` 拋出的錯誤。

<!-- -->

> 此外，讓 `then`、`catch` 分別對應處理 `fulfilled` 與 `rejected` 兩個不同的 state 的 promise，可以提高程式碼的可讀性，更接近 synchronous 的 `try...catch` 寫法。本人建議使用 `catch` 取代 `onRejected` callback。

## Static Methods

標準規範中，Promise 共有四個 static method：

- `Promise.resolve(value)`
- `Promise.reject(reason)`
- `Promise.all(iterable)`
- `Promise.race(iterable)`

### `reject` & `resolve`

其中，`Promise.reject` 與 `Promise.resolve` 相對單純，就是產生一個直接 rejected 或 fulfilled 的 promise。

```javascript
Promise.resolve()
  .then(value => console.log('Immediate resolved!'))

Promise.reject(new Error('Error!!!')).
  .then(() => { /* will not go here */ })
  .catch(err => console.log(`Error shows up here ${err}`))
```

### `all` & `race`

而 `Promise.all` 與 `Promise.race` ，屬於 high order 的 method ，參數為 promise instances array（iterable），回傳一個 promise，其 fulfill 與 reject 的條件如下

- `Promise.all`
  - fulfill：所有傳入的 promises 皆 fulfill。Resolved value 為與傳入的 promises 相同順序 value array。
  - reject：任一個 promise 被 reject 即 reject。Error reason 為與第一個被 reject 的 promise 相同。
- `Promise.race`
  - 任何一個 promise 被 resolve，無論是 fulfill 或 reject，皆回傳該 resolved promise。

### Paralleling Composition

利用 `Promise.all`，配合 function programming 的 `map` 技巧，我們可以達到 paralleling 的 promise 操作，例如：

```javascript
const getImageURL = category => (
  fetch(`http://lorempixel.com/400/200/${category}/`)
    .then(() => response.blob())
    .then(URL.createObjectURL)
)

const imgElements = document.querySelectorAll('img')

Promise.all(
  // 利用 map 建構 Promises Array
  ['cats', 'sports', 'food'].map(getImageURL)
).then(imageUrls => {
  // 將 urls 添加到 img element 上
  imageUrls.forEach((url, i) => {
    imgElements[i].src = url
  })
})
```

為什麼 `['cats', 'sports', 'food'].map(getImageURL)` 會是 parallelism 呢？

因為 `Array#map` 之中的 每個 element 皆為獨立建構，`Promise` 一旦建構了（調用 fetch 會建構 promise），就會嘗試 resolve，也就達到發送 paralleling requests 的目的。

### Sequential Composition

有時候，我們並不需要 parallelism，而是 sequential 的 promise 操作，例如，facebook 讀取動態時，希望動態依照時間順序讀取，既然無法使用 `Array#map`，用 `Array#forEach` 總行了吧？

```javascript
function loadStatus (statusId) {
/* async load status, return a Promise */
}

function addStatusToPage () {
  /* add status to page */
}

let sequence = Promise.resolve()
const statusIds = [1234, 5678, 2468]

// forEach 版本的 sequential promise chain
statusIds.forEach(id => { // iterate 所有 id
  sequence = sequence.then(() => ( // 1, 3
    loadStatus(id)
  )).then(addStatusToPage) // 2
})
```

上例比較複雜，以下一一說明：

（1）從 sequence 調用 `then`，chain 一個新的 promise，

（2）再 chain 一個 promise，

（3）最後將 sequence 變數，指向這個 新 chained 的 promise sequence。

最後，這個 sequence chained 起來會像這樣：

```javascript
Promise.resolve()
  .then(() => loadStatus(1234))
  .then(addStatusToPage)
  .then(() => loadStatus(5678))
  .then(addStatusToPage)
  .then(() => loadStatus(2468))
  .then(addStatusToPage)
```

不過，比起 imperative 的 `Array#forEach` ，近來崇尚 declarative 的寫法，這裡使用 `Array#reduce` 取代。

```javascript
// reduce 版本的 sequential promise chain
statusIds.reduce(id => (
  loadStatus(id)
    .then(addStatusToPage)
), Promise.resolve())
```

程式碼又更簡潔明瞭一些了，也免去宣告額外的變數來保存 promises，很棒！

### First Fullfillment

`Promise.race` 提供開發者取得首個 resolved promise 的 result，但有時候，我們只想取得第一個 fulfillment，不想理會其他 rejection，該如何實作呢？

許多 Promise library 提供 [`Promise.any`][bluebird-promise-any] 這樣的 API，當然也可以自己實作，[Stackoverflow 的答案非常簡潔][stackoverflow-promise-any]，直接附上程式碼。

```javascript
// from Stackoverflow https://stackoverflow.com/a/39941616
const invert = p  => new Promise((res, rej) => p.then(rej, res))
const firstOf = ps => invert(Promise.all(ps.map(invert)))
// ...
```

說明：利用 Promise.all 會因為任一個 promise rejected 而被 reject 的特性，調換 onRejected 與 onFulfilled 這兩個 callback。達成「取得首個 fullfilled promise」的任務。

## Some Issues

我們現在看到的 Promise 是經過百家爭鳴、戰國時代，各方不斷磨合下的產物，雖說 Promise 已是 Modern Front-end 必須理解的基本概念，但其仍有許多改進與討論的空間，以下舉幾個例子：

### Cancelable Promises

傳統 XHR 可以透過 `XmlHttpRequest#abort` 達到 cancel 取消的操作，Promise 也有此意實作 **Cancelable Promises**，不過很可惜的是，[這個提案][proposal-cancelable-promises] 沒能到達 Stage 2 就被撤銷了，也引起[諸多討論][hackernews-cancelable-promises-withdrawn]，不論是否無法達成共識，或有更好的方案，短期內應該看不到此 feature 納入標準了。倒是可參考 [RxJS][rxjs] 的大頭 Ben Lesh 提出[實作與解決 promises cancellation 的方法][benlesh-promise-cancallation]，當然，少不了推崇一下強大的 Rx Library 啦。

### Proposals for `Promise#finally` & `Promise#try`

雖然 cancelable promise 已 withdrawn，仍有人希望原生的 Promise 能有更多實用的 API，[`Promise#finally`][proposal-promise-finally] 與 [`Promise#try`][proposal-promise-try] 便是一例，`Promise#finally` 是希望替 promise 提供類似 try-catch-finally 的 finally block，實作一些 cleanup，目前已在 Stage 2，很有希望成為標準；而 `Promise#try` 則是希望將 promise 起始的 function 也包含進 promise 的 error handling 機制，統整同步與非同步的例外處理，類似 try block，目前在 Stage 1 等著，[詳細解釋在此][joepie-promise-try]。

### Difficult to Debug

由於 Promise 是由許多 closure combine 而成，會產生不少 call stacks，一旦發生 error，stack trace 會夭壽混亂，也不易設置 breakpoint 動態 debug。有一解法是給 anonymous function 一個 name。

```javascript
Promise.resolve()
  .then(function doAsyncThing1 () {})
  .then(function doAsyncThing2 () {})
  .then(function doAsyncThing3 () {})
```

但這樣就無法使用 ES6 的 Arrow function 了，也失去 promise 的簡潔特性，算是一種 tradeoff。

此外，Promise 由 `then` 第二個參數 `onRejected` callback 全權接管 Error Handling，傳統的 try-catch 在此完全不管用，同步／非同步的例外處理距離變遠，可能造成邏輯較為複雜。而且，若無顯式處理被 reject 的 promise，該 Exception 就不會 propagation 到 promise 外部，過於 silent 也是一件壞事（We should let it crash！）。

### Not Synchronous Enough

Concurrency 一直是程式設計最難的議題之一，很多人期盼有一天，我們能夠用最直觀最 synchronous 的 syntax 書寫 asynchronous code。**C#** 的 `async/await` 是主流語言中，算是第一個成功使用 synchronous syntax 的範例。看那優美的書寫方式，

```csharp
// 亂寫的 C# code
public async Task AsyncFunction()
{
  await AsyncTask();
  await AnotherAsyncTask();
}
```

JavaScript 的 Promise 立馬被擊潰。（本人一行 **ㄈ井** 都不懂）

不過 JS 社群近年來蓬勃發展，ES7 已經導入了 `async/await` 關鍵字，又替非同步程式設計帶來新變革，語法堪稱小清新。

```javascript
// async function
function async request () {
  try {
    const json = await getJSON()
    const data = JSON.parse(json)
    console.log(data)
  } catch (err) {
    console.log(err)
  }
}
```

至今，已有[七成六][caniuse-await]的瀏覽器實作 Async function，Node.js 也在 7.6 解除 async function 的 harmony flag，成為 default 的關鍵字，拭目以待吧！

## Further Reading

Promise 是 Modern JavaScript 最為關鍵的一個變革，大大降低非同步前端工程的開發門檻，也成為前端工程師必備技能之一。本篇僅淺淺帶過 Promise 的概念，如果要完全了解 Promise 的概念，一定要將 [Promise/A+][promisesaplus] 的規範通讀一遍，非常精練，不到半小時便能讀完，絕對豁然開朗，其他 promise 文都可以跳過了呢！

[Google 的 Promises 入門][google-promises]也很有意思，從人們想像中的 promise 講起，一步步深入了解 promise 的核心理念，最後甚至比較了 callback、promise、generator、async function 四種非同步程式設計的寫法，值得一看。

知名的 Database Solution [PouchDB][pouchdb] 的部落格也有一篇文章，點出[使用 promises 常見的錯誤][pouchdb-promises-problem]，雖然是 2015 年的舊文，範例也是用自家 PouchDB 的 API，但概念都相同，可以瞧瞧別人究竟踩過什麼坑，順便 review 一下自己的 code。

如果覺得外國的月亮沒有比較圓，想要看一些中文的 References，這本「[從Promise開始的JavaScript異步生活][eyesofkids-javascript-start-es6-promise]」（中英文中間是不會留空白逆= =）寫得非常詳細；另外，阮老師的 「[ECMAScript 6 入门：Promise 对象][ruanyifeng-es6-promise]」份量也很足，兩者都十分值得一讀。基本上，挑其一，就可以完全忽略本人的文章了。

前端技術日新月異，非同步程式設計發展如斯，相信工程師們加班的時間會越來越少吧（但學習新技術的時間需要越來越多⋯⋯)。

![A programmer had a problem. He thought to himself, "I know, I'll solve it with threads!". has Now problems. two he](http://i.imgur.com/G3X0H78.jpg)

> 後記：眼尖的童鞋應該會發現本篇毫無提及 generator 等非同步的實作，因為本人認為 generator async 實作的太抽象了，學習成本太高，用 promise 和 async function 不就很舒服了嗎XD（不過，利用 generator 實作 async function 又是另一回事了）

## Reference

- [Promise/A+][promisesaplus]
- [MDN - Using promises][mdn-using-promises]
- [Google - JavaScript Promises: an Introduction][google-promises]
- [從Promise開始的JavaScript異步生活][eyesofkids-javascript-start-es6-promise]
- [ECMAScript 6 入门：Promise 对象][ruanyifeng-es6-promise]

[concurrency-joke]: https://twitter.com/davidlohr/status/288786300067270656
[wiki-promises]: https://en.wikipedia.org/wiki/Futures_and_promises
[caniuse-promise]: http://caniuse.com/#search=promise
[promisesaplus]: https://promisesaplus.com/
[mdn-using-promises]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises
[mdn-using-fetch]: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
[google-promises]: https://developers.google.com/web/fundamentals/getting-started/primers/promises

[stackoverflow-promise-any]: https://stackoverflow.com/a/39941616
[bluebird-promise-any]: http://bluebirdjs.com/docs/api/promise.any.html

[proposal-cancelable-promises]: https://github.com/tc39/proposal-cancelable-promises
[hackernews-cancelable-promises-withdrawn]: https://news.ycombinator.com/item?id=13210849
[rxjs]: https://github.com/ReactiveX/rxjs
[benlesh-promise-cancallation]: https://medium.com/@benlesh/promise-cancellation-is-dead-long-live-promise-cancellation-c6601f1f5082



[proposal-promise-finally]: https://github.com/tc39/proposal-promise-finally
[proposal-promise-try]: https://github.com/tc39/proposal-promise-try
[joepie-promise-try]: http://cryto.net/~joepie91/blog/2016/05/11/what-is-promise-try-and-why-does-it-matter/
[caniuse-await]: http://caniuse.com/#search=await
[pouchdb]: https://pouchdb.com/
[pouchdb-promises-problem]: https://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

[eyesofkids-javascript-start-es6-promise]: https://www.gitbook.com/book/eyesofkids/javascript-start-es6-promise/details
[ruanyifeng-es6-promise]: http://es6.ruanyifeng.com/#docs/promise
