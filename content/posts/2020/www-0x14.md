---
title: "WWW 0x14: Structured concurrency is promising"
date: 2020-06-06T00:00:00+08:00
tags:
  - Interview
  - Rust
  - Concurrency
---

這裡是 WWW 第貳拾期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Oxidizing the technical interview](https://blog.mgattozzi.dev/oxidizing-the-technical-interview/)

非常瞎搞的一篇 Rust 面試文，面試者要求解演算法題，被面試者開始手寫 `libcore` 的 trait 再用 compile time `const fn` 做到 `O(1)` runtime。內文更提及 `no_core` 也就是不導入 `libcore`，本來以為是開玩笑，，沒想到還真有 [`no_core`](https://github.com/rust-lang/rust/issues/29639) 的 feature，太可怕了。

## MongoDB Retryable Reads and Writes

最近在做 MongoDB zero downtime 遷移與升級，本來以為已經萬無一失，卻還是在 reconfig 切換 primary 時遇到`not master and slaveOk=false` 這種錯誤，導致部分使用者 HTTP request status 500，推斷發生原因如下：

1. A server 為 primary
2. client 與 A server 建立 TCP 連線
3. 其他 server 選為 primary，A server 切換為 secondary，
4. client 沿用舊連線連到 A server，發生 `not master and slaveOk=false` 錯誤

根據 [client spec](https://github.com/mongodb/specifications/blob/master/source/retryable-reads/retryable-reads.rst)，這種錯誤會透過 `retryReads` 和 `retryWrites` 重試，而且這些功能[在 MongoDB 4.2](https://docs.mongodb.com/manual/core/retryable-writes/index.html#enabling-retryable-writes) 早已[預設開啟](https://github.com/mongodb/specifications/blob/master/source/retryable-reads/retryable-reads.rst#retryreads)，但還是很神奇地失敗了。

我們來整理幾個規範中提到，可能拋出 `not master and slaveOk=false` 的點：

- 使用了 transaction
- 使用了 `Cursor.getMore()`
- retryable read/write 只會 retry 一次，但遇到多次 retryable error 無法成功
- 若 retry 失敗但錯誤無法讓 caller 知道有 retry 過，會拋出原始的 retryable error

看來真的要支援 zero downtime 的升級，還是得客製化 multiple retry 的 client，或是多架一層 proxy 了。

## [Tokio: Structured Concurrency Support](https://github.com/tokio-rs/tokio/issues/1879)

![](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/nursery-3-pathified.svg)

> Trio 透過 `async with` 實作一個 structured concurrency context

Structured concurrency 簡單來說就是「讓 concurrent task 之間有階層概念」，上層任務知道有哪些子任務，而且子任務的生命週期包含在上層任務中 內，因此可以輕易做到上層任務來取消子任務，防止資源洩漏，堪稱 concurrency 界的 RAII。換句話說，類似從前 goto 到 control flow 的 structured programming 典範轉移，concurrent task 都會有明確的進入與離開點。

幾個作者認為 structured concurrency 要做到的功能：

- 上層任務只會在所有子任務結束時結束
- 任務只能在上層任務的 context 內產生，且上層任務需記憶其子任務
- 上層任務需有對子任務的取消機制
- 錯誤應該向上層傳播，且所有同階層的子任務都該取消

除了主要 Issue 內容，其他留言討論和各種文章連結都非常有意思，值得一讀。

![](http://libdill.org/index3.jpeg)

![](http://libdill.org/index2.jpeg)

> libdill 的 structured concurrency 示意圖
