---
title: "WWW 0x0D: 已達上限"
date: 2020-04-18T00:00:00+08:00
tags:
  - Cryptography
  - Kubernetes
  - Privacy
---

> 欸，工時系統禁止報加班！？
>
> — Weihang Lo 2020.4

這裡是 WWW 第十三期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [The Facts: Mozilla’s DNS over HTTPs (DoH)](https://blog.mozilla.org/netpolicy/2020/02/25/the-facts-mozillas-dns-over-https-doh/)

![](https://i.imgur.com/LgNKRtn.png)

西元二零二零年二月二十五日起，Firefox 預設開啟了 DNS over HTTPS（DoH）的功能，這會導致：

- 原本裸奔的 DNS query 可以透過 HTTPS 加密，不會再被看光光
- DNS 隱私資料從被 ISP 幹走變成被 Cloudflare/NextDNS 或其他 DoH 供應商幹走
- 因為不會走你家的 internal DNS service，有些解析會壞掉 👋
- 你不會再看見色情守門員

DoH 算是一個容易起爭議的功能，例如：

- Firefox DoH 預設是 Cloudflare 讓 OpenBSD 的 Firefox 版預設直接關閉 DoH
- Chrome 的行為則是如果 DNS provider 有支援 DoH 才自動開啟，爭議點在很多人都用 8.8.8.8 那還不是一定會走 Google 的 DoH
- 英國 ISP 商們票選 Mozilla 為 [2019 年度網路惡棍](https://www.ispa.org.uk/ispa-announces-finalists-for-2019-internet-heroes-and-villains-trump-and-mozilla-lead-the-way-as-villain-nominees/)，因為「DoH 阻撓網路監管，網路會成犯罪溫床」，帥
- DoH 造成 DNS server 從集中在 ISP 變成集中在大型 DoH 網路公司

還是可以理解一下為什麼 Firefox 要預設 DoH，至於是否開啟就看個人囉。

## [No More Crypto Fails 現代密碼學入門](https://speakerdeck.com/inndy/no-more-crypto-fails)

非常簡明的密碼學入門，沒有提到太多數學理論，花個十五分鐘閱讀，然後再花十五分鐘 google，搞懂不熟的知識點吧！

> 順便推薦個 Stanford 大學 Dan Boneh 的[密碼學課程](https://www.coursera.org/learn/crypto)

## [DNS Lookups in Kubernetes](https://mrkaran.dev/posts/ndots-kubernetes/)

你以為 Kubernetes 的 DNS 解析只是 $service.$namespace.svc.cluster.local 嗎？其實 pod 的 DNS 解析一樣會看 [`/etc/resolv.conf`](http://man7.org/linux/man-pages/man5/resolv.conf.5.html) 檔案，而且會做以下設定：

- `nameserver`：指向 CoreDNS 服務 IP
- `search`：欲解析的 domain 不是 FQDN 時，這個 search list 的 domain 會被當作 root domain，K8s 預設會加入 `$namespace.svc.$zone`、`svc.$zone`、`$zone` 三個 domain
- `options ndots:5`：表示只有 domain 有超過五個 `.` 時，才會被當作 FQDN，否則則是 prepend 到 `search` list 的 root domain來搜尋

綜合上述，如果我的服務叫做 `my-service`，DNS resolution 的順序可能會是：

1. ndots < 5，不是 FQDN，不當作 FQDN 解析，嘗試 prepend 到 search list
2. 我的 namespace 叫 `my-ns`，則嘗試解析 `my-service.my-ns.svc.cluster.local.`
3. 若解析失敗，則嘗試解析 `my-service.svc.cluster.local.`
4. 若解析失敗，則嘗試解析 `my-service.cluster.local.`
5. 最後才會把 `my-service.` 當作 FQDN 來解析

Kubernetes 官方也有對這個 [`ndots:5` 的設計做出解釋](https://github.com/kubernetes/kubernetes/issues/33554#issuecomment-266251056)（但現在換成 CoreDNS 了？），是為了要同時支援解析 same-namespace、cross-namespace 還有 SRV record（`_$port._$proto` 的格式，講到這個就想到 external-dns 一直不 review 我的 SRV 相關 PR 🤯）。雖然有人說 [`ndots:5` 有效能隱憂](https://pracucci.com/kubernetes-dns-resolution-ndots-options-and-why-it-may-affect-application-performances.html)，但 DNS 照理說應該會被 cache 起來？總之，如果不是需要 low latency 的服務，使用 Kubernetes 預設值應該不會錯。
