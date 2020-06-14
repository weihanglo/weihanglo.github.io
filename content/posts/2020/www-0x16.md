---
title: "WWW 0x16: JWT、分散式 ID 生成、k8s 安全性"
date: 2020-06-20T00:00:00+08:00
tags:
  - DevOps
  - Distributed Systems
---

這裡是 WWW 第貳拾貳期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Kubernetes Blog: 11 Ways (Not) to Get Hacked](https://kubernetes.io/blog/2018/07/18/11-ways-not-to-get-hacked/#11-run-a-service-mesh)

管理 Kubernetes 就和管理 VM 一樣，一定會遇到各種安全性問題，這篇文章提出 11 種可以增加安全性的小撇步，順便分享 [@hwchiu](https://www.hwchiu.com/k8s-security-11tips-i.html) 整理的中文版，資訊更多更完整，感恩惜福。

## JWT 是否適合 session mechanism

最近翻到 [The Ultimate Guide to handling JWTs on frontend clients](https://hasura.io/blog/best-practices-of-using-jwt-with-graphql/) 這篇小巧精緻的 JWT 身分驗證教學，流程圖簡明易懂，內容包括：

- JWT 的結構：`header.payload.signature`
- JWT 會儲存在 client-side，不適合儲存敏感資料
- JWT 不適合放在 browser storage，容易被 XSS（所以推薦 in-memory）
- 由於 JWT 本身無狀態，誰幹走都能奪權，請保持 JWT 過期時間不會太長，文中案例是 15 分鐘
- 鑑於過期比較快，請配合 `HttpOnly` 的 cookie 的 refresh token 來更新 JWT（但 XSS 還是有點不安全）
- Revoke all login sessions 可以簡單透過 refresh token 達成：刪除該使用者的所有 refresh token 就行
- Server-side rendering 和 JWT + refresh token 如何整合：JWT 會存在 SSR server 上，refresh token 則是每個 page request 都會產生新的 token

有趣的是，留言提出許多 JWT 與這篇文章的實作總總問題，像是：

- JWT 不適合用在 session 上
- 文章 refresh token 還是會被 XSS
- 多個 tab 同時發送 refresh token API 要如何處理
- IETF RFC 建議 refresh token 每次 refresh 都要產生新的

句句都在逼宮作者，但作者完全沒有出來說明，於是我只能好好點擊進入留言中的文章分享。不看也罷，一看便驚天地泣鬼神。

這篇 [Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/) 的標題就破題了（好像很正常），主要是在戳破那些 JWT 沒有告訴你的事，主要是：

- JWT 開啟 session 透過 JavaScript 控制的大門，相較於 `HttpOnly` cookie 更不安全更容 XSS
- 無法主動過期，如果 token 權限設定錯誤或是伺服器受攻擊，很難第一時間解決問題
- 還是需要 cookie consent，functional purpose  像登入使用產品服務，本來就不需要 cookie consent，追蹤行為才需要使用者同意。

看來 JWT vs. cookie 大戰還會持續下去。

## [Leaf——美团点评分布式ID生成系统](https://tech.meituan.com/2017/04/21/mt-leaf.html)

本篇文章把分散式 ID 生成常見的解法和需求點出來，最後歸納出適合美團使用的 [Leaf](https://github.com/Meituan-Dianping/Leaf)。重點節錄：

- **UUID：** 長度太長，而且無序，一般 RDMBS index 都是 B+ tree，不適合無序資料（所以 laravel 做了一個 [timestamp-first ordered UUID](https://itnext.io/laravel-the-mysterious-ordered-uuid-29e7500b4f8)）
- **snowflake：** 很讚很快，有序但並非 `autoincrement` 的 ID，不過相依機器時鐘，如果不小心 sync NTP 之類的，可能就會產生重複 ID
- **用資料庫生成 ID：** 很 robust，但資料庫本身就會變成瓶頸，可以用 step 解決，也就是多台機器，每台發不同 step 的號碼

以下是 Leaf 兩種 ID 生成的簡單介紹：

- **Leaf-segment：** 和資料生成類似，不過一次發一個區段（例如 1-1000）的號碼，讓 DB 壓力小很多，而且可以在取到 10% 是先去取得下一個 segment，降低 latency
- **Leaf-snowflake：** 註冊到 ZooKeeper 來產生 worker ID，server 啟動時檢查時間是否正常，不正常就等到時鐘追上或重試，然後關掉 NTP....

