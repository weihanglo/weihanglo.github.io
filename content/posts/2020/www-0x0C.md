---
title: "WWW 0x0C: 未具名"
date: 2020-04-11T00:00:00+08:00
tags:
  - Weekly
  - Rust
  - Kubernetes
  - Privacy
---

> 既然疫情嚴重，連假就在家加班吧！
>
> — Weihang Lo 2020.4

這裡是 WWW 第拾貳期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Words Are Hard - An Essay on Communicating With Non-Programmers](http://adventures.michaelfbryan.com/posts/words-are-hard/)

以直白的口吻，分享和不同背景的人講解技術的法則。節錄重點如下：

- 避免用過多行話
- 放尊重點，不要擺出紆尊降貴的姿態
- 給技術解釋加些人性生動的類比
- 視覺化圖表比口語更易理解
- 承認自己不熟，但可花時間研究

願我們一起打破工程師古怪又難溝通的刻板印象。

## [The Raft Consensus Algorithm](https://raft.github.io/)

![](https://raft.github.io/logo/annie-solo.png)

最近嘗試貢獻 [TiKV](https://tikv.org)，順便複習一下 Raft 共識演算法
Raft 主要訴求是 Understandability，因為 Paxos 太複雜（無誤），Raft 的 server 分為三個 state：

- `follower`：所有非 leader 的 server 都是 follower
- `leader`：所有 client request 都會送到 leader，一個 Raft group 理論上只有一個 leader
- `candidate`：達到 election timeout 的 follower 會把自己提升為 candidate，並向其他 server 發出訊息：「請 promote 我當 leader」

而 Raft 主要有兩個的步驟：

- **Leader Election**：從 follower 中投票選出 leader，可以處理 split vote
- **Log Replication**：將 state machine 以 log 形式複製到每個 server，大多數的 server 回覆後才會 commit change

不贅述了，[這個簡單的動畫教學](http://thesecretlivesofdata.com/raft/)很清楚點出 Raft 最重要的核心元件，當然自己看[論文](https://raft.github.io/raft.pdf) 😈。

## [We need tool support for keyset pagination](https://use-the-index-luke.com/no-offset)

[![](https://use-the-index-luke.com/static/no-offset-banner-300x250.white.zOfUqF4s.png)](https://use-the-index-luke.com/no-offset)

這篇文章的重點只有一個：不要使用 offset 來做分頁。原因如下：

- offset 的 SQL 標準定義是先 fetch 所有 row，再丟棄被 offset 掉的 row
- 承上，小 offset 效能影響不大，高 offset 就很慘
- 若在計算 offset 時，同時 insert 新 row，就可能拿到重複的 row
- 不論 SQL 還是 NoSQL database 都可能受影響

哪些 SQL 可能會有這樣問題:

- `OFFSET` keyword
- 雙參數的 `LIMIT [offset, ] limit`
- 一些用 row-numbering 來篩選 lower-bound，如 `ROW_NUMBER()`、`ROWNUM`

作者想表達的是，這並非 Database 的鍋，而是 framework 應使用其他 pagination 方法，例如 keyset pagination，也就是傳入上一分頁最後一組 key，來找下一分頁。當然，並非所有情境都適合這種分頁模式，且要改善程式分頁效能之前，請先做 benchmark，阿彌陀佛。
