---
title: WWW 0x04
date: 2020-02-15T00:00:00+08:00
tags:
  - Weekly
---

這裡是 WWW 第肆期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## ["Performance Matters" by Emery Berger](https://youtu.be/r-TLSBdHe1A)

最近滿紅的一個關於 performance measurement 的 影片，講者演講功力深厚，把嚴肅 performance  analysis/profiling 議題以輕鬆的口吻娓娓道出，非常推薦。

節錄一些我覺得有趣的點：

1. 以 CPU 和 transistor 的發展闡述為什麼現代程式越來越注重效能
2. 解釋 Performance Analysis 和 Performance Profiling 有什麼差別
3. Performance Analysis 是需要統計而且不是 eyeball statistics，然後要排除環境變因
4. 想做 Performance Profiling 可以從另一個角度開始：讓其他不想測試的部分「變慢」

## [Why Discord is switching from Go to Rust](https://blog.discordapp.com/why-discord-is-switching-from-go-to-rust-a190bbca2b1f) 

> [簡體中文譯文](https://mp.weixin.qq.com/s/KlDZx5s6fhn37BZMQAUm1g)

標題乍看下有點聳動，其實內容很平實，完整交代來龍去脈：

- 背景：Discord ReadState 服務架構和資料結構
- 問題：高度手動最佳化的 Go 實作仍有兩分鐘一次的 GC spike，測試好幾個 Go 版本都沒解決
- 行動：用沒有 GC 的 Rust 重寫，公司內其他團隊也有[成功案例](https://blog.discordapp.com/using-rust-to-scale-elixir-for-11-million-concurrent-users-c6f19fc029d3)
- 成果：各項指標皆勝原本 Go 實作，但有強調不要腦衝什麼都 [RiiR](http://adventures.michaelfbryan.com/posts/how-to-riir/)


> 紫色是 Go，藍色是還沒升級 Tokio 0.2 的 Rust

![](https://miro.medium.com/max/2570/1*-q1B4t622mnxoV8kvT9RwA.png)

## [I'm not feeling the async pressure](https://lucumr.pocoo.org/2020/1/1/async-pressure/)

這篇文章是由 Python 知名框架 Flask 的作者所撰，內容點出當今 async 熱潮，從 c#、JavaScript、Python 到 Rust，沒有一個語言不想要 async，高層次抽象的背後，卻容易忽略 back pressure 帶來的問題。

### 何謂 back pressure

Back pressure 在「[Backpressure explained — the resisted flow of data through software](https://medium.com/@jayphelps/backpressure-explained-the-flow-of-data-through-software-2350b3e77ce7)」一文中給了不錯的定義，若流體中的 back pressure 定義如下：

> Resistance or force opposing the desired flow of **fluid through pipes**.

那麼在軟體工程中就是以下的定義；

> Resistance or force opposing the desired flow of **data through software**.

作者用了一個貼切的例子：浴缸排水不及，反而水漲了起來，我自己覺得馬桶堵塞更貼切啦！簡單來說，sender 傳送速率大於 receiver，就會使得 back pressure 變成問題。

### 管理 back pressure 的方法

要管理 back pressure 的方式有兩種：

- dropping：丟棄來不及處理的訊息 -> 會掉資料
- buffering：貯存來不及處理的訊息 -> unbounded buffer 可能會漫出來 out-of-memory

可惜現今大部分語言的 async 都沒特別處理，例如 Python 的 asyncio，如果在 async function 中用了 blocking API，就會需要處理 back pressure，而 asyncio 選擇使用 buffering 的方式來解決，如果都沒有 receiver 讀取，buffer 就會一直長大。
 
另外一種管理 back pressure 的方式就是告知 sender 請求其不要再送資料了，例如使用 Semaphore 並告知 sender 當前排隊人數，讓其自行決定是否不繼續等待，server 直接回傳給 client 503 也不失為一個選擇。

不過這些都是基於 request-response 模型的 back pressure 管理，如果是 streaming 或是像 HTTP/2 這種複雜的多工，sender 同時又是 receiver 的模型，async/await 就非常不適用（注：感覺部分的應用應該可以透過 async-iterator 解決）。

### Async Is The New Footguns

作者覺得 async 是 footgun 是因為：

- 雖降低大型軟體工程，但其實也把處理 distributed system 的問題丟給了開發者（注：應是指 non-blocking async app 比起 blocking multi-threaded app 來得更隱晦，更難撰寫正確，例如在 async function 用到 blocking 整個 async runtime 就 block 住，所以才有 [async runtime 要自動偵測 blocking](https://async.rs/blog/stop-worrying-about-blocking-the-new-async-std-runtime/)）
- 改成 async function 會帶來許多 API breakage，這其實對 API user 來說很可怕，整個 call stack 可能都要變成 async 的
- flow control 從來都不是容易的事，許多非 async/await 的 library 在這層面也有諸多錯誤，Go、aiohttp、hyper-h2 都有 issue 從 2014 年開到現在還沒解決

最後，作者期望任何 async library 作者，都能在新年新願望加個「給 flow control 和 back pressure 在 API 和文件中一個重要地位」。
