---
title: "WWW 0x13: 據說網路釣魚比海釣容易成功"
date: 2020-05-30T00:00:00+08:00
tags:
  - Security
  - Rust
---

這裡是 WWW 第拾玖期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [B!tch to Boss](https://addons.mozilla.org/firefox/addon/b-itch-to-boss/)

![](https://addons.cdn.mozilla.net/user-media/previews/thumbs/233/233279.png?modified=1583433848)

這應該是我看過最有趣的 addons，而且還是 Mozilla 官方出品，儘管無法有效減少 internet troll，至少一直有人叫你老闆就是爽。

Great job, Mozilla!

## 關於 Microsoft 的幾個 Rust 新聞與專案

最近除了 AWS 在找 [Rust SDK](https://www.amazon.jobs/en/jobs/1124901/senior-software-development-engineer-aws-rust-sdk) 和 [lambda](https://www.amazon.jobs/en/jobs/1104420/software-development-engineer-aws-lambda) 的職缺，微軟也不斷在 Rust 有所著墨，簡單介紹兩個專案新聞:

- [Microsoft: Why we used programming language Rust over Go for WebAssembly on Kubernetes app](https://www.zdnet.com/article/microsoft-why-we-used-programming-language-rust-over-go-for-webassembly-on-kubernetes-app/)：微軟最初開源 [Helm](https://helm.sh) 的 [Deis Lab](https://deislabs.io/) 最近嘗試使用 Rust 開發一個 kubelet 叫做 [krustlet](https://github.com/deislabs/krustlet)，專門用來跑 WebAssembly app
- [Microsoft: Our Rust programming language Windows runtime library is now in preview](https://www.zdnet.com/article/microsoft-our-rust-programming-language-windows-runtime-library-is-now-in-preview/)：微軟官方寫了一個 [WinRT 的 Rust library](https://github.com/microsoft/winrt-rs)，正在 preview stage，可以用 Rust 開發 UWP 了，官方技術部落格甚至有[踩地雷的 demo](https://blogs.windows.com/windowsdeveloper/2020/04/30/rust-winrt-public-preview/)！

## [To test its security mid-pandemic, GitLab tried phishing its own work-from-home staff. 1 in 5 fell for it](https://www.theregister.co.uk/2020/05/21/gitlab_phishing_pentest/)

GitLab 對自家員工「釣魚」資安演練，至少 20% 的員工中招填入帳號密碼，但驚人的是這個比例居然還是低於業界平均 30-40%。突然想起我在公司內部 hackathon 期間也做過釣魚郵件的資安演練，買了 slack-info.app 的 domain 並寄送重設密碼信來測試釣魚，四十個人只有一人中招。嗯，勉強及格。

## [The Rule Of 2](https://chromium.googlesource.com/chromium/src/+/master/docs/security/rule-of-2.md)

![](https://i.imgur.com/pT9FgAJ.png)

身為 web developer，經常與資料庫打交道的我們都很熟悉 CAP theorem，但你知道 UHU theorem 嗎？其實沒有這個理論，不過 Chromium 團隊在[最近大廠](https://github.com/microsoft/MSRC-Security-Research/blob/master/papers/2020/Security analysis of memory tagging.pdf)發現 memory safety 是主要的漏洞之一，而攻擊 memory safety 的面向有三個，只要三個都達成，恭喜你來到資安地獄。以下分別介紹三個弱點：

1. 不信任的輸入：memory safety 漏洞主要來源
2. 使用缺乏 memory safety 的語言：C、C++、Assembly 都是 unsafe 語言
3. 高權限：權限是一個相對概念，韌體、OS process、容器沙盒，給錯權限你就知死（tsai-sí）

解法至少有四種方向：

- 降低權限：都放入沙盒中，定義清楚的 IPC（或者用 WebAssembly？）
- 驗證可信任的來源：這裡的例子比較 Chromium-specific，但就是透過官方的 updater 或是直接將 TLS pin 到 Chrmium 裡面
- 正規化：將輸入轉化成一個語法簡單的格式，縮小錯誤不安全的 scope
- 安全的語言：例如先用 Java 寫的 JsonSanitizer 來驗證輸入是否安全，再傳給 C++
