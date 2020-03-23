---
title: "Kuberenetes Autoscaling 相關知識小整理"
date: 2020-03-23T00:00:00+08:00
tags:
  - Kubernetes
  - DevOps
---

K8s 有好用的 autoscaling 功能，但你知道除了 pod 之外，node 也可以 auto scaling 嗎？帥，你知道就不用分享了啊 🚬

本文以重點整理的方式，先介紹目前常見的 Autoscaler，再介紹一些防止 pod 被亂殺的 config。

_（撰於 2020-03-23，基於 Kubernetes 1.17，但 Api Versions 太多請自行查閱手冊）_

<!-- more -->

讓我們歡迎第一位 Autoscaler 出場！

## [Cluster Autoscaler（CA）](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)

負責調整 node-pool 的 node size scaling，屬於 cluster level autoscaler。

> 白話文：開新機器，關沒路用的機器 😈

- [**Scale-up：**](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-scale-up-work) 有 pod 的狀態是 `unschedulable` 時
- [**Scale-down：**](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-scale-down-work) 觀察 pod 總共的 memory/CPU request 是否 < 50%（非真實的 resource utilization）+ 沒有其他 pod/node 的條件限制
- 可設定 min/maxi poolsize（GKE），自己管理的叢集可以[設定更多參數](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca)
- 會參照 PriorityClass 來調控 pod，但就是僅僅設立一條~~貧窮~~截止線，當前是 `-10` ，autoscaler 不會因為低於此線的 pod 而去 scale-up，需要 scale-down 也不會理會 node 裡面是否有這種 pod
- 部分設定設不好會讓 CA 沒辦法 scaling
  - CA 要關 node 然後 evict pod 時違反 pod affinity/anti-affinity 和 PodDisruptionBudget
  - 在 node 加上 annotation 可防止被 scale down：`"cluster-autoscaler.kubernetes.io/scale-down-disabled": "true"`
- 理論上 CA 很快，預設發現 `unschedulable` 10 秒就 scale-up，瓶頸會在 Node provision（開機器）需要數分鐘
- ⚠️ GKE 若要 enable CA，會讓 K8s master 暫停重開，不可不謹慎
- ⚠️ 手動更改 autoscalable node-pool 的 node label 等欄位會掉，因為修改不會傳播到 node template

## [Horizontal Pod Autoscaler（HPA）](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

管理 pod 數量的 autoscaler，屬於 pod level，同時也是一種 K8s API resource。

> 白話文：自動增減 replica 數量

- **Scale-up：** 檢查 metrics，發現過了 threshold 就增加 deployment 的 replicas
- **Scale-down：** 檢查 metrics，發現過了 threshold 就減少 deployment 的 replicas
- 在 scale up/down 之後都會等個三五分鐘穩定後，再開始檢查 metric（如果突然爆漲應該來不及？）
- 可以設定 external metrics 來觸發 autoscaling
- ⚠️ v2beta2 以上的 HPA 才有 metrics 可以檢查，v1 只能檢查 CPU utilization

![](https://d33wubrfki0l68.cloudfront.net/4fe1ef7265a93f5f564bd3fbb0269ebd10b73b4e/1775d/images/docs/horizontal-pod-autoscaler.svg)

目前 `hpa.spec` 有以下的 fields：

- `maxReplicas`：恩，字面上的意思
- `minReplicas`：autoscaler 可以設定的最小 replicas 值，預設為 1
- `scaleTargetRef`：要 scale 的 resource，通常設定為 deployment 等 scheduler（statefulset 不行）
- `metrics`：設定 scaling 要檢查的 metrics，有點複雜，可以設定
  1. **Resource：** 目標資源的 Memory/CPU 等
  2. **Object：** 例如 Ingress hit-per-seconds
  3. **Pod：** pod 內部的 metrics，和 Resource 不同在於 memory 是 K8s controller 可見，Pod 內部是 Pod 自己可見
  4. **External：** 外部的 metrics，例如 load balancer，K8s 的 metrics 使用 Prometheus 格式，所以大膽向外求援吧

如果想玩玩 HPA，請參考[官方文件走過一遍](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough)，但千萬不要在正式環境亂玩 😈。

> 去看了 Kuberentes 現在有什麼 stable metrics，得到以下答案，帥

![](https://media2.giphy.com/media/cKmfTuhx0kyu1e6BkL/giphy.gif)

## [Vertical Pod Autoscaler（VPA）](https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/pkg/apis/autoscaling.k8s.io/v1beta2/types.go)

自動推薦並設定最適合 deployment pod 的 resource requests/limits 設定（最低資源需求和可用資源上限），不需要再 runtime 監控透過人工調整到正確的 CPU/Memory。

> 白話文：是一個能解放你的生產力的推薦系統啦

- **Scale-up：** 檢查 metrics，發現過了 threshold 就減少 deployment 的 pod template 的 resources.requests，再透過重啟 pod 實際更新
- **Scale-down：** 檢查 metrics，發現過了 threshold 就減少 deployment 的 pod template 的 resources.requests，再透過重啟 pod 實際更新
- 是一個 CRD（[Custom Resource Definition object](https://kubernetes.io/docs/concepts/api-extension/custom-resources/)）
- VPA 不會更動 `resources.limit`，事實上，在當前 MVP [是將 limit 設定為 infinity](https://github.com/kubernetes/community/blob/a358faf/contributors/design-proposals/autoscaling/vertical-pod-autoscaler.md#recommendation-model)
- VPA 的改動會參考該 pod 的 historic data（嗯，很有自學能力）
- GKE 可以一鍵啟用，但是 API version 改變也要透過 google cloud
- ⚠️ VPA 目前不該跟 HPA 一起用（VPA 0.7.1），除非 [HPA 用了 custom metric 來觸發](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-custom-metrics)
- ⚠️ 對，你發現了一定要重啟 pod 才會更新，這是當前 VPA 的限制，如果受不鳥就暫時先別用吧
- ⚠️ 目前和 JVM 有點不搭，因為 JVM 隱匿病情不公開透明

目前 `vpa.spec` 有以下幾個 fields：

- `targetRef`： 要調整的 resource，通常設定為 deployment 等 scheduler（statefulset 不行）
- `updatePolicy`：會如何調節 Pod，總共有三種模式，但其實你實際只會用到 Recreate
  - `Off`：關，可用來 dry-run
  - `Initial`： 只會在 pod creation 是指派資源，之後整個生命週期都沒 autoscaler 的事
  - `Recreate`： 會透過 delete/recreate 來調節 pod 整個生命週期的 resources
  - `Auto`：自動用任何 updatePolicy 來做事，目前等於 `Recreate`
- `resourcePolicy.containerPolicies`：  決定 autoscaler 如何對特定 container 計算資源用量，是一個 array of struct，有幾個 field
  - `containerName`：想對哪個 container 開刀
  - `mode`：有 `Auto` 或 `Off` 來決定是否對該 container autoscale
  - `minAllowed`：推薦資源用量的最低限度
  - `maxAllowed`：推薦資源用量的最高限度

因為文件更新太慢，建議直接看 [VPA 的 source code](https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/pkg/apis/autoscaling.k8s.io/v1beta2/types.go) 來看到底怎麼用，或是看 [Google 的文件](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler)，此外 GKE 可以一鍵開啟 VPA，beta 版的功能公開出來還不加 beta tag，膽大包青天。

當然，如果你對實作細節和如何推薦很有興趣的話，也可以看最初的 [design proposal](https://github.com/kubernetes/community/blob/a358faf/contributors/design-proposals/autoscaling/vertical-pod-autoscaler.md)。

![](https://i.imgur.com/Nr68ZyD.png)

## 如何讓該死的 Pod 死掉，不該死的 Pod 晚點死

以上是 Autoscaler 的介紹，但無論 scale pod 或 node，都可能殺掉部分的 pod，為了保持網路穩定，或是某些服務需要定量的 replica set 存活（例如用到 raft 共識演算法的服務），我們需要一些設定，讓 pod 不會長在不該長的 node，也不會死得不明不白。

### Pod Resources Rquests and Limits

 K8s 決定 Pod 放在哪，有一個要點：**哪個 Node 的資源夠就往哪放**。嘟嘟好，`pod.spec` 可以設定 container 需要多少運算資源（CPU、Memory 等）：

- `containers[].resources.requests`：就是 **minimum**，該容器「至少需要多少資源」
- `containers[].resources.limits`：就是 **maximum**，該 容器「至多可使用多少資源」

Scheduler 會按照 `resources.requests` 決定 pod 要放在哪，一個 node 上面所有 pod containers 的 requests 總和不能超過該 node 提供的運算資源總量，否則新 Pod 會放不上去該 node。

那想知道 `limits` 怎麼計算的嗎？你不想知道但我還是要說：不同的 container runtime 統計運算資源使用量的方式各異，以最常見的 Docker 來說，CPU 用量是「每 100ms 該 container 佔用多少 CPU time」來決定，而 Memory 用量則是用 [`docker run` 的 `--memory`](https://docs.docker.com/engine/reference/run/#runtime-constraints-on-resources) 來限制，詳情請[參閱官方手冊](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)。

這裡偷一下 Sysdig 的圖，視覺化來理解 resources requests：

![](https://478h5m1yrfsa3bbe262u7muv-wpengine.netdna-ssl.com/wp-content/uploads/image11.png)

*image from Sysdig: [Understanding Kubernetes limits and requests by example](https://sysdig.com/blog/kubernetes-limits-requests/)*

總而言之，在 Pod 要被 schedule 到 node，都會參考這些設定來調控，Cluster Autoscaler 也不例外，如果發現 Autoscaler 運作不能，檢查一下這些設定，然後記得 **requests = 下限**，**limit = 上限**準沒錯。

> 要限制運算資源使用，還有 [`ResourceQuota`](https://kubernetes.io/docs/concepts/policy/resource-quotas/)（限制 namespace 資源使用）和  [`LimitRange`](https://kubernetes.io/docs/concepts/policy/limit-range/)（）這兩個 API Resources 可用，甚至可以管理  storage，但設定有些複雜，按下不表。
>
> 然後 [GKE 會幫你亂加 ResourceQuota](https://cloud.google.com/kubernetes-engine/quotas)，Google 髒髒。

### Pod Disruption Budget（PDB）

PDB 字面上意思是「Pod 的崩潰預算」，說穿了，就是設定Pod 遇到**事故**時**至少要活幾個**和**至多能死幾個**。
還有機房封城 SRE 進不去重開
我們先來定義「事故」。舉凡系統當機、機房斷電、海底電纜被鯊魚咬，或是封城 SRE 無法進去重開機，這些可能會造成機器損毀的事故都是一種 disruption，但這些是「非自願性事故」。當然，K8s 管理員想要 scale down 一個 node 來維護或是省錢也是一種事故，這種就是「自願性事故」，PDB 就是為了防止管理員那天晚上喝了太多酒不小心一次 drain 太多 node 的**最後一道安全鎖**。

 PDB 有下列幾個 fields：

- `maxUnavailable`：恩，剛剛講過，最多能死幾個 pod
- `minAvailable`：至少要有幾個存活
- `selector`：這個你不知道自己 `kubectl explain pdb.spec.selector` 吧 💩

講起來 PDB 很簡單，但其實它非常實用，必須細細品嚐，例如你有個用了 distributed service，由於這種用了共識演算法的服務 qurorum 都需要有一定數量（例如 3），所以你可能選擇對 StatefulSet 的 pod 設定 `minAvailable: 3`；或是你發現你根本不能死任何一個服務，也可以直接設定 `maxUnavailable: 0`，這樣 K8s 管理員發現沒辦法 drain node 的時候就會來找你，你就可以好好規劃手動調整，一起 DevOps 惹。

### Pod Affinity/Anti-Affinity

Affinity，親和性，如 water affinity 是親水性，Pod affinity 代表「Pod 會趨於被安置在哪一個 node」，anti-affinity 則反之。

Pod 可以設定兩種 affinity：Node Affinity 和 Pod Affinity。

- **Node Affinity：** 透過各種 expression（or、and、in 等）選擇不同的 node 來安置 pod，實際上就是強化版的 node selector，但可以設定各種「required」或「preferred」屬性決定條件是否必須。
- **Pod Affinity：** 這是跨 pod 的 affinity，設定上和 Node Affinity 類似，換句話說就是：這個 pod A 已經在這個 Node 上面跑了，所以 pod B 根據 podAffinity 的設定也要（或不要）在這個 node 上面跑。

由於 Pod Affinity 還有一個 `topologyKey` 可以指定 Node label，讓 affinity 限制在有同一個 label 的 node 上面運作，這個 `topologyKey` 因為實作上安全性和效能考量，有諸多限制，請詳閱[公開說明書](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)。

> - ⚠️ 目前實作上，配合 CA 使用可能[造成 CA 慢三個數量級](https://github.com/kubernetes/autoscaler/blob/2933517/cluster-autoscaler/FAQ.md#what-are-the-service-level-objectives-for-cluster-autoscaler)，且設定不好可能無法 scale down，請注意
> - 其實還有和 affinity 相反的 [taint/toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)，會確認 Pod 不在特定的 Node 上安置，有機會再談

### Pod Priority and Preemption

人有貧富貴賤，~~而 SRE 最賤~~，Pod 當然也不例外，我們可以透過 PriorityClass 這個 API resource，讓一些 Pod 就是比其他 Pod 還高貴（或低賤）。

當設定 `pod.spec.priorityClassName` 後，這個 pod 就獲得階級身分，如果遇上了有些 pod 沒辦法 schedule 到 node 上，priorityClass 較低的 pod 就會被迫踢出 node，讓高級的 pod 先 schedule，就是這麼現實。

- PriorityClass 和 StorageClass 一樣，是 non-namspaced 的資源
- `priorityclass.value`：是一個 integer，越高越優先
- `priorityclass.preemptionPolicy`：是否能夠擠掉現有的 pod
  - `Never`：只能搶排隊在 Pending 但還沒 schedule 的 pod 前面先被安置
  - `PreemptLowerPriority`：比較兇，會嘗試幹掉已經 scheduled 的低順位 pod
- [`NonPreemptingPriority` feature gate](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) 在 1.15 截止 1.17 都還在 Alpha，預設 `false`
- 和 [QoS](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/node/resource-qos.md)（由 pod resources.requests/limits 組合出來）是正交關係，互相影響程度低
- ⚠️ PriorityClass 對 PDB 的支援是「盡其所能」，也就是說在需要 evict pod 時，會盡力去找可能符合 PDB 的受害者，但如果沒找到，低順位的 pod 還是會被幹掉

> 事實上 k8s 有預設兩個 PriorityClass，專門給 K8s 核心元件，原則上不要任意動到[這些 PriorityClass](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#interactions-of-pod-priority-and-qos)，也不要搶他們的資源。

## 小結

感謝您耐心看完這篇冗文，來總複習一下：

1. Cluster Autoscaler 控制增減 node 機器，舒服
2. Horizontal Pod Autoscaler 控制 deployment 的 replicas 數量，舒服
3. Verticla Pod Autoscaler 控制 deployment 的 resource requests/limit 數，舒服
4. 儘量設定 Pod resources requests 與 limit，但這代表要熟悉 app 使用資源多寡，除非用 VPA
5. Pod Disruption Budget 是你最後一道鎖，務必設定
6. 若服務需要強 HA（跨 region/zone、或跨不同實體機房），請設定 (anti-)affinity
7. 如果你有些 app 高人一等，非常非常重要，重要到可以把別人的 pod 幹掉，請設定 PriorityClass

切記，若要測試 autoscaling，千萬注意當前在哪個 cluster context，別說我沒提醒，小心弄壞了正式環境的 Kubernetes cluster 😈。

## References

- [K8s Doc - Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [K8s Doc - Manage Compute Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)
- [K8s Doc - Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [K8s Doc - Assign Pods to Nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
- [K8s Doc - Pod Priority and Preemption](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption)
- [GitHub - Cluster Autoscaler FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)
- [GitHub - Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [GKE - Cluster autoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler)
- [GKE - Vertical Pod Autoscaler](https://cloud.google.com/kubernetes-engine/docs/concepts/verticalpodautoscaler)
