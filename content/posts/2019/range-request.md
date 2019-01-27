---
title: 理解 HTTP Range Requests
date: 2018-03-09T10:17:34+08:00
draft: true
---

你是否曾遇過使用瀏覽器下載大檔案時網路中斷，又要從頭下載的經驗？這是因為 HTTP 傳輸協定模型是一個請求對應完整的回應 payload，因此 client 與 server 連線中斷後，若欲繼續取得資源，須將從頭再下載完整資源，之前的傳輸可說是完全浪費了。

而 HTTP/1.1 中的 **Range Requests** 或許是這類問題的救贖，讓我們一探究竟吧！

## Table of Contents

- 發送一個 Range Request
    - `Range`
    - Range Units
- 回應 Range Request
    - `Content-Range`
    - `Accept-Range`
    - `206`
    - `416`
- 確認資源的新鮮度
    - Precondition
    - `If-Range`
- 完整流程圖
- 參考資料

_（撰於 2018-03-10）_

## 簡介

## 發送一個 Range Request

照字面上來說，Range Requests 即是 client 向 server 請求該資源的特定範圍，避免再次傳輸完整資源的開銷。

我們嘗試發送一個 Range Request，其實非常簡單，只要在 Request header 中加入 `Range` header field 就行了，範例如下：

```
GET /z4d4kWk.jpg HTTP/1.1
Host: i.imgur.com
Range: bytes=0-1023
```

### `Range`

`Range` field 是發送 Range Request **必備**的 header field，組成形式如下：

```
"range-unit"="range-set"
```

等號前面值稱為 **Range Units**，表示 Range 範圍的單位。除了自定義的 unit 之外，HTTP/1.1 僅定義一種 Range Units：`bytes`，範圍如同字面，一單位代表一位元組，offset 從 0 算起：

| Case                   | Explanation                              |
| :--------------------- | :-------------------------               |
| `Range: bytes=0-112`   | 前 113 個 bytes（0 到 112）              |
| `Range: bytes=-50`     | 最後 50 個 bytes                         |
| `Range: bytes=123-123` | 從 offset 為 123 到 123 的 bytes         |
| `Range: bytes=123-`    | offset 為 123 的 bytes 到最後一個 bytes  |

於是，可以將前例的 GET 請求解讀為「**向 imgur.com 請求該資源的第 0 個 bytes 到 1023 bytes 的部分資料**」。

## 回應 Range Request

Server 回應 Range Request 就複雜多了

- Headers
  - `If-Range`: 
  - `Content-Range`
  - `Range`
- Response 流程
- Combinded Range

常見的應用場景你我都很熟悉：下載續傳功能。

Range requests 在 HTTP/1.1 中是一個選用的標準，若無支持，則簡單退化到一般的 GET 請求。
Range requests 使用 status code `206` 來區分與一般 GET 請求，以免誤認為是完整的 Response 而錯誤快取了。

- range requests, 
- partial responses 
- `multipart/byteranges` media type

Client range request 應以升冪方式排列 byte-range

## Server 該如何回應 `Range` header field

- 在其他 header 處理完後，最後處理 `Range`，也就是說，如果其他 header 以及導致 response 304，那麼 `Range` 就會被忽略。
- 當 precondition 都是 true 時
  - 指定的 range 有效且滿足必要條件
    - `206`（Partial Content）
  - 指定的 range 無效或不滿足必要條件
    - `416`（Range Not Satisfiable）

## If-Range

`If-Range` 的作用如下：

可視為一個短路，若 representation 未改變，則傳送 Range request 請求的範圍，否則送完整 representation。

- 可作為 precondition
- 只能是 ETag 或 LastModified
- 必須是 strong validator 且 Server 必須執行 strong comparison

## Responses to a Range Request

- 傳輸 single part
  - Response 需包含 `Content-Range` header field
- 傳輸 multiple parts
  - `Content-Range` 隨著 multiparts 傳輸，而不是在 HTTP headers 傳輸。
  - `Content-Type: multipart/byteranges`

`206` response 是 cacheable

## `Content-Range`

在下列 response 中皆需包含 `Content-Range`

- `206`
- `416` with unsatified-range
- multipart/byteranges

- **unsatisfied-range**: `*/65535`
- **完整長度未知**：`2048/*`

## 參考資料

- [MDN: HTTP range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)
- [RFC7232 - Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests](https://tools.ietf.org/html/rfc7232)
- [RFC7233 - Hypertext Transfer Protocol (HTTP/1.1): Range Requests)](https://tools.ietf.org/html/rfc7233)
- [RFC7234 - Hypertext Transfer Protocol (HTTP/1.1): Caching](https://tools.ietf.org/html/rfc7234)
