---
title: "WWW 0x01: 有個部署「部署「部署 K8s 」」的工具"
date: 2020-01-25T00:00:11+08:00
tags:
  - Weekly
  - C++
  - DevOps
  - Kubernetes
  - Front-end
---

這裡是 WWW 第壹期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [How to Adopt Modern C++17 into Your C++ Code : Build 2018](https://youtu.be/UsrHQAzSXkA)

推個 C++ 影片，微軟的大師 Herb Sutter 很精要地講完重要的 modern feature
除了 smart pointer，還包含了

- move semantic
- `string_view`
- `optional`
- `any_cast`/`variant`
- RAII scoped lifetime 心法 => Rust 已經是 NLL 了

## [Tanka：Grafana Lab 部署 k8s 的新工具](https://grafana.com/blog/2020/01/09/introducing-tanka-our-way-of-deploying-to-kubernetes/)

[Tanka](https://tanka.dev/) 是 Grafana Lab 開源的新部署工具，原文短又清楚，但這邊還是再疊床架屋摘要一次

- YAML 不是動態語言，很多邏輯會不斷重複，不好寫
- Helm 很棒，但奠基在 string template 上仍然難寫難維護，彈性不夠高，Chart 維護者沒 export 的欄位你也不能擅自修改
- Helm 其實完全沒有抽象化，就算 `values.yaml` 挖了很多洞，開發者仍然要去看 template 裡面到底做了什麼事

這些的確都是用 Helm 部署的痛點，尤其是低度抽象化，看看精美的 [stable/prometheus-operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator)，就會開始思考 Helm 的定位與其說是 Package manager，倒像只是一堆 yaml 的集合（事實上就是），完全沒有封裝感，更別提 Resource 修改時，很常遇到 Helm 沒辦法正確更新的痛了。

Tanka 用了 Jsonnet 這個小眾動態語言來解決上述問題，並在上面寫了 Tanka 自己用的小小 Jsonnet 函式庫，個人認為雖然看似有解決問題，但同時引進新的概念和語言，依舊是個成本，而且 Helm 目前還有 CNCF 和生態系的加持。

事實上，維運到底要如何封裝、封裝多少，比起應用程式面，更需要關注現有 infra，甚至可以說維運幾乎不可能完美封裝。如果有空閱讀 [Tanka 在 Hacker News 上的討論串](https://news.ycombinator.com/item?id=22011251)，不難發現 Helm 和 Terrafrom，甚至 `kustomize` 都有不同的應用場景，Tanka 想要吃下哪塊市場份額，成為什麼角色，拭目以待吧。

## [Making Instagram.com faster Part 4](https://instagram-engineering.com/making-instagram-com-faster-code-size-and-execution-optimizations-part-4-57668be796a8)

本文描述前端團隊如何讓 Instagram 網站加速，總共分四篇，本篇強調要注重 code size 本身大小（pre-compression），而非壓縮後大小（post-compression），節錄重點如下：

- 就算用了 Brotli 壓縮程式碼，使用者 page load 的時間依然不變，parser 仍要解析你下面那一大包
- 重構 UI 做合理的 code splitting 和動態載入需要的工程資源浩大，是個長期目標
- **Inline require：** 模組在需要時再 require，其實就是 lazy initialization，IG 用 [Metro 這個 bundler](https://facebook.github.io/metro/) 達成此事
- **根據不同瀏覽器版本給予不同的 bundle：** 新瀏覽器給 ES2017，舊的給 ES5。IG 用了 server-side user-agent 來判斷要給 client 載入什麼資源。這個作法可以同時減少 pre-/post-compression size
