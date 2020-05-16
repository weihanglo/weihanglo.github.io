---
title: "WWW 0x0E: 親愛的，我把快取都放你腦中了"
date: 2020-04-25T00:00:00+08:00
tags:
  - Cache
  - Databases
---

> If you cloud end Covid-19 by sacrificing a JavaScript framework, which one would you choose and why Angular?
>
> — [@dabit3](https://twitter.com/dabit3/status/1251597948472999936?s=20) 2020.4.19

這裡是 WWW 第拾肆期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Apple just killed Offline Web Apps while purporting to protect your privacy: why that’s A Bad Thing and why you should care](https://ar.al/2020/03/25/apple-just-killed-offline-web-apps-while-purporting-to-protect-your-privacy-why-thats-a-bad-thing-and-why-you-should-care/)

標題很聳動但無誤，Apple 決定幫 Safari 給所有 storage 加上一個**「七天沒進站就刪掉」**的限制，不負責任猜測是 app 營收不好。

## [Copyrighting all the melodies to avoid accidental infringement ](https://youtu.be/sJtm0MoOgiU)

[All the Music LLC](http://allthemusic.info) 是一間懷抱夢想的公司，他們將旋律視為有限的數學排列組合，而數學是既有事實，所以沒有著作權，然後再利用程式組合不同音高的音符，每秒產生三十萬不同旋律的 midi，放在 public domain，進而保障音樂創作者不會被來路不明的著作權蟑螂吿到死。

該專案認為，音樂是由旋律、節奏、合聲，音色的要素組合，但在節奏差距不大的情況下，聽起來會像同一個旋律，加上美國著作權有「[實質相似性](https://en.wikipedia.org/wiki/Substantial_similarity#Substantial_similarity_in_copyright_infringement)」的概念，所以目前窮舉 8 個音高 x 12 個音符組合的旋律即可涵蓋大部分的旋律（之後又加上更多小調，以涵蓋更多種類的音樂）。

這個專案我覺得非常有趣，而且是[用 Rust 寫的](https://github.com/allthemusicllc)！不過其實世界上音樂不是只有西方古典音樂的五線譜，印度、中國、日本還有大大小小的部落民族都有各種超越五線譜的音樂，這些著作權要怎麼保障？又要怎樣讓創作者盡情發揮？仍然有難度存在。

> 更多細節可以看專案的 [FAQ](http://allthemusic.info/faqs/)，雖然載入超慢...

## [Why We Started Putting Unpopular Assets in Memory](https://blog.cloudflare.com/why-we-started-putting-unpopular-assets-in-memory/)

![](https://blog-cloudflare-com-assets.storage.googleapis.com/2020/03/pasted-image-0--4--1.png)

> Image from Cloudflare blog

乍聽之下，標題聳動駭人，依然推薦閱讀此文。抽絲剝繭，層層理出技術決策如何從觀察、實驗、可能問題、現實部署情況，到未來展望的脈絡，值得技術撰文者參考。稍加摘要（根本稱不上是摘要）：

### 背景

Cloudflare 的 Cache 放在 SSD，[客製化的超強 SSD](https://blog.cloudflare.com/cloudflares-gen-x-servers-for-an-accelerated-future/)，但仍遭遇一些問題：

- **問題一：** SSD 的 IO 是造成 tail latency 的主因
- **問題二：** 物理 SSD 壞掉替換的維運成本很高（Cloudflare 在兩百座城市的資料中心的運費、人力替換成本）

### 觀察現況

熱點資源已有作業系統 page cache 將之放在 memory：

- Linux LRU 等各種演算法早就針對熱點做讀取快取
- page cache 也會做寫入緩衝（buffer write） 但 Cloudflare 作為 CDN 服務，更新資源次數極少，page cache 沒辦法幫助減少硬碟寫入

非熱點資源似乎可以放進 memory：

- **動機一：** 寫入過多[導致 SSD 壽命驟減](https://www.usenix.org/conference/fast12/reducing-ssd-read-latency-nand-flash-program-and-erase-suspension)，寫入需要對 storage 晶片送 P/E operation ，這個 operation 會阻擋 read ops 
- **動機二：** 很多資源都是一次性再也不會存取第二次
  - **假說：** 減少硬碟寫入可加速硬碟讀取
  - **方法：** 只 cache 第二次存取的資源
  - **結果：** 減少硬碟寫入次數，P75 cache hit duration 也降低，因為不需要 evict 非熱點資源、cache hit ratio 和 retention 也提高了

### 如何實作

**解法一：** 紀錄存取次數，但不要快取

- 用 [bloom filter](https://en.wikipedia.org/wiki/Bloom_filter) 等 memory-efficient 資料結構來儲存存取次數
- 新問題：資源都會 miss 第二次才會被 cache，這對 CDN 供應商或客戶來說都無法接受。

**解法二：** 多一個 transient cache (in memory cache)。

- 先將欲快取到 SSD 的資源放在 memory 中，如果存取它太多次，就 promote 到 SSD 中
- 沒被 promote 的資源最後會被 evict

## 權衡

這聽起來很合理，全部放到 memory 中，但其實需要在 SSD 壽命、cache tail hit latency 和 memory 使用量之間權衡，而這次影響最大的就是 memory 使用量上升：

- **transient cache memory 究竟要多大：** 影響 eviction、cache hit ratio
- **和 page cache 競爭：** page cache 抓熱門資源、但 transient cache 大多為非熱門，有排擠效應
- **和 process memory 競爭：** process 和 page cache 不一樣，對 memory 有剛性需求，而且 edge service 的升級需要 zero downtime，所以會同時有兩個版本的服務（[藍綠佈署 🙃](https://tech.hahow.in/淺談-hahow-藍綠部署-1c99d42336a9)），如果記憶體不夠，就會讓 page cache 減少，反而增加 IO。

有段話透露出 Cloudflare 對於客戶太在乎 miss rate 的抱怨，認為只是在博取「眼球效能」😈

> From a customer's perspective, cache retention being too short is unacceptable because it leads to more misses, commensurate higher cost, and **_worse eyeball performance_**.

## 結果與展望

Cloudlfare 採取在新的機器上部署新的 transient cache，並只在部分 asset 使用，不斷尋找 memory size 的甜蜜點，最後結果為

- 在 SSD 壽命、cache tail hit latency 和 memory 使用量三者間，Cloudflare 選擇前兩者
- 減少 20%-25% SSD 寫入
- CDN tail latency 在高峰期間也減少了 20%

而對未來可以做更好的部分則是：

- **部署更多：** 舊機器退役後，新世代機器（更多 memory 的機器）就會上去
- **更智慧的 promotion 演算法：** 現在僅透過資源觸擊數，未來可依據資源的 TTL 決定是否 promote；另一面向則是 demotion，雖然不會減少硬碟寫入，但可增加 cache hit ratio 和 cache retention
- **用其他儲存裝置做 transient cache：** 選擇 memory 是因為損耗花費低，HDD 同樣耐操，可以考慮混合 SSD、HDD、memory 在費用和效能取得平衡


