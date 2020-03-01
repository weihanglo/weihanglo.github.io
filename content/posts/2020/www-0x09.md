---
title: "WWW 0x09: 到底要不要擔心 blocking"
date: 2020-03-21T00:00:00+08:00
tags:
  - Weekly
  - Asynchronous
  - System Programming
---

> A programmer had a problem. He thought to himself, "I know, I'll solve it with threads!". has Now problems. two he
>
> — Davidlohr Bueso

這裡是 WWW 第玖期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Stop worrying about blocking: the new async-std runtime, inspired by Go](https://async.rs/blog/stop-worrying-about-blocking-the-new-async-std-runtime/)

[async-std](async.rs) 是 Rust 非同步生態中兩雄之一，欲與 [tokio](tokio.rs) 爭天下。這次的實驗性更新受到 Go 語言啟發，實作了新的 scheduler，主要特點有：

- 更快更好更自適應
- 自動偵測 blocking task 並將其卸載到其他執行緒，避免阻塞
- 使用者可在 `async` context 內呼叫 blocking task 而不阻塞

要點重申：你不需函式是 blocking 還是 non-blockging，全丟到 async 裡面呼叫吧！async-std 的 runtime 會偵測，然後幫你解決一切。

但事情往往沒這麼單純 😈

## [Do NOT stop worrying about blocking in async functions!](https://www.reddit.com/r/rust/comments/ebpzqx)

async-std 新的 scheduler 在處理 nested `Future` 或是使用其他非 async-std 的 `select!` 等 macro 時，blocking call 仍然會 block。這個 Reddit 討論串認為 async-std 不應該讓大家對 blocking function 降低警覺，否則一個 async library 就沒辦法替換其他沒有提供「自動偵測 blocking」的 runtime，會造成社群更加分裂。

其中也提到了 [withoutboats 在 Interal forum 提及的 `#[might_block]` attribute](https://internals.rust-lang.org/t/warning-when-calling-a-blocking-function-in-an-async-context/11440)，這是一個非常有趣的標記，類似 `#[must_use]` 告知 compiler 這個 function 會 block。不過另一方面，也[有人提出 blocking/non-blocking 其實並非一邊一國](https://www.reddit.com/r/rust/comments/ebpzqx/do_not_stop_worrying_about_blocking_in_async/fb6ux8b)：取得 array slice 中的元素是 non-blocking，但如果 array 實際上是 mmap 映射出來的檔案，取得元素就會有 page fault 然後就真的需要「讀檔」。

也[有人在 PR 提問](https://github.com/async-rs/async-std/pull/631#issuecomment-566313245)，如果 async-std 新的 scheduler 賣點是可在 async block 使用 blocking function，是否產生一堆執行緒，造成 C10k 問題？async-std 團隊正式回應是，其實[只會產生一個執行緒，和 10000 個 socket](https://github.com/async-rs/async-std/pull/631#issuecomment-566657299)，當然，整個討論串仍持續進行，非常值得一讀。

> 有人提到 C10k 其實應該用 semaphore 解決，這的確是比較正確直觀的作法，畢竟，你知道[你的函式是什麼顏色嗎](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/)？

## [如果这篇文章说不清epoll的本质，那就过来掐死我吧！](https://zhuanlan.zhihu.com/p/63179839)

這是在知乎專欄上的三篇文章，從硬體，歷史沿革，到實際程式碼來說明 [`epoll(7)`][] 到底為什麼如此高效。

如果你之前就理解 `epoll`，看看是否可以回答下列問題，若覺得不是很透澈，再讀一遍吧！

- 知道 Unix/Linux 上的 file descriptor 是什麼
- 知道 `epoll` 透過 CPU 中斷來接收網卡數據的流程
- 知道 kernel 和 socket 如何處理 buffer 來喚醒 process
- 知道 [`select(2)`][] 的實作原理
- 知道 `select` 什麼情境可能會比 `epoll` 更有效率

[`epoll(7)`]: http://man7.org/linux/man-pages/man7/epoll.7.html
[`select(2)`]: http://man7.org/linux/man-pages/man2/select.2.html

![](https://pic4.zhimg.com/80/v2-696b131cae434f2a0b5ab4d6353864af_hd.jpg)
