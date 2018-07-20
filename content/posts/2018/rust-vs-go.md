---
title: 【譯】Rust vs. Go
date: 2018-07-20T10:58:59+08:00
tags:
  - Rust
  - Golang
---

> 本文譯自 [Julio Merino][julio-merino] 的 [Rust vs. Go][rust-vs-go]。Julio Merino 目前是 G 社僱員，在 G 社工作超過 8 年，無論工作內外，都接觸開發不少 Go 語言，並撰寫 [Rust 點評][rust-review]系列文，來聽聽他對 Rust 與 Go 的想法吧。  
>  
> Thanks [Julio Merino][julio-merino] for this awesome article!

[rust-vs-go]: http://julio.meroh.net/2018/07/rust-vs-go.html
[julio-merino]: http://julio.meroh.net/

---

歡迎來到「[Rust 點評][rust-review]」系列特別篇，也是我在系列文開始就承諾撰寫的主題，將探討一個難以忽視的大哉問：Rust 與 Go 孰優孰劣？

這麼比較並沒有根據，所以不會有標準答案。我認為人們會把這兩種語言作伙比較只因為它們幾乎同時釋出，而且 Rust 的釋出像是在回應 Go。除此之外，兩種語言都被認為聚焦在系統軟體上（system software），但其實它們大相徑庭，就算都專注系統軟體，各自目標的軟體類型也不盡相同。

Go 可以視為「做對了的 C」或是「Python 的替代品」。Go 在開發網路伺服器與自動化工具的領域發光發熱。Rust 專注在正確與安全性，定位在 C++ 與 Haskell 之間，如同之前提及，可以視為「務實的 Haskell」。儘管 Rust 的語言抽象程度很高，它仍承諾這些抽象是零成本（zero-cost abstraction），也就是說，它應該擅長寫任何系統專案。

這篇個人點評基於我用兩種語言寫了相同的專案 [sandboxfs][sandboxfs]。最初實作是用 Go，而我開發了另一個用 Rust 的實驗性改寫（還沒有完全檢驗），兩個實作都通過相同的測試套件（test suite）。除了透過這次改寫來學習語言，也因為當我分析 Go 實作版本的效能時，發現熱點總是在 Go 的執行環境（runtime），我想要嘗試看看簡單的 Rust 改寫後效能能否長進，而情況似乎就是如此。隨著這次改寫，我很訝異原本的 Go 實作版本有不少潛在的並行（concurrency）漏洞，因為許多 Rust 並不允許我利用相同的設計改寫。

在開始之前，也許你會想讀讀[兩年前我對 Go 語言的點評][golang-review]。讀完了嗎？我們開始吧！

[rust-review]: http://julio.meroh.net/series.html#Rust%20review
[rust-review-introduction]: http://julio.meroh.net/2018/05/rust-review-introduction.html
[sandboxfs]: https://github.com/bazelbuild/sandboxfs/
[golang-review]: http://julio.meroh.net/2016/03/golang-review.html

## 記憶體管理

要說 Rust 與 Go 之間最明顯的差異，首推各自的記憶體管理方式。

Go 根據物件的生命週期，決定物件要配置在 stack 或 heap 上，而後者會以垃圾回收機制（garbage collection）管理。Rust 則是手動（explicit）配置在 stack 和 heap 上，而後者會透過 scopes（C++ 用語中稱為 RAII）與 ownership/move semantic 管理。

在這個領域中，典型的權衡是垃圾回收與手動記憶體管理（explicit memory management）。這代表 Go 因為垃圾回收機制帶來額外開銷，而 Rust 並不會。但對大多數軟體而言不會是個問題。試想你上一次寫效能需求高，不能有延遲，且 CPU-bound 的程式是什麼時候了。

若要高效使用 Rust，需要瞭解電腦記憶體如何運作。Go 可以赦免你不懂記憶體管理，但如同我下一節將提到的，不懂記憶體並非好事：瞭解記憶體運作是通往程式設計大師之路的重要一步。

**獲勝者**：無法決定。Go 與 Rust 兩者都提供更不容易記憶體洩漏（memory leak）且具有優良人因設計（ergonomic）的記憶體管理機制。

## 難度

Go 是一個簡單中不失自身優雅的語言。Go 極度容易幾刻鐘內上手並搞出一堆程式碼。然而，如同我們在「[Rust 點評：學習曲線][rust-review-learning-curve]」一文所述，這可能是謬誤：在你剛學了任何語言後馬上寫的程式碼都不會最符合該語言特性，最佳實踐的程式需要花更多時間熬出。

對 Rust 來說，不能否認它是一個複雜的語言，也許沒有 C++ 這麼複雜，但仍有大量的概念在其中。撰寫 Rust 程式的確需要更多精力。對應的收益是，當你的程式寫完且成功編譯，很高的機率它會安然無恙的運作。這情境無法完全套用在 Go 上，我見過太多太多執行期（runtime）錯誤崩潰了。

你要選擇自己的戰爭：快速地撰寫 Go，再花費額外的時間寫瑣細的測試與修正執行期的問題；或是花時間一步步撰寫穩健的 Rust 程式，避免構建後的問題。

**獲勝者**：難以決定。我們可以很簡單地說 Go 贏了，但我並不想要這樣定論，因為我個人喜歡花更多時間打造一個禁得起時間考驗的程式，而非在未來還必須追蹤複雜的記憶體與線程問題。

[rust-review-learning-curve]: http://julio.meroh.net/2018/06/rust-review-learning-curve.html

## 泛型

Go 不支援泛型。Go 的作者們並沒有堅決反對泛型，但他們聲稱無法簡潔地實作或支援，而開始動手做之前，必須先找到完美解法。因此，人們濫用 `interface {}`，將之作為泛型使用，其他 Go 程式碼也無法受惠於以此實作的原生函式（如 `append`）。

Rust 剛好具有如你所願的泛型。這個泛型支援普通型別及 traits，而且你還可以透過 `impl` 與 `dyn` 這兩個新特性（從 2018 開始），控制 Rust 從 traits 上面產生的泛型機器碼（machine code）。

**獲勝者**：不用多說了，非 Rust 莫屬。

## 程式碼完備性（Code sanity）

我最不能接受 Go 語言缺失的功能是沒有提供零抽象成本的方法，透過程式碼自身來編撰穩健的程式。沒錯，自動程式碼格式化和強力建議程式如何寫這兩件事很美好，但這不足以強制改善程式邏輯。我發現自己常常撰寫過長的註解來解釋一些完全不可能的條件，或為什麼特定參數可以運作，還有變數與互斥鎖之間有什麼關係⋯⋯，這些都是未來程式會崩毀的病徵：[註解無法透過編譯器檢驗完備性，而且註解一定會過時][readability-avoid-comments]。只要有機會，所有東西都該以程式碼表達。

那麼，什麼我在 Rust 發現什麼 Go 缺少的功能，可令程式碼更穩健更能防範未然？

- **斷言（Assertions）**。斷言之所以無價，是因為它讓程式設計師們得以溝通不一定明顯的意圖。Rust 有斷言，反觀 Go 沒有。呃⋯⋯Go 的確有 `panic` 可以來模擬斷言，但這作法不被認可，你應該永不使用它。

    為什麼 Go 沒有斷言呢？以下是我瞎猜的：因為程式設計師常常誤用斷言來驗證使用者的輸入，這樣導致有不對或惡意輸入時產生執行期錯誤。於是，崇尚務實主義的 Go 要求把所有問題當成可以被控制的錯誤，從而避免「誤用斷言」這種情況。（嗯⋯⋯，這我過些時間想再寫一篇獨立的文章來討論⋯⋯) 

     順便提個我常常聽到的說法：你可以從寫了多少斷言來判斷一個程式設計師的經驗是否老到，而越多代表越老練。歡迎對這個想法有任何評論。

- **標註（Annotations）**。有時候該用到的輸入參數沒使用到，或該檢查的回傳值沒檢查。或其他時候，你知道一個特定函式永遠不會返回，而且希望給予呼叫端這項資訊，讓編譯器閉嘴。舉個例子，缺少 return 陳述句。Go 沒有這些標註，讓程式設計是很難清楚表達意圖。而 Rust 嘟嘟好有這些標註。

    更糟的是，Go 有些特定內部函式的行為如 `panic`，這些編譯器知道無法回傳，但不可能在你手寫的 Go 程式碼中表達這件事。如果考慮這問題和前面提及泛型是同個缺點，再次提及比較有點失允。

- **註釋即文件（Docstrings）**。是的，Go 有 docstrings，但神基本。雖然大部分可以正常運作，但寫了一堆 Java 之後，知道事先定義好結構的 docstrings 能提供不少價值。許多工具可協助檢驗文件的完備性。舉例來說，IntelliJ 可以驗證參數名稱是否對應真正的函式參數，並且交叉參照其他類別是否也合法。

    Rust 的 docstrings 支援 Markdown 而比 Go 來得好些，但仍無明確的撰寫指引：似乎沒有一種標準方式撰寫，也不支援替每一項目個別撰寫文件，工具更無法交叉檢查 docstrings 是否和程式碼吻合。

- **錯誤檢查（Error checking）**。我是少數（？）喜愛 Go 手動錯誤傳遞的一分子。你說得沒錯，寫一堆錯誤檢查很惱人，但這樣做迫使你使用與其他語言不同的方式思考錯誤這檔事。

    很不幸，Go 選擇的寫法有些問題：一個函式總是回傳一個結果值與一個錯誤，呼叫端可以決定先檢查錯誤，再檢查值。語言本身並無強制做這件事，而我看多太多太多錯誤是在檢查錯誤前先取值所導致。另一方面，Rust 帶著更高端的型別封裝了值或錯誤，加上沒有 null 這個特點，這代表了呼叫端永遠不會在錯誤存在時取得結果值，反之亦然。可以參考看看 [`Result` 型別][rustdoc-result]還有我寫[有關 match 關鍵字][rust-review-match-keyword]的文章。

讓我下個結論，一個正向的聲明，這兩個語言都不提供自動型別。舉例來說，Rust 與 Go 強制程式設計師們整數轉型至不同大小，於是任何可能溢位（overflow/underflow）之處顯露無遺。提醒你一下：Go 在這方面比 Rust 稍強些，因為 Go 的型別別名（type alias）語義上被視為不同的型別，編譯時需要手動轉型，而 Rust 則是當作語法上的別名（就像 C `typedef` 所作所為）。

**獲勝者**：Rust 輕鬆勝出。你可以主張這只是對 Go 缺乏功能的一些抱怨，而且應該接受 Go 就是這種風格，但我不行：這些抱怨就是討論上述失能讓 Go 無法寫出防範未然，晶瑩剔透的程式碼。

[readability-avoid-comments]: http://julio.meroh.net/2013/06/readability-avoid-comments.html
[rustdoc-result]: https://doc.rust-lang.org/std/result/
[rust-review-match-keyword]: http://julio.meroh.net/2018/06/rust-review-match-keyword.html

## 效能分析

Go 的簡便無所不在，連讓程式最佳化的工具也不例外。從效能分析（profiling）來看，Go 內建追蹤 CPU 和記憶體用量的機制，且能與 [pprof][pprof] 工具整合。可以很容易檢查 Go 程式並取得有用的資料來最佳化。

我還沒發現任何 Rust 的分析工具可以和 Go 的工具一樣整合 pprof。當然，有一個函式庫可以生成類似 pprof 的追蹤資料，但我無法簡易上手，安裝上也有點詭異（需要 gperftools 以顯示在系統上）。[這篇舊文][tools-for-profiling-rust]有相關資訊和工具可供參考。

**獲勝者**：就我目前所知，Go 在這方面大勝。

[pprof]: https://github.com/google/pprof
[tools-for-profiling-rust]: http://athemathmo.github.io/2016/09/14/tools-for-profiling-rust.html

## 構建速度

打從娘胎開始，Go 就被設計為盡可能快速構建。就我所知，這是為了減少 Google 內部大型應用程式構建時間而做的嘗試。我猜測這合理解釋為什麼 Go 選擇 duck typing 來避免組件間強耦合，進而加速增量編譯（incremental compilation）。當我第一次在 NetBSD 自我建立（bootstrap）Go 整個工具鏈時，我非常震驚，整個流程只需要幾分鐘。我以前使用 clang 需要幾小時建立環境。

Rust 是家喻戶曉的編譯緩慢，所有完備性檢驗（sanity check），例如 borrow checker 和泛型，並不是白吃的午餐。我聽說有機會可以改善，但第一，我還沒研究過；第二，這說法尚未實現。

**獲勝者**：簡單啦，Go。

## 構建系統

依照現代程式語言的慣例，Go 和 Rust 都有自己的套件管理與套件相依追蹤工具。

在 Go 語言，有窮極簡單的 Go 內建工具允許我們取得套件與它的相依套件，且無需任何設定檔就可構建整個專案。聽起來超誘人的，但事實上略違反基本工程慣例，有點危險。舉例來說，Go 的工具總是從網站如 GitHub 取得最新快照版本的相依套件，但完全沒有任何機制指定版本，也無法確保惡意程式碼混入。我認為這應是受 Google 超大單一儲存庫（monorepo）如何運作，以及「在最新版構建」（build at head）的哲學影響，但這不太符合開源社群生態的期待。顯然 Go 社群最後接受了他們需要一個更好的解決方案，有[許多提案][go-proposal-versioning]也嘗試改善這種狀況。

在 Rust 這邊，我們有 Cargo，在專案中使用 Cargo 會需要比 Go 內建機制多一點點設定，但就只有一點點：典型的 `Cargo.toml` 只需列出幾行相依套件和該專案基本資料（metadata）即可。Rust 社群使用 Cargo 可以解析的[語意化版號][semver]管理相依。換言之，Rust 和 Cargo 設計上就支援他們身處的生態系，而非趕鴨子上架。Cargo 完全是 Rust 最美好的功能之一。

有趣的是，人們可以透過 Bazel 構建 Go 與 Rust 的程式。這種情況下，Bazel 透過一系列條件（`rules_go`）修正了上述提及 Go 的已知問題：這些條件允許相依套件以及工具鏈固定版號。至於 Bazel 對 Rust 的支援還很陽春，對應的條件（`rules_rust`）並沒有太多功能。

**獲勝者**：只考慮原生構建系統，Rust 的 Cargo 工具鏈勝出。如果把 Bazel 拉進來討論，目前是 Go 略勝一籌。

[go-proposal-versioning]: https://github.com/golang/go/issues/24301
[semver]: https://semver.org/

## 單元測試

對任何程式碼來說，自動化測試是確保程式依照期望執行，並保證程式成長時仍能正確執行（例如：沒有寫測試就無法做大規模的重構）。Go 這方面的表現令我嗤之以鼻，我想我會保留內容給另一篇專文討論。Go 的 `testing` 套件看來完全不鳥現代的測試技術，一心走自己認定的套路。那欸安捏？捨棄斷言（assertion）不用，導致只有測試函式自己可以使測試失敗，不允許其他輔助函式或固定資料（fixture）。對不複雜的單元測試來說挺誘人的，但往往不好控制。最終，更複雜的測試讓真正的待測邏輯變得更隱晦，更難以理解。

謝天謝地，Go 有個第三方函式庫 `testify` 提供類 JUnit 的測試框架。這函式庫使用合理的語義進行測試。較嚴重的問題是 Go 社群文化較武斷，你可能沒有機會在專案中使用它。

另一頭，Rust 的測試函式庫較貼近你預期的其他語言的行為。換言之，你有斷言可以用。我發現比較奇怪的點是，Rust 推薦你把測試寫在與待測原始碼同一份檔案中。由於我還沒寫足夠的測試，不清楚在真實世界中這種做法到底會如何？

**獲勝者**：我很想說是 Rust，因為 Go 的測試途徑太令我失望了，但 Go 有 `testify` 套件存在，我必須說兩者平分秋色。

## 結論

每一種程式語言皆有優缺點，這些小小的權衡抉擇是我藉由 Go 與 Rust 做比較來 證明這個概念。在每個部分勝出的語言都不一樣，有些時候你根本無法決定誰更有優勢。

> 您身為工程師的職責就是瞭解每個專案該如何權衡，並替專案選擇最佳的工具。Rust 與 Go 只是工具，挑一個最適配[團隊][bazel-tests]，專案，還有你自己吧（按照這個順序）。

如果你希望我能更具體，我會強力推薦在座的各位學習 Rust，與 borrow checker 與 ownership 和平共處。即使最終你並沒有使用 Rust，過程中所學都會回饋到其他語言上，連 Go 也不例外。

[bazel-tests]: http://julio.meroh.net/2018/03/bazel-tests-in-java-part-1.html

---

> 以上翻譯經過原作者同意，但譯者並非科班也沒有翻譯學位，若有語句不通順或不合理之處，請留言或與我聯繫，切莫直接怪罪原作者。
