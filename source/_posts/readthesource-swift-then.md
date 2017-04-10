---
title: 閱讀原始碼：Swift-Then
date: 2017-01-10 12:15:34
tags:
  - Swift
  - Source Reading
---

本系列文視筆者心情不定期撰寫。

提升程式設計能力的途徑，不外乎一個字「寫」。而另一個重要方法，則是「讀」。我們很容易將雜亂無章的想法轉化為程式碼，卻不易從程式碼反推回作者的意圖。藉由閱讀原始碼，可了解問題脈絡與解法邏輯，探討值得學習的技術點，將別人的多年修煉化為自身內功！

<!-- more -->

---

> Programmer 不一定懶惰，但厲害的 programmer 絕對很懶惰！
>
> **_Weihang Lo_** -- *Daily Trash Talk*

厲害的 programmer 會為了少打幾個字，犧牲睡眠與休閒時間來開發偷懶工具，

第一篇，先從簡單的 Framework 開始，[Then][Then] 就非常有代表性。

_（撰於 2017-01-10，基於 Swift 3.0、 Then 2.1.0）_

## Problem to Solve

我們知道，Block 的引入為古老的 Objective-C 增添了 lambda／closure 的現代感，Swift 則繼續將其發揚光大。有了 closure，我們不必將所有 UI 元件的設置全擠在 `viewDidLoad` 裡面。我們只需要：

```swift
let label: UILabel = {
  let label = UILabel()
  label.textAlignment = .center
  label.textColor = .black
  label.text = "Hello, World!"
  return label
}()
```

可是對懶惰的 programmer 來說，這段程式碼太多地方重複，必定還有偷懶的空間。[Then][Then] 這個迷你的語法糖 library 就是專為偷懶而生，目的就是將上面冗長的初始化設置簡寫如下：

```swift
let label = UILabel().then {
  $0.textAlignment = .center
  $0.textColor = .black
  $0.text = "Hello, World!"
}
```

出自韓國人之手的 [Then][Then]，僅為了節省 Programmer 珍貴的鍵盤敲擊次數，卻在 Github 上獲得不少關注，截止 2016 年底，得到 1402 stars。深入觀察這正港韓貨，扣除 Framework 複雜的 build settings，真正的原始碼只有[短短 76 行][Then.swift]，再扣掉 comments 和 license 後剩不到 40 行。雖然這個 library 很小，該有的技術卻沒少，可謂一字千金。

## What to learn

我認為 **Then** 有以下幾個技術點值得關注：

- Protocol Extensions
- Value Types V.S. Reference Types
- In-Out Parameters
- Generic Where Clauses

## How To Solve

### [Protocol Extensions][protocol-extensions]

要給所有 NSObject subclass 添加一個 `then` method，使用 **Protocol** 絕對是不二法門。Protocol 常對應到其他語言的 Interface，類似 class，有自己的 methods 和 properties，但並不包含任何實作，而是等著其他 class 來滿足實作，使不同 class 之間可以分享相同的介面。缺點是，所有繼承 protocol 的 subclass 都需實作這些 methods，豈不麻煩？

如果我們可以從 protocol（interface）提供 default implementations 呢？很抱歉，在 Java 和 Objective-C 的世界裡，protocol 只能存在抽象介面（註一）。事實上，Swift 的 protocol 本身也沒辦法提供實作，直到 Swift 2 釋出， **protocol 才能透過 extension 提供 default implementations**，當個名副其實的富爸爸，而非虛有其表。

我們來看 **Then** 中的實例（實際上，最初版本就長這樣，短短八行）：

```swift
public protocol Then {} // 1

extension Then { // 2
  public func then(_ block: (Self) -> Void) -> Self {
    block(self)
    return self
  }
}

extension NSObject: Then {} // 3
```

1. **Then** 最核心的部分就是這純淨的 `Then` protocol，毫無任何 requirements。
2. 這個 protocol extension 提供 default implementations 給所有 adopter。
3. `Then` 被 `NSObject` adopted，`NSObject` 就像是富二代，不用做事，就能直接獲得 `then` method 的能力。

利用 **Protocol Extensions**，subclass 不需再次實作，大大減少 boilerplate code。嫌污染環境，甚至可以透過 [ACL（Access Control）][ACL]來決定 protocol extension 的作用域，但關於 ACL 又是一個議題了，打住先。

不過，protocol extensions **也是有大坑**，多重繼承的問題依然存在。如果繼承多個 protocols 中包含相同 method signatures 的 default implementations，compile 會過，但 runtime 會找到太多 candidates 而報錯。總之，作者 open source 八行程式碼，成功延長你我鍵盤使用年限，揪甘心！

### [Issue: Cannot used with `struct`][issue-16]

不過問題沒這麼簡單，有人發現 `struct` 沒辦法使用 `then`，會報錯：

> Cannot assign to property: '$0' is a 'let' constant

`Swift` 的 function parameters 是 constant 的 let（註二），傳入 function 後無法更改其 value（這裡的 value 是該 argument 實際指向的 value）。當然，如果是 `class` 這種 reference type，可以更改其 properties，但若是 `struct`、`enum` 這些 value type，必須要宣告一個新的變數 `var newValue = oldValue`，將其 copy 一份，直接更改 `newValue`。可能的解法如下：

```swift
func then(_ block: (Self) -> Void) -> Self {
  var copy = self
  block(self)
  return self
}
```

**結果還是報一樣的 Error！**

這是因為傳入 closure（block）的 parameter 仍然是 immutable 的 let constant。為了讓 value type 可以使用這個 syntax sugar，豈不是實作上還要多宣告一個 copy 的變數，完全沒偷到懶，根本脫褲子放屁嘛！

C 或 Objective-C 的開發者也許已經想到使用讓人又愛又恨的 pointer 來解決，實際上，Apple 官方的 Framework 也常用 pointer 解決這種惱人事。例如：在一些 UIKit 的 delegate 中，不時看到被 **inout** 修飾（註三）的 function parameter，透過 pointer dereferencing 來修改並 write back 傳入的argument。

傳統 C 語言 function call 皆是 **call-by-value**，pointer 的使用實際上也只是透過傳遞 memory address 的 value 來模擬 **call-by-reference**。眾所周知，**Swift: Objective-C without the C**。在 Swift 這個階級分明、極不平等的世界裡，value type 統一是 **call-by-value**，而 reference type 則是 **call-by-reference**。可愛 pointer 的戲份因此被刪，僅留下修飾參數的 attribute：[inout][inout]。

Swift 的 **inout** 和 Objective-C 的功能不太一樣，一個被修飾的 Swift  in-out parameter 既非 call-by-value 也非 call-by-reference，而是俗稱 **copy-in copy-out** 的 **call-by-value-result**，可以參考蘋果官方的解釋：

> 1. When the function is called, the value of the argument is copied.  
> 2. In the body of the function, the copy is modified.  
> 3. When the function returns, the copy’s value is assigned to the original argument.

意思就是指：

> function call 之初，先 copy 一份給你褻玩，等 function return，再把 value assign 回去

於是 code 立馬修改成：

```swift
func then(_ block: (inout Self) -> Void) -> Self { // 1
  var copy = self
  block(&copy) // 2
  return copy
}
```

1. 使用 **inout** 修飾 closure 的參數。
2. 傳入 inout parameter，要加 `&` prefix（感覺還是很 C 啊）。

此後，value type 終於爭取到真平權，與 reference type 一樣，毫無違和地使用 `then` 了！

### [Generic Where Clauses][generic-where-clauses]

事情沒有這麼簡單，又有人發了 [issue][issue-25]，言下之意是 reference type 不需要 inout 修飾，作者你 value type reference type 共用同一個 method，我還要多打 inout 來修飾，這樣要怎麼教小孩？幸好，Swift 有提供 **Generic Where Clauses**（一種泛型條件限制），讓我們 overload 不同的型別的實作。請看 code：


```swift
extension Then where Self: Any { // 1
  public func with(_ block: (inout Self) -> Void) -> Self {
    var copy = self
    block(&copy)
    return copy
  }
}

extension Then where Self: AnyObject { // 2
  public func then(_ block: (Self) -> Void) -> Self {
    block(self)
    return self
  }
}
```

1. where clause 限制此 extension 僅作用在 Any 型別（如果是 Any 好像不用寫齁XD）。
2. where clause 限制此 extension 僅作用在 AnyObject 型別，也就是 reference type。

透過泛型的限制，我們成功隔離 value type 與 reference type 的不同需求。雖然仍無法爭取到真平權，但我們是 Swift 不是 Ruby，別把國外那一套拿來比較。至少現在 value type 透過 inout 修飾，可以獲得同樣的功能，只是多了幾道手續，我們還是很看好 value type 的！

## Summary

**Then** library 會受到如此多關注，大概是因為它夠「Swifty」吧，從第二個 [issue][issue-2] 就開始熱烈討論是否該將這個 syntax sugar propose 到 [Swift Evolution][swift-evolution]，作為下一版的新 Features，陸陸續續有類似想法的人就開始行動了（[mailing list][mailing-list] & [cascading issue][cascading-issue]），不難看出 Swift 社群有多麼活躍。我想，多多關注 [Swift Evolution][swift-evolution]，應該會有不少收穫！

## Reference

- [devxoul/Then][Then]
- [Apple Swift Documentation][swift-doc]
- [Stackoverflow: Is Swift Pass By Value or Pass By Reference][byval-byref]

> - 註一：Java 8 引進 [Default methods][java-default-methods]，interface 可以有自己的 implementations 。
> - 註二：在 Swift 3 之前 function argument 可以宣告為 `var`，但普遍認為實用性比 `inout` 低，且容易混淆，就[提案將 argument 改為常數 `let`][remove-var] 了。
> - 註三：實際上 Objective-C 的 inout 修飾只是在 compile 層會做優化，對 function 本身沒啥影響。


[Then]: https://github.com/devxoul/Then
[Then.swift]: https://github.com/devxoul/Then/blob/master/Sources/Then.swift
[protocol-extensions]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html#//apple_ref/doc/uid/TP40014097-CH25-ID521
[ACL]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AccessControl.html
[issue-16]: https://github.com/devxoul/Then/issues/16
[generic-where-clauses]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GenericParametersAndArguments.html#//apple_ref/doc/uid/TP40014097-CH37-ID406
[issue-25]: https://github.com/devxoul/Then/issues/25
[issue-2]: https://github.com/devxoul/Then/issues/2
[swift-evolution]: https://github.com/apple/swift-evolution
[mailing-list]: https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20151228/005122.html
[cascading-issue]: https://bugs.swift.org/browse/SR-160
[inout]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Declarations.html#//apple_ref/doc/uid/TP40014097-CH34-ID545
[java-default-methods]: https://docs.oracle.com/javase/tutorial/java/IandI/defaultmethods.html
[remove-var]: https://github.com/apple/swift-evolution/blob/master/proposals/0003-remove-var-parameters.md
[swift-doc]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/
[byval-byref]: http://stackoverflow.com/questions/27364117/is-swift-pass-by-value-or-pass-by-reference
