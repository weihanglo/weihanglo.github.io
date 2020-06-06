---
title: "WWW 0x07: 為什麼薯餅要炸兩次"
date: 2020-03-07T00:00:00+08:00
tags:
  - Weekly
  - Data structure
  - Rust
  - Databases
---

這裡是 WWW 第柒期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [Why is Rust the Most Loved Programming Language?](https://matklad.github.io/2020/02/14/why-rust-is-loved.html)

又到了推坑 Rust 的時間！這次，[Intellij Rust](https://intellij-rust.github.io/) 和 [Rust Analyzer](https://rust-analyzer.github.io/) 的作者想聊聊為什麼 Rust 值得「最受喜愛的程式語言」的稱號，節錄我覺得蠻有共鳴的點：

> - Intellij Rust：用 Kotlin 寫的 Jetbrains IDE Rust Plugin
> - Rust Analyzer：新一代的 Rust IDE language server

- [Keyword First Syntax](https://matklad.github.io/2020/02/14/why-rust-is-loved.html#keyword-first-syntax)：搜尋 foo 函式只要文字搜尋 `fn foo` 就解決，有利於一般人開發，更使得 IDE 的 parser 更容易開發 
- [Crates](https://matklad.github.io/2020/02/14/why-rust-is-loved.html#crates)：Rust 的 crate 是一個編譯單元，但並沒有 global shared namespace，取而代之的是每個 crate 都會是你的 dependant crate 的一個 property，解決了 lib 命名衝突問題
- [`Eq` 並非多型](https://matklad.github.io/2020/02/14/why-rust-is-loved.html#eq)：以前從來沒想過這個問題，但的確不同型別的比較直接 compile error 很合理，不過代價是需要寫一堆 `as usize` 😂
- [Trivial Data Types](https://matklad.github.io/2020/02/14/why-rust-is-loved.html#trivial-data-types)：透過 `#[derive(...)]` 可以很快速衍生出一堆 boilerplate，不需要再~~像某 Gx 語言一樣~~複製貼上
- [String encoded in UTF-8](https://matklad.github.io/2020/02/14/why-rust-is-loved.html#strings)：現在看起來是優點，未來就不一定了 😈

## [Understanding the power of data types](http://postgres-data-types.pvh.ca/)

滿全面的 PostgreSQL Data Type 概觀，二十分鐘內讀完，推推。

- 字串一律用 `text`、時間一律用 `timestamptz`
- type 底層的 data layout，並介紹 [TOAST 技術](https://www.postgresql.org/docs/12/storage-toast.html)來儲存巨大 field value
- `array`/`jsonb`/`enum`/`range` 使用時機和各種小技巧
- 各種強大 extension e.g. PostGIS（好用）、PostBIS（生物資訊）
- 如何自幹 data type 並整合 aggregate、function、operator

## [Hashbrown/SwissTable](https://rust-lang.github.io/hashbrown/hashbrown/)

最近在看 hashbrown 的實作（Google SwissTable 的 Rust 版），發現幾個有趣的點分享給大家：

- 雜湊碰撞的解法有 open addressing 和 separate chaining ，open addressing 有強大的 cache hit rate。
- open addressing 的問題在於 delete k-v pair 時，假如現在有三個 pair 碰撞在同個 slot (hash value 一樣 slot 就一樣），當 delete (29, 7) 時，index 1 的 bucket 就為空， (6, 6) 就沒辦法在線性搜尋中找到

```
index |  0  |  1   |  2  | 
------|-----|------|-----|
value | 5,7 | 29,7 | 6,6 |
------|-----|------|-----|
slot  |  0  |  0   |  0  | 
```

- 承上，解法有兩個， 1）backshift 向前重排法 ，deleted pair 之後所有碰撞的 pair 都往前 shift，還有 2）tombstone 墓碑標記法 ，標記該 bucket 曾經死過人，線性搜尋就可以延續往後找，跳過這個墓碑
- hashbrown/SwissTable 有做 SIMD 最佳化，可以把 SIMD 想成一個 CPU 指令下去多個 byte 同時平行處理，因此 hashbrown 每個 bucket 除了儲存 k-v pair，還會多存 control byte，是 hash value 的最大（或最小）的 8-bits，讓每個 SIMD 指令一下去，可同時比較 16 bucket (`16 * 8 = 128 bits` 的 register size） 的資料是否 hash value 相同，速度飛快
- 我想不到了言盡於此，大家可以自己看文章

### References

- [雜湊表界的瑞士刀](https://blog.waffles.space/2018/12/07/deep-dive-into-hashbrown/)
- [為什麼薯餅要炸兩次](https://gankra.github.io/blah/hashbrown-insert/)
