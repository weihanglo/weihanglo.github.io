---
title: "WWW 0x15: 你懂資料庫嗎"
date: 2020-06-13T00:00:00+08:00
tags:
  - Databases
---

這裡是 WWW 第貳拾壹期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [The Best Medium-Hard Data Analyst SQL Interview Questions](https://quip.com/2gwZArKuWk7W)

作者總結自己的面試和工作經驗，整理出 Data Analyst 和 Data Scientist 的 SQL 面試題，著重在 self-join 和 window function 的相關練習。雖然 SQL 能力不是應徵資料分析職位的關鍵因子，我覺得反而是資訊工作者不可或缺的基本能力，從行銷、產品經理到工程師都應該要會 SQL DQL（Data Query Language），才能從報表、產品或系統看出洞見 。

## [Anxiety in product development](https://andreschweighofer.com/agile/anxiety-in-product-development/)

本文透過幾個行為觀察，分析是否掉入 anxiety driven development 的無限迴圈，這裡來個~~超譯~~摘要：

- **害怕輸輸去：** 怕失去市佔、怕失去顧客、跟著競爭對手的 feature 跑，導致產品開發看似 agile 其實更不穩定，總是晚一個世代，將創新扼殺在時間漩渦。
- **一心只想贏：** Unique Selling Proposition（UCP）可以理解為產品在市場上的生態區位，可以說是「獨特賣點」，利用 UCP 是好事，但以價格創造的 UCP 最羸弱，最沒使用者忠誠，最容易被其他人宰割。
- **並非發光的都是金子：** 著急業務落後者容易短視近利，這種短期勝利可能只是短暫消除焦慮感，卻讓整個團隊陷入愁雲慘霧，回饋感漸低，特別是在專案尾聲想偷渡 feature 而不是留 buffer。
- **掌舵：** 主要是說退一步並勾勒出真實的展望，並以此影響策略，（對不起這已超出我能理解的範圍，請自行看原文）
- **不可能的承諾：** 焦慮讓你想要找回掌控權？你會開始將流程官僚化，寫下每個 ticket 細節與需求，這反而嚴重打擊各位的動機。
- **脫離官僚：** 信任帶來新幸福，信任你的市場研究和策略，信任你的團隊的專業和洞見，讓他們自行成為一個有機體。

## [Things I Wished More Developers Knew About Databases](https://medium.com/@rakyll/things-i-wished-more-developers-knew-about-databases-2d0178464f78)

世界上大多數的開發者都碰過資料庫，但其實對資料庫一知半解，常常各種掉資料或是 deadlock。來自 Google 的 [@rakyll](https://twitter.com/rakyll) 列出一些和資料庫相關常見的誤解和經驗，其實每個主題都可以獨立寫篇文章，以下稍微摘要：

1. **當 99.999% 的時間網路不構成問題時，恭喜！你很幸運： **網路非常不可靠，從硬體，拓撲到鯊魚咬電纜（[台灣人早就知道會咬了](https://news.ltn.com.tw/news/life/breakingnews/2617852)），而且網路掌控在大型企業或雲端供應商手中，對開發者來說很難鑑定其錯誤。
2. **一個 ACID，各自表述：** 不是所有資料庫都符合 ACID，宣稱符合 ACID 的資料庫也不一定行為正確，這裡 MongoDB 的沒開 journal 60 秒才 fsync 一次的事件又被拿出來鞭屍，當然，最近 [Jepsen 幹爆 MongoDB 4.2.6](https://jepsen.io/analyses/mongodb-4.2.6) 的事件也可以關注一下。
3. **每個資料庫能達成的一致性和隔離性程度不同：** ACID 的 Consistency 和 Isolation 的光譜其實很廣，而且這兩個特性其實很貴，所以不同資料庫的 tradeoff 不盡相同，可以參考 [Jepsen Consistency Model](https://jepsen.io/consistency) 還有各資料的 [Isolation Level 大表](https://github.com/ept/hermitage)看看你要什麼
4. **不適用 exclusive lock 時，樂觀鎖是個選項：** 樂觀鎖是一種在讀取 tuple 時先記錄 checksum/timestamp/version 資訊，寫入時再檢查 tuple 的這些資訊是否改變來決定寫入與否（但要注意 isolation level 和 dirty read 的關係，如果 write 太多可能樂觀鎖效能會較差）
5. **除了 dirty read 和 data loss，還有更古怪的事：** 前兩者可以透過注意鎖和 race condition 來避免，但 read/write skew 這種邏輯錯誤更難發覺。
6. **我的資料庫和我在執行順序上無法總是達成共識：** txn 的順序是依照接收到 txn 順序執行，而非 code 撰寫順序，如果有不同的操作需要保證順序，請包入同一個 txn。
7. **application-level sharding 可以實作在應用層之外：** 例如額外的 sharing service 處理這塊，application 還是處理商業邏輯就行，像 YouTube 底層的 Vitness ，或是 Shopee 底層的 TiDB 的底層 TiKV 都是箇中高手。
    ![](https://i.imgur.com/cDkVBuL.png)
    ![](https://raw.githubusercontent.com/tikv/tikv/c8afff7147c9bb80c5b47a1a79f59d7dc2dec81b/images/tikv_stack.png)
8. **`AUTOINCREMENT` 有害論：** 在分散式系統不易生成正確的 `AUTOINCREMENT` ID、當作 partition key 可能會產生 hotspot、有其他 unique key 是 `AUTOINCREMENT` key 就是廢物
9. **資料雖過期但有用（而且是 lock-free）：** MVCC 可以達到 Repeatable read isolation level，對 read-heavy app 或是 globally distributed app 能有效降低延遲。（代價就是偶爾要跑 GC 或 `VACUUM`）
10. **時間會在不同來源間扭曲：** 所有時間 API 都在說謊，就算用 NTP 服務還是有網路延遲。作者在這邊偷偷推銷 Google 的 TrueTime，但有趣的是 API 回傳是個 time range，當前時間就落在這個範圍中。
11. **我都把「延遲」念「延遲」：** latency 在不同領域意義不同，client latency = database latency + network latency，服用前請看說明書。
12. **評估效能該考慮 per transaction 等場景的需求：** 幫自家資料庫打廣告時不能只著重在 read/write throughput，應還要設計不同的場景、constraint、transaction 才能，脫離應用場景的 benchmark 都是流氓。
13. **nested transaction 有害論：** nested txn 會導致非預期的行為，例如 如果 inner txn 錯誤 rollback，那 outer txn 該 rollback 嗎？如果是開發 request-response 的 web app，我自己會傾向一個 request-response 就是一個 txn。
14. **transaction 不該管理應用層的狀態：** 如果一個 txn 改變的 global state 但是 txn failed，retry 第二次時哪個 global state 就和第一次不一致了。
15. **query planner 能協助理解資料庫：** 可以知道到底是 table scan 還是 index scan 等來決定 SQL 怎麼寫可以最佳化。
16. **online migration 複雜但可行：** 拆成一個個可復原的小步驟，dual write -> change read -> change write -> remove old model，可以參考 [Stripe 怎麼做](https://stripe.com/blog/online-migrations)，當然，還有 code-first 和 data-first 等不同的 migration mode。
17. **可觀的資料庫成長所帶來的狀況難以預測：** 這正是為什麼我們要在 scaling 前各種 migration/refactor/rewrite，不要以為你懂資料庫底層運作就很屌，從 hotspot、data 分佈不均、容量硬體、流量網路 partition，Scale will introduce new unknowns。（然後各種 data model 到部署流程和大小都要改變）
