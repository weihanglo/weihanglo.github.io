---
title: "WWW 0x03: What Color is Your Function?"
date: 2020-02-08T00:00:00+08:00
tags:
  - Weekly
  - Asynchronous
  - System Programming
---

> 你的 function 是什麼顏色？

這裡是 WWW 第參期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Using Rust in Windows](https://msrc-blog.microsoft.com/2019/11/07/using-rust-in-windows/)

相較於 Microsoft 近期在 Rust 社群動作不斷，這篇文章相對平實，不過也藏了許多有趣事實。

1. Microsoft 覺得 Cargo 不能容易配合既有的 build system，這個其實和 Google 使用 Bazel 和 Facebook 自己搞 tool 一樣，超巨頭的工作環境太特殊了。不過也提及正在與社群接觸，微軟真的開始關注 Rust 了。
2. 提到了 Rust 很適合做 C 的 safe wrapper，其實這個也是官方[死靈書提及的作法](https://doc.rust-lang.org/nomicon/ffi.html)，`bindgen` 真心方便。
3. 對熟悉 C++ 的開發者而言，Rust 學習成本比想像中低了很多，一兩天配合 Rust 好用的周邊工具就可以寫出 idiomatic Rust，這和 RustConf 2019 上 Facebook 僱員的說法一致。
3. 看到最後才發現作者是 Hyper-V team 成員，再聯想到 AWS 用 Rust 寫的 [Firecracker](https://firecracker-microvm.github.io) 作為 Fargate 和 Lambda 底層的 micro vm，不難想像這些大公司~~用 C++寫底層的底層員工生活多苦~~ 。

## [What Color is Your Function?](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/)

看起來滿篇幹話，但其實在講一個非常有趣的概念：這個世界被分為兩種 function， synchronous 和 asynchronous。async function 具有感染力，不能在 sync function 內部呼叫，因此，寫程式就要一直把「這個是 sync 那個是 async」的思維放在腦中，不累嗎？

作者提到了三種語言沒有這個問題：Go、Lua、Ruby。這三種都做了類似 green thread 的實作，所以例如操作 IO 就會 suspend 當前執行環境到 callstack，並 resume 其他 function 和 stack，撰寫程式不再需要刻意分辨 sync/async，寫起來都一樣。

雖然本文並非 Go 推坑文，但作者和我的想法的十分接近：Go 語言真的很簡單，連非同步都可以當作不知道，反正語言底層幫你解決了。

## [200 行以內實作 Green Thread](https://cfsamson.gitbook.io/green-threads-explained-in-200-lines-of-rust/)

Go 的 Goroutine 和 Python 的 Greenlet 滿火熱的，最近來研究一下的實作 Green Thread，剛好看到 C 和 Rust 兩個實作版本，順便紀錄閱讀心得。

- [Rust 線上示範](https://bit.ly/33ZdeCE)
- [Rust 180 行版本（推薦）](https://cfsamson.gitbook.io/green-threads-explained-in-200-lines-of-rust/)
- [C 150 行版本（一樣很棒）](https://c9x.me/articles/gthreads/mach.html)

### Green Thread 不負責任定義

提供在 userspace 的 non-preemptive multitasking，一個可以 yield 將 CPU 控制權讓出，並儲存當前的 context，在未來可以 resume 繼續執行。這種作法常見於 blocking-IO 的場景。

> 正名一下，Green thread 稍微正式的名字是 coroutine。

### 要懂 Green Thread 的先備知識

- ABI 的概念（CPU calling convention）
- CPU 如何管理 call stack
- 一些 Assembly（會需要用 asm 於 register 溝通）

### Thread 實作重點整理（直接看文章比較快）

- x86 會把 function pointer、return address 記錄在 register
- 把 function pointer 放到 stack pointer 上 就會執行函式
- 有個 `Runtime` 負責管理每一個 userspace `Thread`
- `Thread` 有個 context，記錄當前 register 的狀態
- `Runtime` 有兩個最重要的 method：`yield`、`spawn`
- `Runtime.yield` 轉讓 CPU 使用權： 找尋 yielding `Thread`，記錄當前的 register 狀態到它自己的 context 以便未來 resume，然後將準備執行的 `Thread` 的 context 寫入 register
- `Runtime.spawn` 啟動一個 thread 執行任務： 傳入任意的函式，將函式指標寫入 context 的特定 offset，這個 offset 對應 x86 ABI 的 stack pointer
