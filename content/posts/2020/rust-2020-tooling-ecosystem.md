---
title: "我眼中的 Rust 2020：生態工具發展"
date: 2020-11-01T08:00:00+08:00
katex: true
tags:
  - Rust
---

最近越來越多人想要學 Rust，也有一些朋友來諮詢 Rust 相關的生態，這裡稍微囉嗦一下我眼中的 Rust 2020 吧。

如果沒有拖稿的話，文章應該會分三篇，表列如下：

- [Rust 生態工具發展](../rust-2020-tooling-ecosystem)
  - [有多少函式庫，都在發展什麼輪子](#有多少函式庫都在發展什麼輪子)
  - [IDE 和 Debugger、測試和開發工具支援程度](#ide-和-debugger測試和開發工具支援程度)
  - [Cross-Compilation、Distribution 工具支援程度](#cross-compilationdistribution-工具支援程度)
  - [與其他語言的 Interpolation](#與其他語言的-interpolation)
  - [穩定性與 Compatibility](#穩定性與-compatibility)
- Rust 業界採用情形
  - 大型公司如 FAANG、RedHat、Dropbox、Mozilla 等如何採用
  - Cloudflare、Fastly 等 CDN 服務商對 Rust 的適用
  - 區塊鏈、高頻交易、加密貨幣領域的公司
  - 嵌入式系統、遊戲界與其他領域
- Rust 開源社群
  - Rust 團隊開放分工的作法
  - 工作組專案組的籌備
  - 核心團隊對 Rust 語言的展望和規劃
  - 研討會 Meetup 和線上討論的風氣與聚集地
  - 台灣、華文圈的 Rust 生態

本篇將會介紹 **「Rust 生態工具發展」**。

> 註零：本文會有大量連結，歡迎點進去。
>
> 註一：本文是於 2020-09-19 和朋友討論的文字整理，所以會和「好讀文章」有點差距，請見諒。
>
> 註二：本文和 Rust 官方的 [Call for blogs 2020](https://blog.rust-lang.org/2019/10/29/A-call-for-blogs-2020.html) 無關，主要是回顧 2020 這年 Rust 在我眼中如何存在。

## 與其他語言的 Interpolation

我先從「與其他語言的 Interpolation」來說：

Rust 其實一開始的定位就是 system programming language，沒有 GC，沒有 runtime（或 minimal runtime），所以跟 C 溝通非常容易，社群也有很多工具可以[自動產生 header 給 C call](https://github.com/eqrion/cbindgen) 或是從 [C lib 建立給 Rust 用的 FFI](https://github.com/rust-lang/rust-bindgen) 的工具，很多社群選擇用 Rust 包裹一層 C code 就是因為 Rust 相對有許多安全檢查（預設 [move semantic](https://rust-lang.tw/book-tw/ch04-00-understanding-ownership.html) + [object lifetime](https://rust-lang.tw/book-tw/ch10-03-lifetime-syntax.html) 檢查），讓 C 的 library 可稍微 robust 一點，至少 caller 這端不用自己 free 有 boundary check 不會 buffer overflow。

對 C++ 來說也是一樣，有[生成 binding 的工具](https://github.com/dtolnay/cxx)，最近 Google 實驗在 [Chromium 導入 Rust](https://www.chromium.org/Home/chromium-security/memory-safety/rust-and-c-interoperability)，所以開發了[自動生成 binding 的工具](https://github.com/google/autocxx)，雖然 Rust 和 C++ 有諸多雷同之處（[Rust for C++ programmers](https://github.com/nrc/r4cppp) 參考手冊），但因為 C++ 過於複雜，所以 binding 工具有些爭議（有人怕會錯）。

其他 GC 類語言的 binding 像 [Python binding](https://github.com/PyO3/pyo3)、[Ruby binding](https://github.com/danielpclark/rutie)、[Node.js binding](https://neon-bindings.com/)（[N-API binding](https://github.com/napi-rs/napi-rs)）、 Java  [JNI binding](https://github.com/jni-rs/jni-rs) and [another](https://github.com/astonbitecode/j4rs) 都在蓬勃發展，我知道前四個都用用在大公司正式環境，尤其是 Python binding 看起來做得很好，基本上串接其他語言不會很痛。

另外，敝司之前為了降低 sha256 hash 過慢，曾經用另一個快速的 cryptographic hash [BLAKE3](https://github.com/BLAKE3-team/BLAKE3) 就是用 Rust 寫然後 Node.js  binding 的 node module。

## 有多少函式庫，都在發展什麼輪子

再來是「有多少函式庫，都在發展什麼輪子」。

Rust 的函式庫走的是中心化 npm 風格，叫做 [crates.io](http://crates.io/)，上面充滿各式各樣有用和無用的函式庫，不過基本上你想做的東西一切都有，例如：

- **Event loop、async runtime：** 這塊目前算很成熟，官方語法只定義了 future 的介面，其他 runtime reactor task 都讓社群實作，所以出現有 libuv 等級的 [tokio](https://tokio.rs)，第二大的 [async-std](https://async.rs/)，也有半官方工具包 [futures](https://github.com/rust-lang/futures-rs/)，我自己覺得比 Python async 更成熟（感覺啦）
- **Concurrency tools：** 這塊非常多，有 parallism 和 channel 之類的工具，例如 [rayon](https://github.com/rayon-rs/rayon) 的目標就是 data parallism，而 [crossbeam](https://github.com/crossbeam-rs/crossbeam) 則是 std 的 concurrency 強化版。
- **Web framework：** 有點像 Python 一樣多頭馬車，[actix](https://actix.rs/)、[rocket](https://rocket.rs/)、[warp
(https://github.com/seanmonstar/warp) 這三個自己比較推薦，但都沒有 Django 和 Rails 這麼功能豐富而肥大，比較像 falcon 那樣簡單精巧。
HTTP/gRPC：[hyper](https://hyper.rs/) 基本上是 de-facto HTTP lib，我貢獻過一些，品質不錯，最近 [cURL 的作者想要底層可以抽換 hyper 這樣](https://www.abetterinternet.org/post/memory-safe-curl/)；gPRC 大概有三家 [tonic](https://github.com/hyperium/tonic/)、[tarpc](https://github.com/google/tarpc)（Google 內部使用）、和 [grpc-rs](https://github.com/tikv/grpc-rs)（TiDB 使用），tonic 的 benchmark 印象中和 Google 自己的 gRPC C library 比起來成績平分秋色。
- 搜尋引擎：搜尋引擎和 web framework 一樣不少選項，有最近拿到融資的開源版 Algolia [MeiliSearch](https://www.meilisearch.com/)，Elasticsearch 替代方案的 [Sonic](https://github.com/valeriansaliou/sonic)、[Toshi](https://github.com/toshi-search/Toshi)，有加上 Raft 搜尋引擎 [Bayard](https://github.com/bayard-search/bayard)，還有作為 Lucene 潛在對手的 [Tantivy](https://github.com/tantivy-search/tantivy)。
- **遊戲引擎：** Rust 就是在蠶食鯨吞 C++ 的疆域，所以有許多優秀的 engine，上次分享過的 [bevy](https://bevyengine.org/)、看起來很強的 [Amethyst](https://amethyst.rs/)，還有 [Piston](https://www.piston.rs/)，不過 game engine 的市場大多被 Unreal 和 Unity 吃下來，所以自研引擎和遊戲目前都是小眾（但「戰神」系列的 CTO 之前說新遊戲要改用 Rust 做不知道現在怎樣了）。
- **物理引擎：** 講完遊戲就要講它底層的物理引擎，最知名的應該是 [rapier](https://rapier.rs/)（[nphysics](https://nphysics.org/) 繼任者），當然物理引擎少不了 [algebra library](https://nalgebra.org/)（還有其他小的但我忘了）
- **parser 和程式語言：** parser 不少，例如 peg parser 的 [pest](https://pest.rs/)，或是另一個 [nom](https://github.com/Geal/nom) parser 和 haskell parsec inspired 的 [combine](https://github.com/Marwes/combine)。用 Rust 寫出來的程式語言更多，我這邊懶得列 XDDD
- **serialize/deserialize：** 基本上這塊被 [serde](https://github.com/serde-rs/serde) 一統江湖（python 超快 [orjson](https://github.com/ijl/orjson/) 就是 serde binding），支援的格式很多，和 haskell 很像，只要在 struct 上面加 annotation 就會自動產生序列化反序列化的實作。而像是 Google 的 [flatbuffer 也有 Rust 支援](https://github.com/google/flatbuffers/tree/master/rust)。
- **Graphics：** 基本上 [gfx-rs](https://github.com/gfx-rs) 整個 org 都在做 vulkan metal 還是什麼顯卡 render pipeline 的串接，剩下還有一些小的 [lyon](https://github.com/nical/lyon) 像，Embark Studio 也在嘗試把 Rust 作為 [GPU 界一等公民語言](https://github.com/EmbarkStudios/rust-gpu)。
- **GUI library：** 不免俗 [GTK 有 binding](https://gtk-rs.org/)（GNOME 官方），然後最新版的 GNOME 已經有 built-in app 是用 Rust 寫的。剩下還有什麼 [azul](https://azul.rs/) 啊 [druid](https://github.com/linebender/druid) 等很多，不過都沒有 Qt 成熟，也不像 Electron 方便，可以參考 [areweguiyet.com](https://www.areweguiyet.com/)
資料庫：[TiKV](https://tikv.org) 是 TiDB 底層的 kv storage，原生支援分散式、[Sled](https://sled.rs/) 是小型類似 SQLite 的 KV storage 適合用在 IoT（ORM 我就不想講了）
- **作業系統：** 這個主題比較有趣，有 AWS 開源給 container VM 的 [bottlerocket](https://github.com/bottlerocket-os/bottlerocket)，還有 AWS lambda serverless 底層的 [firecracker](https://github.com/firecracker-microvm/firecracker)、有 Google 下一代作業系統 Fuchsia（核心部分一半 Rust 一半 C++），還有從 kernel 開始自幹重寫的作業系統 [Redox OS](https://www.redox-os.org/)（真的可以在裸機上面安裝）
安全元件：openssl 的替代品 [rustls](https://github.com/ctz/rustls) 最近經過一些第三方審計，可以免除 OpenSSL heart bleeding 的問題；[Sequoia-PGP](https://sequoia-pgp.org/) 是維護 GnuPG 團隊其中三個人自己出來幹的 PGP（GPG）實作。
- **嵌入式系統：** 這塊我比較不熟（文章都跳過），但 Rust 官方有個 [dedicated 團隊在搞這個](https://github.com/rust-embedded)，基本上常見的開發版都能編譯，而且 Rust struct 編譯出來最後會是 zero cost abstraction，所以寫嵌入式變得更語義化，而不是一直在搞 bit。Google 和一堆知名大學也合力開發 [Tock 安全嵌入式系統](https://www.tockos.org/)。
- **視訊、音訊：** 這邊我也比較不熟，但 Mozilla 有小組在搞下一代影音格式 [rav1e](https://github.com/xiph/rav1e)，應該是 AV1 官方之外最快最 robust 的選擇；[image-rs](https://github.com/image-rs/image) 也是非常實用的各種圖片格式轉換的函式庫
- **前端框架與 WASM：** 因為 Rust 原生支援 compile 成 WebAssembly，所以就有了好幾套前端框架，最大一套叫做 [yew](https://yew.rs/)，核心維護者現在在台灣（是外國人）。當然 WebAssembly 目前就是 Rust 的天下，例如 [WASI](https://wasi.dev/) 這個跑在非瀏覽器的標準就是用 Rust PoC。其他 Python[（RustPython）](https://rustpython.github.io/) 或 Ruby[（Artichoke）](https://www.artichokeruby.org/) 的 in browser interpreter 都是借助 Rust combine to WASM 很方便才辦得到。
- **Scientific computing：** 這塊死了又活活了又死，有很多 dataframe 或類似 pandas [Weld](https://www.weld.rs/)，不過看起來還是 Python 比較有優勢。
- **C library binding：** 太多，都可以透過工具搞出來，基本上有 C 就可以幾乎自動搞一個零成本 Rust binding 沒問題。

## Cross-Compilation、Distribution 工具支援程度

接下來是「Cross-Compilation、Distribution 工具支援程度」。

- Rust 基本上 cross compilation 非常方便，除了 rustc 支援，也 [cross 工具](https://github.com/rust-embedded/cross)省去部分設定的麻煩，[這個列出 rustc tier 1 2 3 支援列表](https://doc.rust-lang.org/nightly/rustc/platform-support.html)，加上 rust compiler 現在目前就只有 rustc 一個實作，所以沒有什麼 gcc llvm 支不支援哪個 feature 的問題。
- 針對不同平台的 conditional compilation 也非常方便，在你要的 function struct 或是各種 item 上加 `#[cfg(windows)]` `#[cfg(not(unix))]` 之類的就可以 ，所以真的實作不同可以直接分開不用 runtime 判斷。
- Rust 編譯出來的東西就是一個 binary 或 .so  .dylib .dll ，如果不是 no-std（給嵌入式的特殊 cfg），除非你有另外使用其他特殊函式庫，基本上只 depends on libc，所以完全 portable，不會有什麼要 apt-get install python3-dev 之類的。
- 在 Linux distro 分發 Rust 的工具我知道的目前 Debian Fedora Ubuntu 已經在做，不過都是終端工具，dynamic lib 目前好像還沒有，主要是 Rust ABI 還沒有 stable 的問題
- 一個範例是我自己的小工具，[CI 就寫這樣](https://git.io/JTHYe)，然後就可以在三大平台跑測試，CD 也是類似的指定 target，就可[編譯出三大平台的 binary](https://git.io/JTHYe) 供下載。
- 另一個八卦是 ARM 最近給 Rust team 錢和編譯機器資源，想要提升 Rust 對 arm 的編譯支援程度達到 tier-1 等級，[RFC 已經合併了](https://git.io/JTHYz)。

## IDE 和 debugger、測試和開發工具支援程度

有關「IDE 和 debugger、測試和開發工具支援程度」：

這個你就來對時間了，如果你在 2019 年來，我會說只有 Intellij IDEA 這個 IDE 可以用，但 Rust 社群最近寫出了一個 langauge server 套件 [rust-analyzer](https://rust-analyzer.github.io/)，基本上類似 reimplement rust 編譯器的部分實作，我覺得用在 VIM 搭配 YouCompleteMe 完全無違和（雖然我最近改成 [Neovim built-in LSP](https://neovim.io/doc/user/lsp.html)），從 root 開  30 萬行大型專案基本上有時候一點點卡，但通常都只會進到 submodule 去修改就完全不卡。

Rust 我寫到現在很少用到 debugger，而且因為通常編譯錯誤多於 runtime error，所以其實相較之下很少用到 debugger，如果真的要用就要靠 Intellij IDEA 的 IDE 支援，或是 VS Code + rust-analyzer 下 breakpoint，這是我自己不熟從 terminal 下斷點啦，不過 Rust 最容易被誇獎的地方就是 compile error 非常明確告知是什麼原因，甚至會教你要怎麼改寫，我覺得 DX 很好。

Rust 編譯不用自己 link，類似 cmake 和 ninja 的工具叫做 [cargo](https://doc.rust-lang.org/stable/cargo/)，其實應該算 npm + build system 集大成，所以不用記得一堆指令，寫好 [Cargo.toml](https://doc.rust-lang.org/stable/cargo/getting-started/first-steps.html)（Rust 的 package.json）一切搞定。測試，benchmark，產生 API doc、發佈、跑 example 都是透過 cargo 這個工具。cargo 這個東西也支援 plugin subcommand，所以除了內建 `cargo build` 編譯，也可以安裝社群的 cargo cache 清理快取， `cargo audit` 對 dependency 安全檢查，或是 `cargo afl` 做 fuzz testing，有夠實用的就可能會納入官方 subcommand。

另一個很實用的就是 Rust 的 docstring 是 markdown，所以非常好撰寫文件，我覺得可以用 markdown 當作 docstring 的原因是因為 compile strong type language 不需要再寫 parameter 是什麼，反正都在 function signature 上面。然後所有發佈到 crates.io 的 library，它的 API doc 都會統一在 docs.rs 上面出現，例如這個 Redis client 就是從 docstring 生成的文件。

Rust 的測試就更有趣了：

- **Unit test：** 和 source code 寫在同一個檔案裡，用 `#[cfg(test)]` 做到 conditional compilation，只會在編譯測試時被編譯，編譯 debug/release mode 不會，這樣除了要測試的 code 和 unit test 很接近以外，也不用再考慮「這個內部函式到底要不要測試，我是不是要 public 一下測試但在註解說不要用這是內部函式」，反正在同一個檔案都可以 access
- **Integration test：** 獨立在另一個資料夾，基本上就和大多數語言一樣，只能 access public interface，自己是一個獨立的 compile target 沒什麼太特別
- **Benchmark：** 這算特殊的 test compile target，這裡面的測試會多跑幾次跑出統計結果這樣。
- **Doctest：** 剛剛講的 docstring，如果 markdown 裡面有 rust code block，就可以透過 doctest 測試你的 rust code block 是否可以正確編譯成功，不會讓 doc outdated，這裡有一個很好玩的 feature，假如你的 doc 只希望顯示 3 行 code ，但 setup 這 3 行需要其他 10 行才能成功編譯，你可以用[特殊的 `#` prefix 隱藏你不想要顯示的行數](https://github.com/hyperium/hyper/blob/e90f0037d3864ce91dad59eda49659db0e6ca322/src/client/connect/http.rs#L48-L66)。
- **Examples：** Rust 內建 code example compile target，在跑測試也可以一併跑這些範例，讓你範例不要 outdated

Rust 官方也有一個 formatter [rustfmt](https://github.com/rust-lang/rustfmt)，是選用的（不像 go format 不過編譯就不會過….），但是很多專案都會用，可以省去很多格式上的爭論；另外也有類似 eslint pep8 這種可以移除 bad smell 讓 code 更 rusty 的 [rust-clippy](https://github.com/rust-lang/rust-clippy)（clippy 就是以前 windows 迴紋針小幫手的名字 XDD），但有時候太刁鑽個人沒有特別喜歡。

Rust 官方自己有出一個類似 nvm rvm rbenv pyenv 這種工具叫做 [rustup](https://rustup.rs/)，從下載不同版本的 Rust，安裝一些 rust 工具週邊（在 Rust 叫做 component），到鎖定某個資料夾要用哪個版本編譯，編譯的 target 要是 linux-musl 還是 linux-gnu ，32 bit 還是 64 bit，都可透過 rustup 直接 override 你的 default 設定，原本測試跑在穩定版  `cargo test` 你想要測試 nightly 版也只要 `cargo +nightly test` 就可以，神之方便。

我自己覺得 2020 年是 Rust 開發體驗大躍進的一年，整個開發阻力降低非常多，很適合入場。

## 穩定性與 Compatibility

剩最後一點「穩定性與 Compatibility」我快速打完：

有人說 Rust 語言很新一直更版不穩定，事實上 Rust 非常嚴格遵守語義化版號 semver。從 2015 五月十五日 Rust 1.0 發佈到現在穩定版的 1.46，基本上沒有任何 breaking change。而且 Rust 版本發佈非常規率，嚴格的[六週發佈一個 minor version](https://forge.rust-lang.org/#current-release-versions)，所以跟著官方就會一直升級上去不會有特別的問題。

Rust 團隊想要導入 breaking change 的時候怎麼辦，他們開發了一種叫做 edition 的機制，目前預計是每三年發佈一次（有點像 c++11 14 17？），這個 edition 可能會有很小的 breaking change，例如將 `async` 原本不是關鍵字改為關鍵字，這種情況下 Rust 官方為了不要真的引入 breaking change，用了幾個手法緩解：

- 第一個就是 edition 是可以選擇的，如果你不想要升級到 2018 版本，那就留在 2015，所有東西都照常可以使用，只是 2018 一些新的語法糖就享受不到，但所有 compile 更新什麼的都會獲得，並不是 LTS 的概念。
- 第二個就是 Rust 團隊為了這個 edition 專門寫了一本 [Edition Guide](https://doc.rust-lang.org/edition-guide/) 告訴你每個版本有什麼新功能，你需不需要，要怎麼改寫或不改寫。
- 第三個就是直接提供 codemod 工具  cargo fix subcommand，協助你 migrate 到新版本，但你留在 2015 版，你還是可以獲得幾乎所有編譯器的新 feature 和 bugfix，不會有任何問題和差異，就是寫法舊了點繞了點。

Rust 團隊接下來可能會為了 compatibility 做的功夫是可以[在 `Cargo.toml` 指定最低支援的 Rust version](https://rust-lang.tw/rfcs-tw/2495-min-rust-version.html)，這可以讓社群的函式庫作者或使用者都能明確得知他的 rustc 版本是否足夠支援使用該 library，作者也可以很放心的寫出什麼時候要 drop 哪一個版本的 rustc 支援，我個人非常其他這個功能實現，但應該要一段不少的時間。

大概以上，我還沒想到更多。
