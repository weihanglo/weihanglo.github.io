---
title: "WWW 0x00: Rust 有個靜態 GC"
date: 2020-01-18T00:00:00+08:00
tags:
  - Weekly
---

> 如果員工年齡用 5 bits 存，那 J 同事的確最年輕，在 overflow 之後。
> 
> 傑森 - 2020

這裡是 WWW 第零期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Rust has a static garbage collector](https://words.steveklabnik.com/borrow-checking-escape-analysis-and-the-generational-hypothesis)

雖然這篇作者是 Rust 核心成員，文章鋪陳也是為了褒 Rust，但內文講到 static typed 與 dynamic typed lang 的權衡比較，還有各種 GC 和記憶體管理的精實介紹，覺得蠻值得一讀，第一次聽到 escape analysis 也是驚呼了一下，不就是 GC 版 RAII 嗎！

## [Starship](https://starship.rs/)

小又快的 shell prompt

- config 超簡單
- 支援顯示 Node.js/Ruby/Python/Rust/Go/AWS/K8s/... 非常多環境
- 支援 Git rebase/merge stage 還有 status/branch
- 還有自帶很醜的顏色

如果覺得 oh-my-zsh 太肥的同學可以來試試看，個人用了半年沒出什麼問題。

![](https://raw.githubusercontent.com/starship/starship/master/media/demo.gif)

## [A simple C thread pool implementation](https://github.com/mbrossard/threadpool)

看到一個很簡單的 300 行 threadpool in C 實作，想分享一下：

- 只有一個 thread queue 和一個 task queue
- 利用 mutex 限制一次只能一個 thread 取 task 來執行
- 沒有 task 時就[用 condition variable ](https://github.com/mbrossard/threadpool/blob/169d20f326772492a836c0d2acd6d1de985f002d/src/threadpool.c#L275-L279)來 block thread 等待新增 task
- 最重要的 [loop 在這裡](https://github.com/mbrossard/threadpool/blob/169d20f326772492a836c0d2acd6d1de985f002d/src/threadpool.c#L266)
- [threadpool_task_t 這個 Task](https://github.com/mbrossard/threadpool/blob/169d20f326772492a836c0d2acd6d1de985f002d/src/threadpool.c#L45-L56) 儲存了 function 和它的 args： 

不過這並非 lock-free 的實作，Mutex 鎖仍然有不少效能改善空間，等我看懂 lock-free threadpool 再來分享。

## [The Case for Writing Network Drivers in High-Level Programming Languages](https://www.net.in.tum.de/fileadmin/bibtex/publications/papers/the-case-for-writing-network-drivers-in-high-level-languages.pdf)

慕尼黑工大寫了一系列論文，用各種語言實作 Network driver，實作細節包含 DMA 到封包傳遞，Rust 的效能接近 C 在意料之中，比較令我驚訝的是 C# 效能好得誇張。

[GitHub 專案請點此](https://github.com/ixy-languages/ixy-languages)。

![](https://raw.githubusercontent.com/ixy-languages/ixy-languages/master/img/batches-3.3.png)
