---
title: "WWW 0x10: 重構不是病，寫起來要人命"
date: 2020-05-09T00:00:00+08:00
tags:
  - Rust
  - DevOps
  - Databases
---

這裡是 WWW 第十六期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Graceful shutdown in Kubernetes is not always trivial](https://medium.com/flant-com/kubernetes-graceful-shutdown-nginx-php-fpm-d5ab266963c2)

對不起，分享一篇 medium 付費牆的文章。重點節錄：

- 讓你的 app delay 一些時間再停止接收 connection
- 如果你沒辦法控制 app（code 不是你寫的），可加 `preStop` hook 來控制
- 如果加了沒用，請去看該 app 如何處理各種 Signal
- 請測試，請分析，不要盲目寫完就當作自己做好 graceful shutdown

## [三篇文章了解 TiDB 技术内幕 - 说计算](https://pingcap.com/blog-cn/tidb-internal-2/)

由於開源資料庫系統 [TiDB](https://pingcap.com) 為中國人研發，中文撰寫的文件非常多，這篇主要介紹 SQL 的 relation model 如何映射到 Key-Value model，處理 index 和 unique index 也不相同。很有趣，值得一讀（TiDB/TiKV 的 source code 也是 😂）。

## [Rewriting the heart of our sync engine](https://dropbox.tech/infrastructure/rewriting-the-heart-of-our-sync-engine)

![](https://dropbox.tech/cms/content/dam/dropbox/tech-blog/en-us/2020/03/01.png)

Dropbox 重寫整個電腦版的同步引擎 **Nucleus**，花了四年時間，節錄些（其實不是節錄）有趣發現：

### 🤯 同步檔案有下列幾個困難點

- 分散式系統：client 常常 offline、或是在不同的裝置同步，扎扎實實就是個分散式系統
- 耐用性：不同作業系統有不同的實作，有些時候甚至要 reverse-engineering，不過這通常會影響到很小部分人
- 測試檔案同步：各種連線狀況、本地讀取、寫檔到硬碟、不同的 snapshot、上傳、chunk transfer
- 同步行為：不同 client 任意移動資料夾，造成資料夾間 circular cycle

### ✏️ 為什麼要重寫

雖然原始的同步服務很成功，團隊也不斷重構最佳化，但程式碼並不健康，最大幾個問題是：

- **Consistency：** data model 沒有考慮共享性，consistency guarantees 不強
- **Testability：** 系統可測試性不夠強，反而依靠 slow rollout 然後開始 debugging
- **Concurrency：** 最後當然是 concurrent 問題，不好測，不好重現，只好用粗粒度的鎖，犧牲一些效能

### 📝 系統重寫核對清單

整篇文章~~只有~~這部分最有趣，因為 Dropbox 團隊知道[重寫其實容易是不明智的決策](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/)，但團隊還是很清楚列出決定重寫的關鍵（說不定是事後諸葛）。

1. 是否窮盡所有漸進改善方案
    1. 有試過重構現有模組嗎
    2. 有針對熱點分析改善嗎
    3. 可階段性發佈漸進改善的成果嗎
2. 是否有足夠能力重寫專案
    1. 對現有專案完全瞭解到考古程度嗎
    2. 有足夠的工程資源嗎
    3. 可接受新功能開發步調趨緩嗎
3. 是否知道專案的未來方向
    1. 重寫真的會改善嗎
    2. 新系統有制定各種原則嗎

我懶得詳述 Dropbox 對這些問題的答案，但它們其實透過 [MyPy](http://mypy-lang.org/)（印象中 MyPy 就是 Dropbox 發揚光大）還有各種 profiling 工具不斷重構，但仍然決定重寫。其中完全跳脫我的思維的是最後一點，重寫新系統其實就是「 **重新塑造工程文化** 」的好時機（也是大搞辦公室政治的好時機 😈），善用這個機會，團隊肯定煥然一新。

> Starting from scratch is a great opportunity to reset technical culture for a team.

### 📦 所以 Dropbox 到底做了什麼

寫了這麼多，應該已經猜到 Dropbox 做了什麼，對，就是用 **Rust** 重寫他們整個 Desktop client sync engine。Rust 對 Dropbox 來說是個「force multiplier」，使用 Rust 是最好的技術決策之一，除了效能，type system 和 AOT compiling checking 才是讓團隊笑到最後的關鍵因素。

廣告快打完了，還是提一下新的 sync engine **Nucleus** 到底葫蘆裡賣什麼課程：

- **Threading model 簡化：** 幾乎所有 code 都在 single thread（a.k.a「The Control Thread」）用了 Rust 非同步的 de facto [futures.rs](https://github.com/rust-lang/futures-rs)，剩下 network IO 放到 event loop（未看先猜是 [tokio](https://tokio.rs)），CPU-heavy task 有 thread pool，檔案系統 IO 也有個 dedicated thread。乾乾淨淨，清潔溜溜。
- **Deterministic 增加 testability：** The Control Thread 在輸入值和排程法確定的條件下，行為是 deterministic，解決了舊系統不容易寫測試的問題，也能簡單重現錯誤，甚至可以用個做 pseudorandom 的 input、檔案、系統狀態和錯誤。
- **重新設計具有 strong consistency 的 client-server protocol：** 共享的檔案和目錄終於有全域 ID，檔案和目錄的移動是 O(1)，和他們 subtree 的大小無關（不知道底層怎麼做到）。

然後 Dropbox 正在找會寫 Rust 的 infra team member，帥。

> 沒錯，Rust 早就滲透你我的生活，人遲早會鏽蝕
