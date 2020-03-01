---
title: "WWW 0x08: 你的 Helm chart 安全嗎"
date: 2020-03-14T00:00:00+08:00
tags:
  - Weekly
  - FOSS
  - Kubernetes
---

> organizations which design systems are constrained to produce designs which are copies of the communication structures of these organizations.
>
> -- M. Conway

這裡是 WWW 第捌期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [My FOSS Story](https://blog.burntsushi.net/foss/#other-thoughts-on-entitlement)

這篇文章是 Rust 社群非常有名的 Andrew Gallant ([@burntsushi](https://github.com/burntsushi)) 所撰，講述了他自身與 FOSS 的糾葛。文章裡面許多篇幅在描述 FOSS 中的負面事情，不過這也是開源社群較少提及和處理的一塊。這篇文章也可以視為是 burntsushi 針對最近 Rust 社群最大的 web framework [Actix 的作者退出開源界](https://github.com/actix/actix-web/issues/1289)的有感而發。節錄一些我覺得可以帶著走的實用想法：

- 設立界線：開源即政治，網路上就是有一堆酸民，就算沒有，也有太多太多 issue 和 PR 壓得我們喘不過氣，把開源工作和個人生活切割開來，設立界線和停損點，自己的活自己安排。
- 遵循「比例原則」：如果提出一個問題卻僅寥寥幾行，就用寥寥幾行回覆吧。
- 問題重現：良好的問題回報能搭配簡單重現方式最棒，如果沒辦法，那就帶著作者一起 debug 吧！

作者最後雖然表列許多負面行為，但也說了 FOSS 仍然有許多有趣的經驗和美好。信任為開源之本，希望這篇文章能帶給 FOSS 界打滾的我們更多啟發。

## [Uncharted territory – discovering vulnerabilities in public Helm Charts](https://snyk.io/blog/uncharted-territory-discovering-vulnerabilities-in-public-helm-charts/)

**⚠️⚠️⚠️ 你的 Helm chart 安全嗎 ⚠️⚠️⚠️**

專門做各大語言的開源套件安全性檢驗的 [Snyk](https://snyk.io)，除了檢驗原有的 npm、PyPI 等套件，最近開始檢驗起 Helm 官方的 stable charts 中每個 image 是否有安全性漏洞，並出一份[安全性報告](https://snyk.io/wp-content/uploads/helm-report.pdf)。報告指出：

- 277 個 stable chart 中，68% 有高度安全性漏洞，但 64% 可以透過升級 image 來解決漏洞
- 最常見的風險有：out-of-bounds reads/writes、access restriction bypass、NULL pointer dereference（一和三 Rust 完美解決）
- [`dduportal/bats:0.4.0`](https://hub.docker.com/r/dduportal/bats) 是最常用的 image，也擁有最多漏洞。`postgres:9.6.2` 第二。`unguiculus/docker-python3-phantomjs-selenium:v1` 第三。

此外，Snyk 同時開源了[一支方便檢查 Helm chart image 安全性的 Helm plugin](https://github.com/snyk-labs/helm-snyk)，非常方便，~~除了需要註冊 Snyk 帳號順便竊取電子郵件之外~~。

## [Architecting Kubernetes clusters — how many should you have?](https://learnk8s.io/how-many-clusters)

![](https://learnk8s.io/a/6f3a82b403f001b6862a27ee3e41879b.svg)

本篇文章說明不同數量的 cluster 規劃之應用場景與優劣勢，文內附有許多連結，值得延伸閱讀。

- [單一大型共用 cluster](https://learnk8s.io/how-many-clusters#1-one-large-shared-cluster)：所有不同環境的 app 都在同一個 cluster
  - ✅ 資源利用率高
  - ✅ 便宜
  - ✅ 管理容易：CI/CD 流程、升級 k8s
  - 👎 單點故障機率高：k8s 升級失敗、clsuter-wide 元件壞掉
  - 👎 安全性較差：物理隔離程度低，可以透過 [PodSecurityPolicy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) 處理，但並非易事
  - 👎 無物理資源隔離：資源隔離只能透過 [resource request limit](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)、[ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/) 處理，同樣不好設定
  - 👎 多使用者：較不安全，須通過 [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 額外設定
  - 👎 Cluster 不能無限制增長：node 和 pod 還有 container 在 cluster 中都有一個理論上限值，需注意。
- [多個小型單一用途 cluster](https://learnk8s.io/how-many-clusters#2-many-small-single-use-clusters)：不同環境，不同 app 都各自獨立一個 cluster
  - ✅ 縮小爆破半徑：一個 cluster 掛了就是一個特定環境的 app 掛了而已
  - ✅ 獨立隔離：每個工作負載（workload）都是獨立的環境、OS、CPU、memory
  - ✅ 較少使用者：更容易管理 cluster 的 access control
  - 👎 資源利用率低
  - 👎 比較貴：data plane 和 control plane 都增加了
  - 👎 複雜的跨 cluster 權限管理
- [一個 app 一個 cluster](https://learnk8s.io/how-many-clusters#3-cluster-per-application)：每個 app 的不同環境（開發、正式、測試）都放在同一個 cluster
  - ✅ cluster 可以為 app 量身打造（e.g. MongodDB 就可以用 zfs 的 node）
  - 👎 不同環境在同一個 cluster：測試或開發環境如果有 bug，可能會導致正式環境崩壞
- [一個環境一個 cluster](https://learnk8s.io/how-many-clusters#4-cluster-per-environment)：按照測試、開發、正式等環境建立不同的 cluster
  - ✅ 隔離「正式」環境（不必解釋）
  - ✅ 最小化正式環境的 access control：除了 CI/CD，原則上沒有人需要進入正式環境
  - 👎 APP 之間沒有隔離
  - 👎 環境沒有針對不同需求最佳化：例如有需要 GPU 的 app，那就每個環境都需要裝一個 GPU node

我個人看完的結論是

1. 先學好各種 resource request limit 和 RBAC
2. 把 service mesh、service discovery、API gateway 這些基礎設施搞好，讓 inter-cluster 溝通無障礙
3. 從 Cluster per environment 開始搞起，有需求再特化出 app-specific cluster
4. 永遠記得 [Conway's law](https://en.wikipedia.org/wiki/Conway%27s_law)
