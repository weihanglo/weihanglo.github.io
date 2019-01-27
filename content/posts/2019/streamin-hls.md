---
title: HLS 串流協議二三事
date: 2019-01-27T12:31:29+08:00
tags:
  - HLS
  - Streaming
---

最近開始研究很夯的直播技術，一般常見的直播方案為 [HLS][hls] 以及 [RTMP][rtmp] 等，本篇將介紹 Apple ~~強迫使用~~ 大力支持的 HLS 協議。

_（撰於 2017-04-10）_

> 本文是兩年前的舊文，剛好最近又開始碰串流，所以拿出來獻醜一下。

## Overview

**HLS** 的全名為 **HTTP Live Streaming**，是一個由 Apple 提出並實作。HLS 是基於 HTTP 的串流協議，實作起來平易近人。如果你想要實作串流但又不想要太複雜的後台配置、或是串流須經加密驗證，HLS 會是一個不錯的解決方案。

## Workflow

HLS 原理非常簡單：

1. 將欲串流的影音媒體檔案進行對應編碼切割為一系列的影音串流片段（media segment，一般為 [.ts 檔][mts]）。
2. 建立索引檔（index file，為 [.m3u8 檔][m3u]）作為 HLS 的播放列表（playlist），指向多個影音串流片段的路徑 。
3. 透過 HTTP 給予 client 對應的 Response（**.m3u8**、**.ts**）。
4. Client 請求並解析索引檔，即可開始串流，按照播放列表逐一下載播放串流片段。
5. 該索引檔的播放列表（playlist）播完後，再請求新的索引檔，繼續串流。

> 簡單來講，就是取得 **.m3u8** 播放列表，按照順序播放 **.ts** 檔，全部放完再請求下一個 **.m3u8** playlist，週而復始。

## Features

HLS 定義許多機制，讓串流得以在各種惡劣的網路連線環境下生存。以下列出幾個 HLS 的重要特色：

### Adaptability and Availability

`.m3u8` 這個 Playlist 檔除了指向影音串流片段路徑，也可以指向其他 Playlist 的路徑。標準架構是有一個 **Master Playlist** 指向其他的 **Media Playlist**（真正包含 **.ts** 的播放列表），達到[自適應串流][adaptive-bitrate-streaming]的結果。

> 自適應串流：根據使用者的頻寬與 CPU 負載，調整至不同 bitrate／影音品質（高清、普清）的串流，使串流體驗更加快速、穩定。

![](https://github.com/videojs/videojs-contrib-hls/raw/master/docs/hls-format.png)

除了可以調整不同 bitrate，`.m3u8` Playlist 尚可提供多個同內容但來源相異的串流，多個 server 同時待命，讓可憐的魯蛇工程師不再為 server 掛掉加班救台灣。

### Based on HTTP Protocol

HLS 基於 HTTP Protocol，得以彌補其他非 HTTP-based 串流協議的缺點：

- **無須專門協議**，可穿越大部分的 router／NAT／Firewall。
- Server／Client 實作容易（支援 HTTP request/response 的 server 即可）。
- 可利用 HTTP-based CDN 作為 distribution server。

### Content Protection

HLS 有提供影音串流片段（Media Segments）個別加密，每個加密的片段需包含 **#EXT-X-KEY** tag，指向 decryption key 進行解碼。取得 decryption key 的方法則未加以限制，可有不同的認證／傳輸方式，端看如何實作（當然，建議使用 HTTPS 傳輸 key）。

### Two Session Types

HLS 分為兩種 session：**Video on Demand（VOD）**與 **Live Sessions**，除了一般的影音串流，更有直播模式可選擇，在此我們先將兩者粗分為 **Static Mode** 和 **Live Mode**。

- **VOD（Static Mode）**:又稱為**隨選視訊／視頻點播**，是播放一個靜態、非直播的影音，相較於一般 H5 的 video tag 或 mp4，擁有動態切換 bitrate（自適應串流）以及驗證加密等技術。

- **Live Sessions（Live Mode）**：顧名思義，就是一般認知的直播，如果 Playlist 不包含 `#EXT-X-ENDLIST` Tag，Client 將處於 live session，會不斷加載新的 index file（**.m3u8**）。

## Architecture

概念上，HLS 的實作分為三個重要角色：

- **Server Component** -> 負責影音前置作業的 server
- **Distribution Component** -> 負責 serving file 的 HTTP server
- **Client Software** -> 負責發送、接收、解析、並呈現串流的 client

蘋果親爹對該三角色的示意圖如下：

![HLS Basic](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/art/transport_stream_2x.png)

以下介紹圖中三個要角的內容：

### Server Component

如圖所示，主要工作就是：「接受影音輸入，並將影音轉碼為 [MPEG-2 Transport Stream][mts] 格式、最後分割為方便傳輸小片段」。此外，server 在切割片段時，必須產生對應的 Playlist（**.m3u8**），Playlist 內含有影音片段的有序播放列表。若檔案經過加密，server 需替 Playlist 注入對應的 **#EXT-X-KEY** tag，指明 decryption Key 的 URI。

### Distribution Component

就是一個 HTTP web Server，不需為了發送資料而自定義模組，透過簡單的 Request／Response，向 Clients 發送對應的影音媒體檔案。這個 HTTP Server 僅需簡單的配置，如將 MIME type 限制在 **.m3u8** 與 **.ts** 檔案。

### Client Software

Client 的職責為解析索引檔（**.m3u8**），並依照索引檔提供的 URL 下載串流影音檔（**.ts**），串流檔下載足夠量時，組裝影音檔並呈現給用戶。

在有需要時，Client 需實作切換不同品質／來源的串流源。若檔案經加密，Client 需依照索引檔的 URI 下載 decryption key 解密，並在必要時呈現認證畫面。

## Reference

- [Apple - Streaming](https://developer.apple.com/streaming/)
- [IETF Drafts - HTTP Live Streaming](https://tools.ietf.org/html/draft-pantos-http-live-streaming)
- [Wiki - HTTP Live Streaming][hls]
- [Wiki - M3U][m3u]
- [HTTP Live Streaming (HLS) - 概念](https://www.jianshu.com/p/2ce402a485ca)

[hls]: https://en.wikipedia.org/wiki/HTTP_Live_Streaming
[rtmp]: https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol
[mts]: https://en.wikipedia.org/wiki/MPEG_transport_stream
[m3u]: https://en.wikipedia.org/wiki/M3U
[adaptive-bitrate-streaming]: https://en.wikipedia.org/wiki/Adaptive_bitrate_streaming
