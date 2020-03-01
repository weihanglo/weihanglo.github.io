---
title: "WWW 0x05: 若單體服務是屎，微服務就是許多屎"
date: 2020-02-22T00:00:00+08:00
tags:
  - Weekly
  - Microservice
---

這裡是 WWW 第伍期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Microservices: From Design to Deployment](https://www.nginx.com/blog/introduction-to-microservices/)

![](https://i.imgur.com/6uLbuzb.png)

這是 [microservices.io](https://microservices.io) 的作者在 NGINX blog 上面的系列文章，雖然是 2015 年的舊文，從起源、問題，和模式來理解微服務依然詳實，看完絕對驚呼：原來現在 Cloud Native 世界這麼混亂是有些道理！

> Note：不知道為什麼作者很愛提到 Netflix 各種微服務的專案，不過 Netflix 的 Java 開源微服務工具數量之多還真大開眼界

以下分別摘要每個主題：

### [Introduction to Microservices](https://www.nginx.com/blog/introduction-to-microservices/)

簡介什麼是微服務，有什麼優缺點，並介紹微服務架構下常見元件，鋪陳給接下來的系列文，總之是個不想看可跳過的篇章。

### [Building Microservices: Using an API Gateway](https://www.nginx.com/blog/building-microservices-using-an-api-gateway/)

介紹 API gateway 為什麼存在：統一微服務一致對外的介面，解耦客戶端與微服務們，但缺點是 API gateway 需要更多 operational cost，也要維持 hign availibility。

實作 API gateway 要注意以下幾點：

- Performance：所有請求都會通過 gateway，所以效能和擴充性一定要好
- Reactive Programming 模式：gateway 需要集合各種請求，善用 Reactive programming 模式很有幫助
- Service Invocation：微服務之間就是 IPC（inter-process communication），如何透過不同模式相互 invoke 很重要，下一章會詳述
- Service Discovery：如何讓服務之間互相知道彼此，就是「服務發現」的工作了，分為 client-side 和 service-side discovery，之後有專文說明
- Partial Failures：微服務之間不像單體服務可以用簡單的 transaction 處理錯誤並 rollback，處理部分錯誤，保持 CAP 的 consistency 是個重要課題

### [Building Microservices: Inter‑Process Communication in a Microservices Architecture](https://www.nginx.com/blog/building-microservices-inter-process-communication/)

介紹微服務間 IPC（inter‑process communication）的方法與模式，這是系列文中最接近實作層面的文章，很棒。

IPC 常見的溝通模式根據同步與非同步，以及一對一或一對多，有許多不同的作法，例如 request-respone（一對一、同步）、publish-subscribe（一對多、非同步）。而常見的技術有：

- **Message-based communication（message queue）**
  - client-service 完全解耦合
  - message 有 buffering
  - 有明確的 IPC，反觀 RPC 可能會以為自己在 invoke local function
  - 系統複雜度增加不少
  - 非同步，不容易做到同步的 request-response 互動模式
- **同步溝通：REST**
  - 對 entity/resource 操作，很簡單，大家都熟悉
  - 如果用 HTTP，防火牆通常不會擋
  - 因為是同步的溝通，client 和 server 要一起等待互動結果出爐
  - client 必須明確知道自己要到哪裡找資源，這部分有較重的耦合
  - REST 有個 [4 level 的 Maturity Model](https://martinfowler.com/articles/richardsonMaturityModel.html) 可以參考
- **同步溝通：Thrift（注：其實應該要泛稱各種 IDL）**
  - 一個老牌，可以作為 IDL 的 binary format
  - 有 compiler 可以協助產生各種語言的 code
  - （注：個人偏好 ProtoBuf 或是 FlatBuffer 這些更高效支援也廣的格式）

 而 message format 也是重要的課題：選擇好用的 IDL 可以減少雙方來來去去修改 spec 的時間，例如 [JSON schema](https://json-schema.org/) 或 [Protocol Buffer](https://developers.google.com/protocol-buffers)。

### [Service Discovery in a Microservices Architecture](https://www.nginx.com/blog/service-discovery-in-a-microservices-architecture/)

Service discovery 可以動態改變每個服務的位置，讓服務之間不再需要寫死 IP，使得部署與 scaling 更為彈性，主要分為兩種方式：client-side 與 server-side。

- client-side：client 詢問 service registry 來取得可用的服務位置，而且可以做到 client-side load balancing，但相對地，不同語言的 client 都需要實作一遍這個 discovery 邏輯
- service-side：服務隱藏在 load balancer 後，load balancer 詢問 service registry，再決定要用哪個服務，完全抽象於 client 外，但也必須導入 load balancer 這個角色而且必須做 HA。

此外，實作 service discovery 最重要的元件是 service registry，將服務註冊在 registry 上，讓其他服務可以透過 registry 發現彼此，常見使用 [etcd](https://etcd.io/)、[consul](https://www.consul.io) 和 [ZooKeeper](https://zookeeper.apache.org) 達成。註冊的方式有

- 自我註冊 Self‑Registration：服務自己主動向 registry 註冊/取消註冊
- 第三方註冊 Third‑Party Registration：額外的 registrar 訂閱該服務的事件或 healthcheck，來決定是否註冊或取消註冊

### [Event-Driven Data Management for Microservices](https://www.nginx.com/blog/event-driven-data-management-microservices/)

本篇探討在微服務這種分散式架構下，每個服務都有獨立的資料庫，甚至資料庫的類型還不一樣，那如何保證 ACID、如何在 CAP 理論中作出取捨，two-phase commit（2PC）過於注重 C（consistency），不符合現代架構要求的 availability，因此，這裡提出 **event-driven architecture**：

- 事情發生會 publish event
- 其他服務會訂閱這些 event 做對應處理
- 可以保證 [BASE model](https://queue.acm.org/detail.cfm?id=1394128) 中的 eventual consistency
- 可以透過特定方法達成 Atomicity
  - **使用 local 的 transaction：** event 不直接 publish 到 message broker，而是利用 local 的 transaction 寫入到 event table 中，再透過另一個 Event publisher 服務發布至 message broker
  - **從資料庫 transaction log 挖寶：** transaction log 裡面資料 100% 完整，可做為 event 來源，但是 log 太生不好處理，而且和選用的資料庫緊耦合
  - **使用 [Event sourcing](https://github.com/cer/event-sourcing-examples/wiki/WhyEventSourcing)：** 將原本 mutate 資料庫 table 的操作都改成一個個事件，例如 Order 狀態改變變成一個個 Order.completed Order.pending 事件，因為不再將資料映射到 Object entity，不僅省了 ORM 抽象，更保證資料 consistency（因為根本不會 mutate state），在 persistent data 的同時也會直接 publish event，但缺點是不好設計，而且不直觀，需要使用 [Command Query Responsibility Segregation（CQRS）](https://github.com/cer/event-sourcing-examples/wiki) 達成特地的查詢操作。

### [Choosing a Microservices Deployment Strategy](https://www.nginx.com/blog/deploying-microservices/)

由於微服務架構不論數量、語言、框架種類通常比單體架構更多，因此更難部署，這篇整理了許多不同的部署策略：

- 一個 host 多服務
  - Pros：部署最直接、資源運用率高
  - Cons：抽象化不夠，服務直接沒有隔離
- 一個 VM 一個服務
  - Pros：服務間獨立、安全性
  - Cons：資源運用率低、啟動慢
- 一個 container 一個服務
  - Pros：啟動快、image 容器化容易部署、隔離完善
  - Cons：資源運用率比 VM 高但比單一 host 低、比 VM 安全性低一些
  - 如果有 cluster manager 例如 kubernetes 會增加資源運用率
- Serverless
  - Pros：不需管理 infra、by request 算錢
  - Cons：僅適合 stateless 服務但不適合 long-running 服務、受限於 runtime 語言支援程度

### [Refactoring a Monolith into Microservices](https://www.nginx.com/blog/refactoring-a-monolith-into-microservices/)

如何從遷移到基本上是老生常談，還是條列有提到的策略好惹：

- **停止堆屎：** 知道目前的單體架構是一坨屎，新 feature 就別再往上加了
- **切堆分層：** 架構通常分為 1）presentation layer，和 UI 或 REST API 等相關，2）business logic layer，都是業務邏輯，以及 3）data-access layer，存取資料庫或是訊息中介 message queue 等。切好切滿更容易抽象出微服務
- **抽出服務：** 乍看之下不知道在講啥，但提到需要以 module 為單位來抽象（前提是 module 權責分明），如果本來就有遵守 [Domain Model pattern](https://martinfowler.com/eaaCatalog/domainModel.html) 會更好抽象
