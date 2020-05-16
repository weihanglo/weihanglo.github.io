---
title: "WWW 0x11: 庫存文章已用罄"
date: 2020-05-16T00:00:00+08:00
tags:
  - DevOps
  - Kubernetes
  - Rust
---

這裡是 WWW 第拾柒期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。


## [Optimizing Kubernetes Resource Requests/Limits for Cost-Efficiency and Latency / Henning Jacobs](https://youtu.be/eBChCFD9hfs)

![](https://i.imgur.com/QtqZvXs.png)

如何設定 K8s Pod 的資源最低需求 `containers.resources.requests` 和最高限制 `containers.resources.limits` 一直是門藝術，最低需求影響 scheduler 如何安排 pod，最高限制，尤其是 memory，可能會有 OOM kill 把 pod 殺死。

[@hjabocs](https://github.com/hjacobs) 分享了幾個作法：

- 測來測去發現停用 [CPU CFS](https://en.wikipedia.org/wiki/Completely_Fair_Scheduler) 的 latency 最小
- 要記得你的 node 會被 system、kubelet，還有 container runtime 佔去部分資源 😨
- 用 Admission Controller 設定和 requests 一樣的 limit，防止 overcommit
- 知道你的 pod 的 container-aware limit，例如 JVM 就是 maxheap，node cluster 就是你設定的 process number
- 用他的本人寫的 [K8s Resouce Report](https://github.com/hjacobs/kube-resource-report) 來看冗余資源可以幫你省下多少美金
- 可以設定一些 priorityclass 很低的 pod 作為 buffer capacity，讓資源不足時他們可以先被踢掉應急，再慢慢等 Cluster autoscaler 來 privision 新 node
- 又在老王賣瓜推銷自己寫的 [downscaler](https://github.com/hjacobs/kube-downscaler)，離峰時間自動關機省錢

## [Rust Logo is a Bike Chainring!](https://bugzilla.mozilla.org/show_bug.cgi?id=680521)

[![](https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Kettenblatt.jpg/128px-Kettenblatt.jpg)](https://commons.wikimedia.org/wiki/File:Kettenblatt.jpg)

![](https://www.rust-lang.org/static/images/rust-logo-blk.svg)

關注 Rust 社群這麼久了，直到最近才意識到 Rust 的 Logo 其實是單車的大盤（踏板旁的齒盤），原意是 Rust 作者們常常騎單車，而且單車大盤通常都有點生鏽。身為單車愛好者怎能不愛 Rust ♥️

## [Cardinality is key](https://www.robustperception.io/cardinality-is-key)

最近遇到了寫出很爛的 Prom Query 還有短時間發送太多 Query，導致整個 Prometheus 服務火爆炸開，當然，Prometheus 的 High Available 有很多種做法，例如導入 [Thanos](https://thanos.io)/[Cortex](https://cortexmetrics.io/)，使用外部 storage 等等，不過根本下手，應該要改善 metrics 和 query 這層的效能，否則只是矇著眼騙自己。

這篇文章開頭就點出最重要的一句話： **Prometheus 的效能幾乎皆取決於 label cardinality** 。這裡的 cardinality 指的是唯一值的數量。

文中簡單計算了 label cardinality 多容易爆炸，假設我們有一個 Node.js 服務有 100 replicas， 會追蹤 heap 上新生，中生代等 12 種相關指標，若系統每 30 秒抓一次資料，拉三個小時的報表算起來就有 `100 * 12 = 1200` 個 series，也就是有 `1200 * (60 * 60 * 3 / 30) = 432000` 個資料點，聽起來不太多對吧，但通常一個 Prometheus 不會只看一個 metrics 也不只有一個服務，真實的爆炸程度超乎想像。

作者提供了一般性通則： **避免 cardinality 超過 10 的 label** 。但這僅僅是通則，如果 replicas 數量不會太大，cardinality 超過 10 也可接受。

你會想說，媽的我不能最終這麼細，還要蒐集 metrics 幹啥吃？其實 nginx-ingress 團隊也因為 [`uri`、`remoteAddress` 等 label cardinality 太爆炸而移除過於細緻的 label](https://github.com/kubernetes/ingress-nginx/pull/2701)。

文末畫龍點睛的一句話，分享給大家細細品味： 

> Metrics giving you a high level view of your subsystems, logs the blow-by-blow of individual requests.
