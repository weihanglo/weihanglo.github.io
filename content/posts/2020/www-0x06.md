---
title: WWW 0x06
date: 2020-02-29T00:00:00+08:00
tags:
  - Weekly
---

這裡是 WWW 第陸期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [WebAssembly Isolation with Tyler McMullen](https://softwareengineeringdaily.com/2019/09/25/webassembly-isolation-with-tyler-mcmullen)

聽了一集個人覺得不難但蠻有內容的 Podcast，主要在講 Isolation 和 WebAssembly 相關的知識，我覺得 web developer 都很值得稍微聽一下，內容包含：

1. 概要提點了 VM vs. Container 等各種 Isolation 的差異
2. WASM 如何 isolation workloads：限制 jump instruction 跳到任意的地方 etc.
3. Fastly 為什麼要使用 WASM： 一個請求本來可能要起 container，但 container 啟動時間還是不夠快，WASM 的 isolation 可以提供安全快速的環境
4. WASM 使用 [linear memory model](https://webassembly.org/docs/semantics/#linear-memory)：和一般的 virtual memory 不同，memory space 是連續性一個 block，需要用到更多再與系統 / 瀏覽器請求
5. WASM 還在解決的問題：與外部世界互動的標準還沒完整， 但可以參考 Fastly 和 Mozilla 等幾個大廠訂定的 [WASI（WebAssembly System Interface）](https://hacks.mozilla.org/2019/03/standardizing-wasi-a-webassembly-system-interface/)
6. WASM 目前 function pointer 只能用 dynamic dispatch，對要求極極極高效能的應用場景較不吃香
7. 市面上的 WASM runtime：[lucet](https://github.com/bytecodealliance/lucet)、[wasmtime](https://github.com/bytecodealliance/wasmtime)（個人補充 wasmer）

> Note: Fastly 是市面上前十大的 CDN provider（約第六）

## [An Introduction to Python Concurrency](https://www.slideshare.net/dabeaz/an-introduction-to-python-concurrency)

如果你想用 Python 寫 Concurrency Programming，大推這篇！

雖然這份簡報因為早在 2010 年製作，沒有提到 `async`/`await`，但內容非常紮實，摘錄我有印象的點：

- `threading` 應用時機與底層概念
- 各種常見鎖的原理與應用時機
- GIL 原理以及如何克服
- `multiprocessing` 應用時機，並與 `threading` 比較
- 使用上述工具實作高層次抽象的 message queue、event communication

其中讓孤陋寡聞的我最驚艷的是，原來 pickle 可以再 thread/process 中序列化 class instance，太好用了！

## [Load balancing and scaling long-lived connections in Kubernetes](https://learnk8s.io/kubernetes-long-lived-connections)

一行摘要：Kubernetes 的 Service 資源提供負載均衡功能，但並沒提供 long-lived connection 負載均衡。如果使用 gRPC、AMQP、HTTP/2 或資料庫連線等，可能需要做 client-side 負載均衡。

本篇圖文並茂，詳細說明：

- Kubernetes 如何透過 Service 做 proxy
- 但 iptable 用機率選擇 IP 而不算能有做負載均衡
- long-lived connection 為什麼會造成負載不均衡
- 如何解決 long-lived connection 造成負載不均衡的問題
    1. 做 client-side 負載均衡：提供 client 所有服務節點，讓 client 自己選擇要送到哪個節點
    2. 用 service mesh（[Linkerd](https://linkerd.io/)、[Istio](https://istio.io/)）
- 哪些情境下可暫時忽略這個問題，哪些不行
	- ✅ 多 client 少 server
	- ❌ 少 client 多 server

> 本文連圖片都有 step-by-step guide，不愧是教學為重的 [learnk8s.io](https://learnk8s.io/)
