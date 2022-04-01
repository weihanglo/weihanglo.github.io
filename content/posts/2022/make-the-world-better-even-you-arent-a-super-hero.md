---
title: "不必是眾星拱月那個月 也能替世界增添光芒"
date: 2022-04-01T00:00:00+08:00
katex: true
tags:
  - Rust
---

> _謹以此文紀念 [Alex Crichton 從 Cargo Team 退休]_
>
> _Thank you Alex for your hard work making Rust great!_

猶記得，在大學生涯最後一年，我不小心掉進程式設計的兔子洞，深不見底。那時，也是我初次接觸開放原始碼的軟體專案，當時只覺得「**哇，有免費下載的程式碼和軟體耶，我就免費仔**」 ，那時感覺免費軟體就如同谷關的空氣一樣自然，不至於有人會把新鮮空氣包裝起來賣吧？但隨著我一步步掉入開源社群的陷阱，才發現這一切多麼不尋常。注重隱私的 [Firefox 瀏覽器]、[Android 手機作業系統的核心]，到你最常見的 [404 Not Found]，都是奠基在開發原始碼的軟體專案上。會寫程式後才發現，想打造如此複雜的軟體，需要多聰明的開發者，經歷多少月日打磨？而我們卻坐享其成，一毛錢都沒付出，這些人實在是太佛心啦！

想到此處，我對開源貢獻者的敬佩之心油然而生，開始崇拜被社群封為大神的開源領袖們，也癡心妄想自己有天會成為開源界的耀眼新星。於是，每次被面試或面試別人時，我總是述說自己多愛多愛開源，好似早已在開源社群取得什麼重大成就，殊不知，我依舊只是個門外漢，在開源那扇敞開大門前躊躇。其實我也並非厚顏無恥，而是懼怕面對自己平庸無奇的能力，懼怕證實自己不是做開源貢獻的料。沒有人想讓一個智商不到 157 的人~~當他們的市長~~替他們打造賴以為生的軟體工具。

這一切都在我認識 [Rust 程式語言]和它的社群後改變。

![](https://raw.githubusercontent.com/rust-tw/media/master/logos/rust-taiwan-2.png)

<small>_可愛的 Rust Taiwan Logo，感謝 [@MengWeiChen] 的設計_</small>

Rust 是門神奇的程式語言，陡峭的學習曲線、詭異的語法，以及囉嗦的借用檢查，乍看之下不適合程式新手學習，但 Rust 的編譯器卻非常有包容性，不斷教導開發者怎麼寫會更好，讓新手~~按時吃藥~~遵循指示就能學好學滿。圍繞 Rust 形成的技術社群一樣神奇，人人都熱情地回答問題，哪怕提問者只是搞不懂最最基礎的借用規則，因為老手也曾在此翻過跟斗，更懂那種無助徬徨，知道有人適時拉一把對入門來說多麼重要。我從民國 106 年開始每天逛 [r/rust] 偶爾看看[官方使用者論壇]，處處都能感受社群慷慨激昂但有建設性的交流、辯論與回饋，自己雖然沒什麼提問過，卻總能在他人提問下看到熱心人士完整而有條理的論述，並且從中學習成長。不知何時開始產生一種想法：**我想成為其中一員，想回饋給曾經幫助我的社群**。

已不記得我第一個 Rust 相關貢獻是哪個，但仍記得點燃我熱情的那個[小小貢獻][rust-lang/mdBook#1027]。最初只是閱讀 [Rust by Example] 時，發現目錄側欄又臭又長，想要有個可以收合的功能，就順手貢獻個，沒想到後來許多 Rust 官方文件啟用，看到自己貢獻的陽春功能有實際的幫助，那種感動完全無法言喻。爾後，我開始貢獻簡單的錯誤修復和文件更新，像在熱門的 HTTP crate [hyper][hyper-involved] 和 [Redis crate][redis-involved] 持續了幾週少量產出與交流，成就感說大不大，足夠讓我體驗開源貢獻的快樂，也踏出第一步成為開源的一分子。

<img src="./mdbook-expandable.gif" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

之後，我開始對 Rust 組織的官方專案 Cargo 送出了[第一支修復貢獻][rust-lang/cargo#8622]，雖然最後被關掉了，但維護者耐心地和我提及他們提上會議討論，並說明他們的決議，最後，反而是另一個打蛇隨棍上處理 [lockfile 的小小效能改進][rust-lang/cargo#8641]被合併了！那種成就感比應徵上 FAANG 的工作還爽，是一種「我終於有能力回饋社會」的感覺（其實社會不需要你 🙈）。

接下來，我投入更多心力到 cargo 貢獻中，第一個新功能是讓[編譯產物選擇支援 glob 語法][rust-lang/cargo#8752]，看到了自己的貢獻被提 FCP 讓所有成員 sign-off。還有貢獻到一些 Edition2021 的錯誤處理訊息，所以不小心就列在 [2021 感謝狀]裡面。也有一個修復 `--crate-type` 未穩定功能一些小問題，讓整個 [hyper 生態系減少 10-20% 左右的編譯時間][rust-lang/cargo#10388]。雖然這些都不是什麼手寫 red-black tree 或是 state snapshot transfer 等難度很高的貢獻，但要了解一段程式碼的過往歷史、當下權衡，和未來發展，再寫出合適解法，也並非一蹴可幾，依然需要可觀的時間精力和熱情，尤其是對我這種普通人來說，有些時候簡單的功能還是讓我想破頭到凌晨三點。

<img src="./thankyou2021.png" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

<small>_剛好做到 Edition2021 相關的 issue，就被列在感謝名單了_</small>

<img src="./midnight-pr.png" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

<small>_簡單的更動，但為了節省資源配置寫到凌晨兩點半（最後還沒用上 🥲）_</small>

我的程式能力其實很普通，工作上經常跟不上同事的討論，只能會後自己再多看資料；開源貢獻也甚至曾間接導致[整個函式庫不能使用]。但我深信就算貢獻微小，對受到幫助的人來說，都是巨大的不同。於是我開始嘗試[回覆 issue 和審核 pull request]，在我能力範圍之內協助這個專案成長，也讓 Cargo 專案的維護者減輕負擔，能有更多時間從事他們擅長的更 high-level 的設計開發，而不必被一些小修復佔去時間。

在開源貢獻的旅途上，我才發現，開源專案的成功，並不總是需要英雄焚膏繼晷輸出，更重要的是成員之間不斷地溝通協調，耐心傾聽來自社群的意見和回饋，並學習調適自己的身心也尊重他人的立場，還要適時帶領貢獻者改善他們的程式碼又不能幫他釣魚。我很感謝 Cargo team 的成員給我機會獲得這些寶貴的經驗，我從 Cargo team lead [@ehuss] 身上學到很多溝通技巧，如何從沒有根據的說法拔出更多~~獅子的鬃毛~~回報者的資訊；也很感謝 [@alexcrichton] 總是耐住性子在我不成熟的修補中來回溝通；[@joshtriplett] 則總是用一個回覆一語道破點出我的盲點；更要感謝 [@Eh2406] 主動推薦邀請我加入 Cargo 週會，和大家一起讓專案更完善真的很有趣。

其實，我們不需要是超級英雄，也能讓世界更美好；不必是眾星拱月那個月，也能替世界增添光芒。願我們都能在紛亂的世道找到適合自己的位置。

<img src="./add-weihanglo-to-cargo-team.png" style="box-shadow: 0 0 2em rgba(168, 168, 168)">

[Alex Crichton 從 Cargo Team 退休]: https://blog.rust-lang.org/inside-rust/2022/03/31/cargo-team-changes.html
[Firefox 瀏覽器]: https://firefox.com
[Android 手機作業系統的核心]: https://source.android.com/setup/build/rust/building-rust-modules/overview
[404 Not Found]: https://nginx.org/
[Rust 程式語言]: https://www.rust-lang.org/zh-TW/
[@MengWeiChen]: https://github.com/MengWeiChen
[r/rust]: https://www.reddit.com/r/rust/
[官方使用者論壇]: https://users.rust-lang.org/
[Rust by Example]: https://doc.rust-lang.org/rust-by-example/
[hyper-involved]: https://github.com/hyperium/hyper/issues?q=involves%3Aweihanglo
[redis-involved]: https://github.com/mitsuhiko/redis-rs/issues?q=involves%3Aweihanglo
[rust-lang/mdBook#1027]: https://github.com/rust-lang/mdBook/pull/1027
[rust-lang/cargo#8622]: https://github.com/rust-lang/cargo/pull/8622
[rust-lang/cargo#8641]: https://github.com/rust-lang/cargo/pull/8641
[rust-lang/cargo#8752]: https://github.com/rust-lang/cargo/pull/8752
[2021 感謝狀]: https://github.com/rust-lang/rust/issues/88623
[rust-lang/cargo#10388]: https://github.com/rust-lang/cargo/pull/10388#issuecomment-1049725601
[整個函式庫不能使用]: https://twitter.com/weihanglo/status/1427860255715725318
[回覆 issue 和審核 pull request]: https://github.com/rust-lang/cargo/issues?q=involves%3Aweihanglo
[@ehuss]: https://github.com/ehuss/
[@alexcrichton]: https://github.com/alexcrichton/
[@joshtriplett]: https://github.com/joshtriplett
[@Eh2406]: https://github.com/Eh2406
