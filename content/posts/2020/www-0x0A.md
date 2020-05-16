---
title: "WWW 0x0A: 嗯，你這塊 0xDEADBEEF"
date: 2020-03-28T00:00:00+08:00
tags:
  - Weekly
  - Rust
  - Golang
  - Assembly
---

> A programmer had a problem. He thought to himself, "I know, I'll solve it with threads!". has Now problems. two he
>
> — Davidlohr Bueso

這裡是 WWW 第拾期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [The Missing Semester of Your CS Education](https://missing.csail.mit.edu/)

這是近期看過最實用導向的大學課程了！由 MIT 博士生授課，但不教死板又混亂的計算機科學，而是貼近開發者，異常實際的工具和技巧。

雖然內容對部分業界人士來說可能略淺，例如 metaprogramming 居然是在講 build system 和 makefile，不過學資訊的學生不一定熟稔，非常適合作為進入業界前先修的「失落的課程」。我自己印象最深刻的是「 _...if you start a command with a leading space it won’t be added to you shell history._ 」真的是嚇歪我的毛，推薦大家翻翻看看。

> 順便提一下 [JonHoo](https://twitter.com/jonhoo) 是我有認真在看的 live-coder。嗯，應該猜的到他寫什麼語言

## [Early Impressions of Go from a Rust Programmer](https://pingcap.com/blog/early-impressions-of-go-from-a-rust-programmer/)

我有過很多面之緣的 Rust 核心成員 [Nick Cameron](https://github.com/nrc) 在大型專案中使用 Go 語言後（我猜是 TiDB）的評價，摘要個人覺得有趣的觀察面向：

- 很實際，設計得宜、小巧好學、std lib 很小很讚
- 比 C、C++、Java、Python 開發快，而且有很多改善，但撰寫感覺上是同世代的語言，例如還是有 null pointer
- 少了 macro 和 generic，專案大就會有許多 boilerplate 和 `if err != nil { return err }`，讓閱讀原始碼變得困難
- 有 var args（應該是跟 Rust 比 XDD）
- `go` tooling 集中一處而非分散成好幾個小工具，很方便
- 沒有 first class enum，用 constant 代替感覺開倒車（也導致 `switch` 並非 exhaustive，也就是 compiler 不會要求窮舉所有 enum member）
- 在內建功能和黑魔法之間的取捨不太一致，Go 有很多魔法，但也很多簡單的事無法達成，例如 `for ... range` 可用在 array 和 slice 但不能用在其他 collection type；`len`、`append` 是全域泛型函數，但只能用在內建型別，而且不能自己定義全域函數

個人認為 Nick 給的評價很正面，而我根據自己不太多的經驗，對 Go 的評價是「A tool to get jobs done easily」，但感覺就是把事情做完，寫程式那種創意設計回饋感較低。

（理性勿戰）

## [A slick `matches!` macro comes with Rust 1.42.0](https://godbolt.org/z/ysCzYF)

> 其實是一篇複習 x86 assembly 的文章

[Rust 1.42.0](https://blog.rust-lang.org/2020/03/12/Rust-1.42.html) 在 2020 年 3 月 12 日正式釋出，除了實用的 [subslice patterns](https://github.com/rust-lang/rust/pull/67712/)（和 Python 的 slicing 很相似）、更詳細的 `unwrap` 錯誤訊息（不用再 `RUST_BACKTRACE=1` 看 callstack），最有趣的就是 [`matches!` 這個 macro](https://doc.rust-lang.org/stable/std/macro.matches.html)，提供了比較 expression 是否符合特定 pattern，不用再寫整個 `match` expression 來比較。

但今天想要分享的是 Rust 在 pattern matching 上如何最佳化，[這個例子](https://godbolt.org/z/ysCzYF)比較 `char` 是否落在大小寫 A-Z a-z 的範圍中：

```rust
pub fn slick(c: char) -> bool {
    matches!(c, 'A'..='Z' | 'a'..='z')
}
```

編譯出來最佳化的組合語言長這樣：

```assembly
example::slick:
        and     edi, -33 ; #1
        add     edi, -65 ; #2
        cmp     edi, 26  ; #3
        setb    al       ; #4
        ret
```

帥！其實原理很簡單，讓我們一行一行解密：

1. 第一行是在抹去大小寫差異，A 是 `0b1100001`，a 則是 `0b1000001`，兩者剛好差了 32，也就是 `0b100000`，因此可利用 bitmask 抹去第六個 bit，這樣小寫字母都會得到跟大寫一樣的值
    ```
    0b1100001 # a
    &
    0b1011111 # -33 = ~32
    =
    0b1000001 # A
    ```
2. 第二行則是將大家一視同仁減去 65，這樣的結果就會落在 0 ~ 25 之間
3. 第三行的 [`cmp`](https://www.felixcloutier.com/x86/cmp) 實際上是執行 `SUB` 指令，但只會將結果狀態紀錄在 EFLAGS 暫存器，由於 `0 ≤ edi < 26 `，所以 `edi - 26 < 0`，可以得知需要借位，所以 CF（carry flag）會被設為 1
4. 第四行的 `setb` 屬於 [`SETcc`](https://www.felixcloutier.com/x86/setcc) 指令家族，會針對不同的條件設定 byte value，而 `SETB` 的功能是「**Set byte if below (CF=1)**」，理所當然 `AL` 會被設定為 1 然後回傳了。

> 打到這邊心好累，x86 asm 整個忘光，還請教了即將進入 Amazon 實習的大大才解決，我們感謝他。
