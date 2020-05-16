---
title: "WWW 0x0F: 工程師唯一需要知道的數字是伴侶生日"
date: 2020-05-02T00:00:00+08:00
tags:
  - DevOps
  - Asynchronous
  - Monitoring
  - Databases
---

這裡是 WWW 第拾伍期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Latency Numbers Every Programmer Should Know](https://gist.github.com/jboner/2841832)

最近替公司服務做 autoscaling，需要各種伺服器數據，好來順便做 cache 和最佳化 API，剛好讀到這篇「程式設計師都應知道的延遲數字」，心裡有個概念，大概就可以抓到服務什麼地方可能需要加強了。

![Visual representation of latencies](http://i.imgur.com/k0t1e.png)

Visual chart provided by [ayshen](https://gist.github.com/ayshen)

## [Shopee 的分布式数据库实践之路](https://zhuanlan.zhihu.com/p/101609527)

![](https://raw.githubusercontent.com/pingcap/tidb/master/docs/logo_with_text.png)

內容比較分散的「漫談」，主要闡述蝦皮使用知名分散式資料庫 [TiDB](https://github.com/pingcap/tidb) 的各種姿勢和場景。幾個有趣的點：

**觀察：** 原本 1000 sharding 的把表分片，改成 TiDB 同一張表，結果某個佔 90% read op 的 latency 大到會把 TiDB cluster 卡死，最後把這個效能吃緊的 read cache 在 Redis 上才解決。

**感想：** 省了 sharding 的管理規劃成本，多了 Redis cache 的成本，不過這層 cache 個人覺得遲早的事。

**觀察：** 蝦皮寫了自己的 Binlog middleware 來解析 binlog，在儲存到 Kafka 或 Redis。

**感想：** 感覺這種 operation log 當作事件處理的流程漸漸成為標準配備，像 MongoDB 直接提供 [Change Streams](https://docs.mongodb.com/manual/changeStreams/) 統一介面很方便，能夠以更接近資料的面向訂閱資料流當然更好。

**觀察：** 預設還是使用 MySQL，但積極嘗試 TiDB，並通過 Redis 弭平鴻溝。

**感想：** 這表示 1）TiDB 和 MySQL 底層實作差很多，內文也提到不太可能 1:1 遷移，還有 2）DBA 和 RD 設計管理 sharding 的成本太大，大過學習 TiDB 加上維護 Redis，尤其是 logging 這種大量產生的資料的場景。

## [Backpressuring in Streams](https://nodejs.org/en/docs/guides/backpressuring-in-streams/)

無意間看到這個 Stream Guide，才發現 Node.js 原生就有處理 backpressure，在 Readable/Writable stream 裡面個放一個 [internal buffer](https://nodejs.org/api/stream.html#stream_buffering) 和 `highWaterMark`（threshold），只要高過這個 threshold 就會停止讀寫或通知 source 停止傳送資料。

文中最有趣的一段是講[萬一缺乏 backpressure 處理，恐導致記憶體用量驚人](https://nodejs.org/en/docs/guides/backpressuring-in-streams/#excess-drag-on-garbage-collection)， GC 開銷要顧及這些 buffer 也逐漸緩慢，範例程式碼最後 RSS（resident set size，可看作實際物理記憶體用量）兩者分別為 87.81 MiB 和 1.52 GiB，已經達到不可忽視的地步。

讓我想起 Flask/Redis-rs 的作者呼籲所有 async library 作者一起來解決 backpressure 的文章，[附上連結供看倌享用](https://weihanglo.tw/posts/2020/www-0x04/#im-not-feeling-the-async-pressurehttpslucumrpocooorg202011async-pressure)。

> 寫 Node.js 這麼久，今天才知道這件事，覺得慚愧。
