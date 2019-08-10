---
title: 現代化的 JavaScript 併發 - Async Functions
tags:
  - JavaScript
  - Concurrency
  - Async Function
  - Generator
  - Front-end
date: 2017-06-18T12:45:34+08:00
---


在前一篇介紹 [JavaScript Concurrency 的文章][weihanglo-promise]中，Promise 提供開發者安全統一的標準 API，透過 `thenable` 減少 callback hell，巨幅降低開發非同步程式的門檻，大大提升可維護性。不過，Promise 仍沒達到 JS 社群的目標「Write async code synchronously」。本篇文章將簡單最新的 Concurrency Solution「Async Functions」，利用同步的語法寫非同步的程式，整個人都變潮了呢！

_（撰於 2017-06-17，基於 ECMAScript 7+）_

<!-- more -->

## Introduction

[Async Functions][async-functions] 在去年進入 Stage 4，正式成為 ECMAScript 7 標準，這對 JS 社群無疑是一大利多。截至目前為止（2017.6），實作 Async Functions 的環境有：

- Node.js 7.6.0 (without `--harmony`)
- Chrome 55
- Firefox 52
- Safari 10.1
- Edge 15

可以看到[當前 Release 版的 Desktop browser 都可以用了][caniuse-async-functions]。

從此我們不會在 callback hell 中迷失自我，不需在 `then` 中塞一堆 `console.log`，也不需使用蹩足的 generator 語法。ES7 的 `async function` 完成我們對非同步程式的想像。

**真的有這麼好康嗎？**

[MDN][mdn-async-funciton] 點出 async function 的定位。

> The purpose of async/await functions is to simplify the behavior of using promises synchronously and to perform some behavior on a group of Promises. Just like Promises are similar to structured callbacks, async/await is similar to combining generators and promises.

Async functions 的目的在於簡化多個 promise 操作，不需要再串聯一堆 `then`。如果我們將 Promises 比喻為好讀版的 callbacks，那 async／await 就是 generator + promise 的綜合體，因此，**我們仍需學習 promise 以及 generator 等概念**。

話不多說，一起快速了解 generator 吧！

## Generator With Async Operations

在 async／await 還沒出世之前，generator function 是非同步程式設計的最新潮的替代品，TJ 的 [co][tj-co] 與 Facebook 的 [regenerator][facebook-regenerator] 這兩個 libraries 都擁有高人氣。藉由 [Coroutine（協程）][wiki-coroutine] suspend／resume 的機制，讓開發非同步 JS 可以避開多線程煩人的 context-switch、dead lock，能用很直觀的方式撰寫程式。當然，coroutine 仍是在同個 thread 上面執行，並非真實的 parallel computing，不過 browser 這種常出現 I／O 的場景中，coroutine 已綽綽有餘了。

**我只是想了解 async function 怎麼用，為什麼還要學 coroutine 和 generator？不會太複雜嗎？**

別緊張，接下來將淺淺帶過 generator 概念。本人同樣不喜歡 generator 醜陋的 `*`，`*` 只該留給最愛的 pointer。介紹 generator 之前，先來了解 ES6 的 **Iterable** 與 **Iterator** 吧 XD！（不是說好快速瞭解 generator 嗎⋯⋯）

### Iterable & Iterator

ES6 除了引入標準的 `Promise` object 以外，另一重大的語法變革就是 [Iterator][mdn-iteration-protocols] 與 [Generator][mdn-generator]。熟悉 C++、Swift、Java 或 Python 3 的朋友應該非常熟悉 iterable／iterator 等名詞。在 JavaScript中，名詞解釋大致如下：

- **iterable** 是指可迭代的物件，也就是可丟進 loop 運作的物件，會產生 **iterator**，但不一定是 [sequence][wiki-sequence] 或 [container][wiki-container]。
- **iterator** 就是鼎鼎大名的迭代器，如同指針般迭代東西（通常是 **iterable** 提供的值）。

日常會遇到的 iterable 應該會長這樣：

```javascript
for (let obj of iterable) {}
iterable.forEach()
iterable.map()
```

這些 **iterable** 有共通特性，就像下面的 list 一樣又臭又長。

- 有一個 `[Symbol.iterator]` method，
  - `[Symbol.iterator]` 會回傳一個 **iterator** object，
    - **iterator** 上要有 `next` method，
      - `next` method 會回傳一個 object 記錄 iteration 當前狀態，其有兩個 property，
        - `done`：當次 iteration 是否結束的 boolean flag
        - `value`：當次 iteration 的 return value

看了這種 nested list，是不是眼睛都茫了，想立馬關掉這篇廢文呢？別怕，常用的 `Array` 和 ES6 的 `Map`、`Set` 等都是內建的 iterable，我們不需自己辛苦實作；而 plain `Object` 雖非 iterable，但也有 `Object.entries` 等方法供我們轉換成 iterable 呢。

我們來看一個簡單 Iterator 實作：

```javascript
const infiniteLoop = {}
infiniteLoop[Symbol.iterator] = function () { // 實作 iterator 建構 funtion
  let v = 0
  return { // 回傳有 `next` method 的 object
    next: () => ({ // 回傳記錄當前 iteration state 的 object
      value: ++v,
      done: false
    })
  }
}

// 無限迴圈
for (let v of infiniteLoop) {
  console.log(v)
}
```

> 有興趣了解相關 protocols，可以[看此][mdn-iteration-protocols]。

### Generator

上一節最後，我們從頭打造了一個 Iterator，看起來十分不易，其實 iterator 實作繁瑣，是每種語言皆然，[連 Python 3 也不例外][python-iterator]，於是，**generator** 就誕生了。 Generator 基於 iterator 概念之上，利用~~簡單明瞭~~的語法，讓建構 iterator 不必這麼痛苦。我們將前一節的例子改成 generator 試試看。

```javascript
function* genFunc () { // `*` 宣告一個 generator function，即是 iterator factory
  let v = 0
  while (true) {
    yield ++v // generator function 的 body 內才能使用 `yield` keyword
  }
}

// 無限迴圈
const g = genFunc() // 產生一個 iterator
let v = g.next() // 取得 iterator 下一個 state
while (!v.done) {
  console.log(v.value)
  v = g.next()
}
```

乍看之下，似乎沒比 iterator 簡單，而且又多了 `function*` 和 `yield`，是要嚇死人嗎？這裡的重點並非語法，而是一開始提及的 [Coroutine][wiki-coroutine]概念。這種 coroutine 的概念與一般逐行執行的程式不同，運作流程如下：

1. 執行到 `yield`，暫停。
2. 將執行權交給外部，等待外部 call `next`。
3. 外部 call `next`，回到步驟一繼續執行。

套在我們的例子中，就是：

- 當每次 `genFunc` 執行到 `yield` 時，會停下來，
- 將程式執行權交給外部 caller，
- 等到外部調用者再次 call `next` method，`genFunc` 再接著執行。

簡而言之，**「Generator 是 coroutine 的一種形式，是一個 pause／resume 的執行流程」**。但這樣到底與非同步程式設計有啥鬼關係？

重點在於「透過 coroutine 將程式執行權交給外部 caller」，這可好玩了，如果我們讓 `yield` 返回一個 promise，程式執行權就會回到 caller 上，而 caller 不僅有程式執行權，可以執行其他程式片段，也可以取得非同步操作的結果。想像中的程式碼長這樣：

```javascript
// 想像中的程式碼
// fetch 是一個 promise-based 非同步 function
function* asyncFunc () {
  const a = yield fetch('a')
  console.log(a)
  const b = yield fetch('b')
  console.log(b)
}
```

看起來非常驚人！可惜這是虛擬的程式碼，`a`、`b` 都是一個 Promise，需要利用 `then` method 取得 resolve value。不過，JS 社群當然不會放過 generator 這個裝逼的好工具，大神們透過各種奇淫巧技，讓我得以利用 generator 優美地寫出 synchronously asynchronous code，以下這個例子便是透過 `spawn` 自動執行 `next` 的 helper function 達成。

```javascript
// Helper Function
// from: Jake Archibald - JavaScript Promises: an Introduction
function spawn (generatorFunc) {
  function continuer (verb, arg) {
    var result
    try {
      result = generator[verb](arg)
    } catch (err) {
      return Promise.reject(err)
    }
    if (result.done) {
      return result.value
    }
    return Promise.resolve(result.value).then(onFulfilled, onRejected)
  }
  var generator = generatorFunc()
  var onFulfilled = continuer.bind(continuer, 'next')
  var onRejected = continuer.bind(continuer, 'throw')
  return onFulfilled()
}

// 利用 spawn 包裹，自動執行 generator function
// 這是一個 sequential(serial) operation
spawn(function* () {
  const a = yield fetch('a') // 等待 fetch('a')，並將結果 assign to a
  console.log(a) // a 是一個
  const b = yield fetch('b') // 等待 fetch('b')，並將結果 assign to b
  console.log(b)
})
```

這就是 async generator 的實作，很美，但過程十分嚇人。

> Note：Coroutine（協程）比較明確的定義是，指執行權從一個 coroutine 交至另外一個 coroutine，不過概念上類似，這裡借用一下，特此說明。

## Debut of Async Functions

使用上面這些燒腦的東西，雖達成任務，不過太疊床架屋，抽象概念難以消化。這時候就該主角 **Async Function** 登場！可以將 async functions 想像為 generator + promise，不過更直接的講法是：**「Async Function 是內置 `spawn` 的 generator function」**。

接下來，將前面使用 `spawn` 執行的 generator function 改寫成 async function。

```javascript
// 利用 `async` keyword 宣告 一個 async function
async function run () {
  const a = await fetch('a') // 使用 `await` 等待 fetch('a')，並將結果 assign to a
  console.log(a)
  const b = await fetch('b') // 使用 `await` 等待 fetch('b')，並將結果 assign to b
  console.log(b)
}

// 執行 async function，不需自己寫 `spawn`，如同正常的 function call。
run()
```

Async functions 使用語意清楚的 `async`／`await` 取代 `function*`／`yield`，除此之外，幾乎與 generator 版本一模一樣。其差異如下：

- 不需額外的 helper function 來執行，一般的 function call 即可。
- 回傳值為 promise。（相比於 generator 回傳 iterator，async function 復用／組合性較高）

### Usage

使用方法如下，非常簡單：

```javascript
async function myAsyncFunc () {
  let result
  try { // 慣例使用 try-catch 處理錯誤
    const a = await fetchA() // async operation
    const b = await fetchB() // async operation
    result = {a, b}
  } catch (e) {
    // 將 error 吃掉
    console.log(`Error occurred: ${e}`)
  }
  return result
}
```

### Await

`await` 是用來等待 Promise resolution 的運算子，語法與特性如下：

```javascript
[rv] = await expression
// rv -> return value of await expression
```

- 僅能用在 async function 內部。
- expression 若是 promise 以外的 value，直接返回該 value
- expression 若接 promise object，則等待該 promise resolution。
  - 若 promise fulfilled，直接返回該 value。
  - 若 promise rejected，拋出 Error 到 async function context 中（不被 promise 本身吃掉）。

這裡要注意的是，`await` 會等待 promise resolution 後才 return value，所以行為與 synchronous code 一致。

```javascript
// async arrow function
const fun = async () => {
  const a = await Promise.resolve()
  // 等待 a 處理完畢，再往下執行
  const b = await a.process()
  // 等待 b 處理完畢，再往下執行
  const c = await b.process()
  // 返回最終的結果 c
  return c
}
```

### Return Value

我們知道，Async function 的 return value 會是一個 promise，那這個 promise 什麼時候會 fulfill，什麼時候會被 reject 呢？

情況其實不複雜，整理如下：

1. `return` 語句會使 async function 直接 resolve，不再往下執行。
  - 若 `return` 一個 promise，則以該 promise 為 return value。
  - 若 `return` 一個非 promise 的 value，則以 `Promise.resolve` 包裹該 value。
2. function context 內部拋出任何 **error**，都會直接 reject，不再往下執行。

舉幾個簡單例子：

```javascript
// 直接拋出 Error
// Return 的 promise 是 rejected 狀態
async function throwDirectly () {
  throw new Error('Rejected!')
}

// 從 await 表達式中拋出錯誤
// await 會把 promise 中的 error 向外傳遞到 async function context 中
// Return 的 promise 是 rejected 狀態
async function throwFromAwait () {
  await Promise.reject(new Error('Rejected!'))
}

// 透過 try-catch 處理錯誤，錯誤不繼續傳遞
// Return 的 promise 不會被 reject
async function handleError () {
  try {
    await Promise.reject(new Error('Rejected!'))
  } catch (e) {
    // Explicitly swallow errors
    console.log(`Got error: ${e}`)
  }
}

// 利用其他流程控制語句，達到 early return 的效果
async function earlyReturn () {
  if (someRuleFulfill) {
    // 直接 return value，外部會收到 `Promise.resolve('Return Value')`
    return 'Return Value'
  }
  // 由於原本即是 return a promise，所以不需使用 `await` 等待結果
  // No need to: `return await heavyAsyncProcess()`
  return heavyAsyncProcess()
}
```

看完範例，我們可以得知 Async function 的錯誤處理模式與一般的 function 如出一轍，即「由 context 的執行情形來決定何時 return，何時該 throw Error」。

另外，Async function 的 return value 與 Error 傳到 caller context 時會以 promise 包裹。不會讓整個 call frame 掛掉，但也如同 promise 對錯誤比較 silent，所以再次提醒，慣例會在 async function 內部透過 **try-catch** 處理錯誤，不讓錯誤傳遞過遠，好比 promise 最後必會掛個 catch 處理錯誤。

### Declarations

Async function 既然是 function，想必有許多不同的宣告方式，在此將常用的方式列出來。

```javascript
// function declaration
async function asyncFunc () {}

// IIFE (Immediately Invoked Function Expression)
(async function () {/* ... */}())

// ES6 Arrow Function
const myAsync = async () => {}

// An object props
var obj = {
  async myAsync () {},
  otherProp: 1234
}

// A method of a class
class MyClass {
  async myAsync () {}
}
```

## Advanced Usage

### Sequential Operation

還記得[上一篇文章][weihanglo-promise]，我們利用 `Array#reduce` 與 `Array#forEach` 實作 serial operation 嗎？雖然 promise + functional programming 看起來很有逼格，但又多了一層抽象理解層次。藉由 async function  `await` 的特性，我們可以寫出很直觀 sequential operations，避開那些 hack。

```javascript
// 直觀的同步操作，每個 await 皆會等 promise resolution 再往下執行
const processInSequence = async (url) => {
  const resA = await getAsyncResult('a')
  const resB = await getAsyncResult('b')
  return {resA, resB}
}
```

透過 `for` loop，也可達成 sequential 的效果。

```javascript
// 利用 for loop，iterate 所有 url，逐一等待 promise resolution
const fetchInSequence = async urls => {
  const result = []
  for (let url of urls) {
    const res = await fetch(url)
    const json = await res.json()
    result.push(json)
  }
}
```

### Parallel Operation

如果 `await` 會阻塞該 context（正確說來是轉移執行權），那我如何設計 parallel operation 呢？

非常簡單，那就提前讓 promise 開始執行嘛！

```javascript
// 平行執行兩個 promise
const operationInParallel = async () => {
  // 不加 await，一次執行兩個 promise
  const pA = getAsyncResult('a')
  const pB = getAsyncResult('b')
  // 加上 await，耐心等待 promise 的結果
  const resA = await pA
  const resB = await pB
  return [resA, resB]
}
```

自幹兩個 promises 很不直觀？不然我們改用 `Promise.all`。

```javascript
// 使用 Promise.all await 多個 promises
const promiseAllInParallel = async () => {
  return await Promise.all([
    getAsyncResult('a'),
    getAsyncResult('b')
  ])
}
```

蛤！`Promise.all` 又出現了！使用 async function 不就是為了拋棄 promise 嗎？很抱歉，在有更清楚的語言特性出現前，只能選擇這種方式，畢竟 async funciton 整個 tech stack 就是建立於 promise 之上。

如果是多個 promise，也可以利用 `Array#map` 建立新的 context（function scope）來實作 parallel operation，這種方式看起來也稍微 hack，不過仍是本著 async function 的概念。

```javascript
// 利用 `Array#map` 實作 parallel operations
const fetchInParallel = async urls => {
  const jsonPromises = urls.map(async url => { // 建立新的 async function context
    const res = await fetch(rul) // await 只會在這個 context 內等待
    return res.json()
  })
  // 我們可以按順序地印出結果
  for (let jsonPromise of jsonPromises) {
    console.log(await jsonPromise) // 等待個別 promise resolution
  }
}
```

### Promise.race

想模擬 `Promise.race`，該如何實作？就直接用 `Promise.race` 吧。

```javascript
const getFirstResolutionInParallel = async urls => {
  // 利用 Promise.race 取得第一個 resolution (either reject or fulfill) 的 promise
  return Promise.race(urls.map(async url => {
    const res = await fetch(url)
    return res.json()
  }))
}
```

### First Fulfillment

在前一篇 Promise 文章中，我們 invert `onRejected` `onFulfilled` 兩個 callback，取得首個 fullfillment result。那在 async function 該如何實作呢？

當然，我們可以直接拿 Promise 做一樣的事，不過時代在走，人要進步，讓我們嘗試使用 `try-catch` 吧！

```javascript
// from Stackoverflow https://stackoverflow.com/a/39941616
const invert = p => new Promise((res, rej) => p.then(rej, res))

// 利用 try catch 實作 get first fullfillment（但仍須借助 Promise 的 API）
const firstFulfillmentInParallel = async urls => {
  try {
    await Promise.all(
      urls.map(async url => {
        const res = await fetch(url)
        return res.json()
      }).map(invert)
    )
  } catch (e) {
    return e // 直接返回 inversion 的 fulfillment
  }
}
```

雖然有達到目的，但 fulfillment 卻是從 `catch` block 返回，實作漸漸不直觀了。

## Async Interation

我們知道，async function 原理上是 generator 的 syntax sugar，利用 iterator 與 `yield` 轉換控制權，達成 asynchronous operation 效果，但是 `iterator.next` 這個 method 卻只有 synchronous 版本，有些場景（例如 streaming）需要非同步的 iterator 來取得 streaming data，這時候就該 **async interator** 出場了。

[這個提議][proposal-async-iteration]目前已在 Stage 3 了，即將納入標準，可以開始瞭解它了。

話不多說，附上提議的範例程式碼，感受一下吧！

```javascript
// for-await-of loop
for await (const line of readLines(filePath)) {
  console.log(line);
}

// Async generator functions
async function* readLines(path) {
  let file = await fileOpen(path);

  try {
    while (!file.EOF) {
      yield await file.readLine();
    }
  } finally {
    await file.close();
  }
}
```

## Further Reading

比起 promises，async functions 相對沒這麼多文獻供參考，想要入門，依然推薦阮大大的 [ECMAScript 6 入门：async 函数][ruanyifeng-es6-async]，真的是非常豐富的 ES6 大全。當然，[Google Web Fundamentals][google-async-functions] 也值得一看，但沒有 Promise 篇含金量這麼高就是了。

Medium 上也有許多作者在評論 async functions，[Hacker Noon 這篇推坑文][hakernoon-6-reasons-async]比較了 promise 與 async function 的優劣，算是蠻清楚的入門文，看看 async function 是否符合妳的期待。另外，也有人寫了不少篇~~批判~~反思 async function 的文章，[這篇告訴你還是需要理解 promise][danielbrain-understand-promises] 才能以正確的姿勢使用 async／await，另一篇則告訴你，[promise 還是比較厲害][danielbrain-promises-are-keys]的啦。

當然，沒有任何 unit tests，就算程式碼可讀性再高，仍然非常脆弱，所以，別花太多時間看這些新技術，乖乖地補上缺漏的 tests 比較實在 XD。

## Reference

- [Mozilla Developer Network](https://developer.mozilla.org/)
- [Google Web Fundamentals: Async functions - making promises friendly][google-async-functions]
- [ECMAScript 6 入门：Generator 函数的异步应用][ruanyifeng-es6-generator]
- [ECMAScript 6 入门：async 函数][ruanyifeng-es6-async]
- [Daniel Brain: Understand promises before you start using async/await][danielbrain-understand-promises]
- [Haker Noon: 6 Reasons Why JavaScript’s Async/Await Blows Promises Away][hakernoon-6-reasons-async]

[async-functions]: https://tc39.github.io/ecmascript-asyncawait/
[ruanyifeng-es6-generator]: http://es6.ruanyifeng.com/#docs/generator-async
[ruanyifeng-es6-async]: http://es6.ruanyifeng.com/#docs/async
[caniuse-async-functions]: https://caniuse.com/#search=async%20functions
[hakernoon-6-reasons-async]: https://hackernoon.com/6-reasons-why-javascripts-async-await-blows-promises-away-tutorial-c7ec10518dd9
[google-async-functions]: https://developers.google.com/web/fundamentals/getting-started/primers/async-functions
[danielbrain-understand-promises]: https://medium.com/@bluepnume/learn-about-promises-before-you-start-using-async-await-eb148164a9c8
[danielbrain-promises-are-keys]: https://medium.com/@bluepnume/even-with-async-await-you-probably-still-need-promises-9b259854c161

[weihanglo-promise]: https://weihanglo.github.io/posts/2017/javascript-concurrency-promise/

[mdn-async-funciton]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function

[tj-co]: https://github.com/tj/co
[facebook-regenerator]: https://github.com/facebook/regenerator
[wiki-coroutine]: https://en.wikipedia.org/wiki/Coroutine

[mdn-generator]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Generator
[wiki-sequence]: https://en.wikipedia.org/wiki/Sequence
[wiki-container]: https://en.wikipedia.org/wiki/Container_(abstract_data_type)

[mdn-iteration-protocols]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Generator
[python-iterator]: https://stackoverflow.com/a/7542261

[proposal-async-iteration]: https://github.com/tc39/proposal-async-iteration
