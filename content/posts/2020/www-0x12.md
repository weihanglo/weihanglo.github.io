---
title: "WWW 0x12: Oxidized Chromium?"
date: 2020-05-23T00:00:00+08:00
tags:
  - DevOps
  - Kubernetes
  - Security
  - Databases
---

這裡是 WWW 第拾捌期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [10 Ways to Shoot Yourself in the Foot with Kubernetes, #9 Will Surprise You - Laurent Bernaille](https://www.youtube.com/watch?v=QKI-JRs2RIE)

Datadog 的工程師分享十個在正式環境踩到的 K8s 坑，這邊簡單條列標題，有興趣的請直接看影片：

1. 永遠是 DNS 的鍋
2. Job 沒開始，Image 又 pull 失敗惹
3. 我不能 kubectl 了：apiserver 被 DDOS 而且 OOM killed
4. 新 node 不能 schedule pod
5. log volume 成長了十倍：都是一堆 audit logs
6. 我的 pod 怎麼沒有漲到 replicas 數量
7. 120 node 的 Cassandra cluster 爆了
8. Deploy 的 heartbeat 越來越慢
9. Runtime 壞了（寫壞的 readinessProbe、效能問題）
10. 優雅地關閉你的 pod

## [RedisJSON - a JSON data type for Redis](https://oss.redislabs.com/redisjson/)
Redis 可以和 NGINX 一樣支援 [load 各種外掛 modules](https://redis.io/topics/modules-intro)，而且 Redis 官方（RedisLabs）甚至做了可以在 Redis 裡面操作 JSON 的 [RedisJSON](https://oss.redislabs.com/redisjson/)。

[Benchmark 顯示 RedisJSON：](https://oss.redislabs.com/redisjson/performance/#performance)

1. 整個 object root 的 get/set 比 lua script 的 cjson 和 msgpack 慢，雖然已經不錯了
2. `object.path` 的 get/set 完全相反過來，一整個好非常多，，隨著 payload size 上升 ops 還是維持常數

感覺如果有 nested JSON update on Redis 需求可以考慮，而且這個 module 不小心用到 Rust 的 `bson`（現由 MongoDB 官方維護）和 Rust 社群最知名最強大的 `serde_json` JSON 序列化反序列化這兩個 crate， ~~哪間公司採用 RedisJSON 後想要 fork 可以找我~~。


附上範例：

```
127.0.0.1:6379> JSON.SET foo . '"bar"'
OK
127.0.0.1:6379> JSON.GET foo
"\"bar\""
127.0.0.1:6379> JSON.TYPE foo .
string

127.0.0.1:6379> JSON.SET arr . []
OK
127.0.0.1:6379> JSON.ARRAPPEND arr . 0
(integer) 1
127.0.0.1:6379> JSON.GET arr
"[0]"
127.0.0.1:6379> JSON.ARRINSERT arr . 0 -2 -1
(integer) 3
127.0.0.1:6379> JSON.GET arr
"[-2,-1,0]"
```

## [The Chromium Projects: Memory safety](https://www.chromium.org/Home/chromium-security/memory-safety)

![](https://www.chromium.org/_/rsrc/1589581287612/Home/chromium-security/memory-safety/piechart.png)

Chromium 團隊檢視了目前 Chromium 軟體漏洞分類，並做出未來的行動規劃：

- 將近七成是 memory unsafety，也就是 C 和 C++ 指標使用錯誤導致，而其中一半是 use-after-free 這種問題
- Chromium 安全機制很大一部分建立在「產生不同 process 來隔離資源作為沙盒」，但 process 不便宜，尤其在手機上
- Network layer 仍是整個 app 共用，違反了 [Rule Of 2](https://chromium.googlesource.com/chromium/src/+/master/docs/security/rule-of-2.md)，但把 network 拆成 per-process 資源消耗會更可怕

魔高一丈，道高一尺，團隊覺得不行動就等死，所以有了以下幾個方向：

- 開啟 std/abseil（類似 boost 的 std extension lib） 檢查 caller 的編譯機制、用更多 GC 機制
- 自己做個 C++ 方言，並限制使用 raw pointer
- 使用更 memory safe 的語言：Java/Kotlin、JavaScript、Rust、Swift
- 最適切的語言選擇要有編譯期的安全檢查，而且效能影響要夠低
- 團隊能預見導入新語言的 bridge 成本存在（軟體面、工程面都有指涉我猜）
- Chromium 已經有個 [Rust 實驗性分支](https://chromium-review.googlesource.com/q/project:experimental/chromium/src+branch:refs/wip/rust-experimental-branch)

![](https://www.chromium.org/_/rsrc/1589569060172/Home/chromium-security/memory-safety/sat3CHOc8lXZbGicChW6w5Q.png)
