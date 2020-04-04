---
title: "WWW 0x0B: 個資被偷和管理 DNS 紀錄，孰難孰易"
date: 2020-04-04T00:00:00+08:00
tags:
  - Weekly
  - Rust
  - Kubernetes
  - Privacy
---

> Zoom 很讚，host 可以看你有沒有認真
>
> — Zoom: Attendee attention tracking

這裡是 WWW 第十一期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [What future does the captical of Japan carry?](https://bit.ly/2S7NwbL)

> Note: 東京不算是日本的「法定」首都

這份簡報講解 Rust 最流行的非同步框架 [Tokio](https://tokio.rs/) 運作原理，透過圖像化的流程說明 `future` 如何於 Tokio 互動中被 poll 和 waken，非常直觀易理解，比敝人在 COSCUP 2019 的簡報 [Our Future in Rust](https://weihanglo.tw/slides/coscup2019-our-future-in-rust.pdf) 好太多了。

![](https://rust-lang.github.io/futures-rs/assets/images/futures-rs-logo.svg)

## [Using Zoom? Here are the privacy issues you need to be aware of](https://protonmail.com/blog/zoom-privacy-issues/)

因為疫情緣故，最近 Zoom 很夯，剛好有篇文章寫到 Zoom 有很多噁心有趣的 feature：

- host 可以看參與者專不專心，超過 30 喵沒在看 zoom 就會 alert
- 會存一份聊天紀錄給 host，但沒說 private message 會不會給 host
- 宣稱蒐集名字、實體位置、email、電話、公司和職稱但不會拿去賣，只會用在「business purposes」

推薦有空看看這篇文章，尤其是「How you can protect your data」一節。

## [controller.go:796\] only numeric ports are allowed in ExternalName services: http is not valid as a TCP/UDP port](https://github.com/kubernetes/ingress-nginx/pull/4449/files#diff-86ac9ff9d75a0c5005c116e766a6127dL851)

最近一些第三方服務需要設定 custom domain，DNS 簡單解決，但掛 SSL 憑證卻有點棘手，由於不想額外開一台 proxy
 server，決定使用 **Plan A： 使用既有的 NGINX** 。我們的 custom domain 需求是兩層 subdomain 的 `one.two.example.com`，而當前憑證是 `*.example.com` 的 wildcard certificate，原本以為可以成功掛憑證，卻一直沒有成功，後來才知道 [wildcard certificate 只支援一層 subdomain](https://www.ietf.org/rfc/rfc2818.txt)。

```
Matching is performed using the matching rules specified by
[RFC2459].  If more than one identity of a given type is present in
the certificate (e.g., more than one dNSName name, a match in any one
of the set is considered acceptable.) Names may contain the wildcard
character * which is considered to match any single domain name
component or component fragment. E.g., *.a.com matches foo.a.com but
not bar.foo.a.com. f*.com matches foo.com but not bar.com.
```

於是，改用 **Plan B：Cloudflare 的 Universal SSL 免費掛憑證** ，嘗試將 DNS 導向 Cloudflare，卻發現 [Universal SSL 也不支援 multi-level subdomain（除非付錢）](https://support.cloudflare.com/hc/en-us/articles/204151138-Understanding-Universal-SSL#h_408802647171549663799400)，只好 say goodbye。

最後只能使出 **Plan C：沿用在 Kubernetes 上的 NGINX Ingress Controller** 。先將 DNS A record 導向 ingress controller，然後建立 `ExternalName` 的 service 指向第三方服務，再透過 [cert-manager](https://cert-manager.io/) 發憑證。豈料一直無法成功掛上憑證，原來是 0.26.0 版之前的 NGINX Ingress Controller 的 `Ingress` 資源的 backend service 如果是 type `ExternalName`，就只能使用 numeric port，不能使用 [IANA 定義的 named port](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)，本來寫 `backend.servicePort=http` 只好改寫成 `80` port。

附上錯誤訊息：

```
I0229 06:00:03.677872       6 controller.go:177] ingress backend successfully reloaded...
W0229 06:00:06.744761       6 controller.go:796] only numeric ports are allowed in ExternalName services: http is not valid as a TCP/UDP port
I0229 06:00:06.744977       6 controller.go:168] backend reload required
I0229 06:00:06.979204       6 controller.go:177] ingress backend successfully reloaded...
```
