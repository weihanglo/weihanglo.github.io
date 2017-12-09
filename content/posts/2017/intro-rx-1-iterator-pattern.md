---
title: Intro Rx - 1. Iterator Pattern
tags:
  - Design Patterns
  - Iterator Pattern
  - Swift
  - ReactiveX
date: 2017-08-15T13:06:59+08:00
---

本篇介紹 Rx 的重要基礎概念 **Iterator pattern**。

_（撰於 2017-08-15，基於 Swift 3.1）_

<!-- more -->

## Definition

[迭代器模式（Iterator pattern）][wiki-iterator-pattern] 提供一個迭代器，讓使用者透過特定方式走訪序列（sequence）中的元素，而不需知道底層的演算法。

## Application

Iterator pattern 是最基本的設計模式之一，基本上大部分語言的 `for-in` loop 都是 iterator pattern 的實作。我們可以說 Python 的 `for x in iterable` 符合 iterator pattern，因為 Python 將該 `iterable` 封裝起來，使用者對 iterator 如何取得下一個 element 並不知情；Swift 的 `for x in Sequence` 中 `Sequence` protocol 也有 iterator 介面，並提供了 default implementation。

相反地， C 的 `for (int i = 0; i < n; i++)` 通常不認為是 iterator pattern，因為使用者知道底層資料儲存在連續的記憶體空間中，也必須自行透過指針迭代。

透過 iterator 封裝的序列（或集合），讓調用者不需關係實作，只需使用統一的 for loop，或是 `map`、`reduce`、`filter` 等高階函數，即操作序列中的元素，完全與演算法解耦合。

## Requirements

一般來說，要符合 iterator pattern 的實作，通常會有以下幾個介面：

1. 一個取得下一個 element 的方法，通常是 `next`
2. 告知使用者是否仍有下個 element 的方法，各語言有自己對應的實作，如：
  - 拋出 Exception（Python）
  - 主動 call `hasNext` 方法（Java）
  - 回傳 flag 判斷迭代是否完成（JavaScript）
  - 直接回傳 `nil`（Swift）

## IteratorProtocol & Sequence

在深入 iterator pattern 前，先來理解 Swift 最重要的兩個 protocol：`IteratorProtocol` 與 `Sequence`。

Swift 實作 iterator 須符合 [IteratorProtocol][swiftdoc-iterator-protocol]，該 protocol 要求一個 `next` method。雖然簡單，但要實作 iterator pattern 也是滿繁瑣的。我們直接看例子。

```swift
// 宣告一個 countdown 用的 iterator struct，每次迭代時會將當前計數減一。
struct CountdownIterator: IteratorProtocol {
    var count: Int
    mutating func next() -> Int? {
        guard count > 0 else { return nil }
        count -= 1
        return count
    }
}
```

其實這樣就做完我們的 iterator 了，我們可以嘗試使用 `while` loop 使用這個倒數計時器。

```swift
var it = CountdownIterator(count: 5)
while let v = it.next() {
  print(v)
}
/// 4 3 2 1 0
```

不過通常我們會希望將 next 方法藏起來，利用簡單的 for-in loop 迭代，這時候就該 [Sequence][swiftdoc-sequence] protocol 出場。**Sequence** protocol 提供一個按序迭代的介面，讓調用者可好整以暇的使用。只要符合 `Comparable`、`Equatable` 等 protocol，Sequence 甚至提供許多方便的 default implementations。

一般來說，Sequence 需有 iterator 的 associatedType，以及 `makeIterator` 方法，提供 sequence 製造 iterator 的介面。

```swift
struct Countdown: Sequence {
    let count: Int

    func makeIterator() -> CountdownIterator {
        return CountdownIterator(countdown: self.count)

    }
}

let countdown = Countdown(count: 5)
for i in countdown {
    print(i)
}
/// 4 3 2 1 0
countdown.forEach { print($0) } // ⚠️： Sequence 並沒有保證 repeated access
/// 4 3 2 1 0
```

這些步驟看起來異常繁瑣，我們可以利用 Swift 提供的 default implementation 減少 trivial part。若同時符合 Sequence 與 IteratorProtocol，只要實作 `next`方法，則 Sequence 會自動產生 `makeIterator`。

```swift
struct Countdown: Sequence, IteratorProtocol {
    var count: Int
    mutating func next() -> Int? {
        guard count > 0 else { return nil }
        count -= 1
        return count
    }
}

// 可以透過 default implementation 直接使用 `map` 方法！
Countdown(count: 5).map { $0 * 5 }
/// [20, 15, 10, 5, 0]
```

## Collection protocols

Sequence protocol 僅提供迭代方法，並不能保證序列能否走訪多遍，也沒有提供 subscript（下標）。[Collection][swiftdoc-collection] protocol 提供 subscript 的容器介面，並建議實作 access elements 預期為 O(1) 複雜度。  
不過實際情況因實作而異，例如 Doubly linked-list 遵循繼承自 Collection 的 [BidirectionalCollection ][swiftdoc-bidirectional-collection] protocol，卻無法如符合 [RandomAccessCollection][swiftdoc-randomaccess-collection] 的 Array 一樣有 O(1) 的隨機存取操作。

這些 Collection protocols 加強了 Iterator pattern 應用面的生產力，演算法能以更豐富的方式呈現給使用者。好比 Swift Standard Library 中的 Array、Dictionary 和 String 也都是實作 Collection protocol 的案例，而這些的集合實作就非常夠開發者使用了，幾乎不需考慮底層的演算法，更甚不必接觸任何 Iterator。

## Conclusion

Iterator pattern 封裝了許多演算法，讓使用者能夠專注在更高層次的邏輯上；iterator pattern 同時也提供迭代完畢的訊息，許多程式間通訊得以透過 iterator 完成不同的任務。近來很流行的 generator／coroutine 都是建立於 iterator pattern 上，Rx 的設計理念也是吸收 iterator pattern 的精華，提供 `Observable` **no data available** 與 **error** 的重要特性。

## Reference

- [SwiftDoc.org][swift-doc-org]
- [Wiki: Iterator pattern][wiki-iterator-pattern]

[swift-doc-org]: http://swiftdoc.org/
[wiki-iterator-pattern]: https://en.wikipedia.org/wiki/Iterator_pattern
[swiftdoc-collection]: http://swiftdoc.org/v3.1/protocol/Collection/
[swiftdoc-sequence]: http://swiftdoc.org/v3.1/protocol/Sequence/
[swiftdoc-iterator-protocol]: http://swiftdoc.org/v3.1/protocol/IteratorProtocol/
[swiftdoc-bidirectional-collection]: http://swiftdoc.org/nightly/protocol/BidirectionalCollection/
[swiftdoc-randomaccess-collection]: http://swiftdoc.org/nightly/protocol/RandomAccessCollection/
