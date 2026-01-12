---
title: 理解 Swift Generics
tags:
  - Swift
  - Generics
date: 2017-05-08T22:28:09+08:00
---

![](https://i.imgur.com/xuMiBGM.webp)

**泛型程式設計（Generic Programming）** 是經典的程式設計典範之一，不論是老牌的 **C++**，還是潮潮的 **TypeScript**，都能一睹**泛型**的風采。近年來，程式設計吹的是 **static typing** 風，泛型又開始被廣泛討論。

本篇將簡單介紹泛型的背景，再來理解並學習 Swift 語言的泛型寫法。

_（撰於 2017-05-08，基於 Swift 3.1）_

<!-- more -->

## Definition

想像一下，有個需求是要交換兩個變數儲存的值，現在欲交換的變數是 `int` type，因此實作了 `void swapInt(*int, *int)` 的函式；接下來要交換的是 `double`，又寫了 `void swapFloat(*double, *double)`，但兩個函式實作幾乎一樣（交換指標指向的值），如果還有 `float`、`char` 等其他 *n* 種 data types，就必須寫 *n* 個版本的實作。如果程式語言支援[函式重載][wiki-function-overloading]，可以把 function name 都改成 `swap`，降低函式調用端的複雜度，但依然沒解決重複的問題。

泛型程式設計（Generic Programming）目的就是「**消弭因為不同資料型態，而重複實作相同的演算法**」。[維基百科][wiki-generic-programming]寫得非常清楚：

> ... is a style of computer programming in which algorithms are written in terms of **types to-be-specified-later** that are then **instantiated when needed for specific types** provided as parameters

白話一點，就是「**延遲型別決定的時間點，再利用對程式碼的解析結果，到實例化該程式片段時，才決定實際的型別**」。

泛型本質上就是減少冗餘代碼，增加代碼重用，遵守「[DRY][wiki-dry]」的程式設計典範。有名的 C++ 的[標準模版庫（STL）][wiki-stl]就是利用 C++ `template` 模版泛型，定義 `map`、`vector`、`sort`、`binary_search` 等重要的資料結構與與演算法，讓這些演算法非常「generic」，泛用於各種 data types。

Swift 這個~~四處剽竊~~集大成的[多典範語言][wiki-multi-paradigm]，當然也少不了對泛型的支持。Standard Library 內的 `Array`、`Dictionary`、`Set` 等資料結構也支持不同 data types，而根據泛型化的對象不同，Swift 可分為 **Generic Functions** 與 **Generic Types**。接下來分別介紹兩者。

## Generic Functions

想像一下，有三種不同廠牌，功能外觀也非常不一樣的手機，隸屬不同 class，

```swift
class AppleIPhone7 {}
class SamsungNote7 {}
class AsusZenfone {}
```

有一個 `call(_:)` 函式，需傳入一個 `phone` 參數，才能開始打電話，但由於各廠牌差異過大，需要定義多個實作相同的函式，每支手機才可正常 call out，

```swift
func call(by phone: AppleIPhone7) {
  print("\(type(of: phone)) is calling")
}
func call(by phone: SamsungNote7) {
  print("\(type(of: phone)) is calling")
}
func call(by phone: AsusZenfone) {
  print("\(type(of: phone)) is calling")
}
```

透過 Generic Functions 可以將 `call(_:)` 改成支援任何 data types 的泛型版本，

```swift
func call<Phone>(by phone: Phone) {
  print("\(type(of: phone)) is calling")
}
```

跟在 function name 後的 `<Phone>` 就是 Swift 的泛型語法，角括號 `<>` 內的 `Phone` 是虛擬的 type，官方名稱為 **Type Parameters**。這個 `<Phone>` 泛型有幾個特性：

- 只是一個「**代名詞**」，不代表任何實際的型別。
- 直接寫在該宣告名稱的後面（例如 function name 之後）。
- 在該宣告的 body 中，可自由運用該泛型型別，例如傳入其他 function，或當作 return type。
- 在可以確定實際調用的型別後，虛擬的泛型型別將會被真實型別取代。

> 泛型就是一個把**代名詞換成已知名詞的概念**，交由 compiler 代勞罷了。

<!--  -->

> Type Parameter 可使用任意的合法 identifier，常見如 `<T>`、`<U>`，或是與語彙環境有關，如 generic collection protocol 就用 `<Element>`，慣例會用大寫開頭，表示是一個 type，而非 value。

## Generic Types

除了 function 以外，Swift 的 first class citizens（struct、enum、class）、**initializers**，以及 **typelias** 都支援泛型宣告功能，這裡直接使用官方的 `Stack` 例子：

```swift
struct Stack<Element> {                   // 1
  var items = [Element]()                 // 2
  mutating func push(_ item: Element) {   // 3
    items.append(item)
  }
  mutating func pop() -> Element {        // 4
    return items.removeLast()
  }
}
```

範例宣告了一個 `Stack` struct，帶有一個 type parameter「**Element**」（1），Element 這個虛擬的 type 可以在 struct 內部盡情使用。在（2）（3）（4） 就分別用來當作

- Array 儲存的資料型別
- 函式的參數型別
- 函式的 return type

定義完成後，若希望使用 `Stack` 這個 generic type 時，我們必須明確告訴 compiler 這個 `Stack` instance 會儲存何種型別，寫法如下：

```swift
var stack0 = Stack<String>()
// or
var stack1: Stack<String> = Stack()
```

當 generic type 被實例化，會稱該實例的泛型宣告（如本例的 `<String>`）為 **Type Arguments**，如同一般函式帶入引數的概念，原本虛擬的 type parameter 的 placeholder，將完全被 type argument 取代。此即 Generic Types 的用法，與 Generic Functions 如出一轍。

> 在不使用 literal 的狀況下，實例化 Generic Types 的語法與實例化 Array／Dictionary 一樣，畢竟 Array／Dictionary 也是內建的 generic types。

## Type Constraints

有時候，演算法可能需要傳入的型別有實作特定方法，泛型可以透過設置 **Type Constraints**，確保傳入型別符合需求，簡單的範例如下：

```swift
func myFunction<T: SomeClass, U: SomeProtocol>(someT: T, someU: U) {
  // Here is function body
}
```

上例中有兩處新語法：

- 宣告多個 type parameters 時，parameters 間使用 `,` 分隔。
- 泛型型別名稱後，添加 `: SomeClass`、`: SomeProtocol`，代表 `T` 的實際型別必須繼承 `SomeClass`，`U` 的實際型別則需遵循 `SomeProtocol`。

回過頭，看最初手機廠牌的範例，我們為每個廠牌加上一點特性。

```swift
protocol Chargeable {}          // 可充電的
protocol HeadphoneJack {}     // 有 Headphone Jack 的

extension AppleIPhone7: Chargeable {}
extension SamsungNote7: HeadphoneJack {}
extension AsusZenfone: Chargeable, HeadphoneJack {}
```

再定義三個 generic functions，但每個 functions 都有相對應的 type constraints，確保傳入的型別符合要求。

```swift
func charge<Phone: Chargeable>(phone: Phone) {
  print("\(type(of: phone)) is charging")
}

func listenMusic<Phone: HeadphoneJack>(phone: Phone) {
  print("Listen music with \(type(of: phone))")
}

func listenMusicWhileCharging<Phone: Chargeable & HeadphoneJack>(phone: Phone) {
  print("Listen music with \(type(of: phone)) while charging")
}
```

> `listenMusicWhileCharging(_:)` 的 type constraint 為`Chargeable & HeadphoneJack`，為 [protocol composition][swift-protocol-composition]，是合法的 type constraint。

最後將手機實例化，並分別帶入所有 functions，

```swift
let iphone7 = AppleIPhone7()
let note7 = SamsungNote7()
let zenfone = AsusZenfone()

charge(phone: zenfone)
charge(phone: iphone7)
charge(phone: note7)

listenMusic(phone: zenfone)
listenMusic(phone: iphone7)
listenMusic(phone: note7)

listenMusicWhileCharging(phone: zenfone)
listenMusicWhileCharging(phone: iphone7)
listenMusicWhileCharging(phone: note7)
```

最後應該會編譯失敗，因為 `AppleIPhone7` 與 `SamsungNote7` 分別沒有實作 `HeadphoneJack` 與 `chargeable`，兩者的 instances 當然無法帶入不符合 **type constraints** 的 functions。

## Generic Parameter Clause

到此，我們來看看泛型宣告的完整語法。

依照 Swift 官方說詞，泛型的宣告叫做 [Generic Parameter Clause][swift-generic-parameter-clause]，是由角括號 `<>` 將 Generic Parameter 包裹起來，若有多個 parameters，則以 `,`（comma-separated）分隔。

```swift
<GenericA, GenericB, GenericC>
```

而每個 Generic Parameters 除了虛擬 type name（官方：**Type Parameter**），還可有 optional 的 **Type Constraints**。

最後，Generic Parameter Clause 語法大致會像這樣：

```swift
<GenericA, GenericB: SomeClass, GenericC: SomeProtocol>
```

> Generic Parameter Clause 用在宣告型別，若對應泛型實例化，有 [Generic Argument Clause][swift-generic-argument-clause]，例如建構 Dictionary：`let a = Dictionary<String, [Double]>()`。將指定的實際型別帶入對應位置即可。


## Associated Types

在 **Generic Types** 一節，我們提到 Swift 所有一等公民、**typealias**，以及 initializers 都可以利用 Generic Parameter Clauses 宣告泛型。那 **protocols** 呢？我們可以嘗試看看。

```
protocol Test<T> {}
// error: protocols do not allow generic parameters; use associated types instead
```

結果 Swift 不允許 protocol 使用我們熟悉的泛型宣告，而是引入另一個關鍵字 [associatedtype][swift-associatedtype]。我們可以把 `associatedtype`，想像成 protocol 版的 generics，其有幾點特性：

- 使用完整的繼承寫法，如 `associatedtype MyType: MyClass, MyProtocol, AnotherProtocol`。
- 可透過 `Self` access **associated type**。
- 承上，因此實際上是一個 **nested type** 的 protocol requirements。

> 有關為何捨棄 type parameterization，而特別設計 `associatedtype` 作為 protocol 的泛型，可參考[這篇文章][associatedtype-why]、[這個 Pokemon 範例][associatedtype-pokemon]，和[這個 stackoverflow 回答][stackoverflow-associatedtype-why]。

接下來，藉由幾個重要的 protocol 來理解 `associatedtype`。首先，我們來看 [IteratorProtocol][swiftdoc-iteratorprotocol]。**IteratorProtocol** 是一切集合、容器、迴圈最基礎 protocol。擷取定義如下：

```swift
public protocol IteratorProtocol {

  associatedtype Element                        // 1

  public mutating func next() -> Self.Element?  // 2, 3
}
```

1. 宣告一個泛型 associated type `Element`。
2. 必須實作 `next()` 方法，返回一個 **Optional** 的 `Element`。
3. 繼承 `IteratorProtocol` 型別，必須有 `Element` 這個 nested type，才能存取 `Self.Element`。

再來，就可以實作一個無限迴圈的 `ForeverIterator`，並利用 Swift 的 Type Inference，自動判斷 `Element` 這個 associated type 實際的型別。

```swift
struct ForeverIterator: IteratorProtocol {
  func next() -> Bool? { // 從 declaration 推斷 Element 的實際型別
    return true
  }
}
```

我們也可以利用 `typealias` 顯式宣告 `Element` 的實際型別。讓該型別完成 nested type 的 requirement。

```swift
struct ForeverIterator: IteratorProtocol {
  typealias Element = Bool // 完成 nested type `Element` 的 requirement
  func next() -> Bool? {
    return true
  }
}
```

這樣就完成一個無限迴圈的 Iterator 了。

```swift
import Foundation

let it = ForeverIterator()

while let flag = it.next(), flag {
    Thread.sleep(forTimeInterval: 1)
    print(Date())
}
```

`associatedtype` 除了提供 protocol 相關的 generic type 之外，也可以直接提供 Default 的 type。簡單範例如下：

```swift
protocol GotDefaultAssociatedType {
  associatedtype SomeType = Double     // 提供 default type `Double`
}

struct SomeStruct: GotDefaultAssociatedType {   
  // 不需要宣告任何 typealias 或是實際的型別，就可以正確執行 `multiply(_:)`

  func multiply(x: SomeType) {
    print(x * x)
  }
}

SomeStruct().multiply(1.5)
// 2.25
```

看完上面的範例，可以了解 Associated Type 其實就是 protocol 版的 Generic Parameter Clause，彈性更大，可讀性更高，配合接下來的 **Generic Where Clauses**，更能展現 Associated Type 的強大。

## Generic Where Clauses

在 Type Constraints  一節，提到使用 Type Constraints 限制傳入的型別，Swift 的泛型也有另外一個可讀性、彈性更高，更接近自然語言的 syntax —— [Generic Where Clauses][swift-generic-where-clause]。以下兩種寫法等價：

```swift
func lessThan<T: Comparable>(x: T, y: T) -> Bool {
  return x < y
}
// is equivalent to
func lessThan<T>(x: T, y: T) -> Bool where T: Comparable  {
  return x < y
}

lessThan(123, 1234)
```

某些情境下，需確認「兩個泛型引數為相同型別」，才能進行操作，例如比較兩個 Sequence 是否完全一樣，可如下宣告：

```swift
// 在兩個 Sequence 擁有相同 Element 才能執行的 function
func someFunc<S1: Sequence, S2: Sequence>(s1: S1, s2: S2) where S1.Iterator.Element == S2.Iterator.Element, S1.Iterator.Element: Comparable {
  // skip the implementation
}
```

從上兩例中，我們可以理解 **Generic Where Clause** 相關特性如下：

- 必定放在 declaration body `{}` 之前。
- 接受 requirements，多個 requirements 以 `,` 分隔。

在前例中，我們也看到了 `S1.Iterator.Element` 這個奇怪的傢伙，這其實源自於 `Sequence` 的 `associatedtype`

```swift
public protocol Sequence {

  associatedtype Iterator : IteratorProtocol

  public func makeIterator() -> Self.Iterator

  // other implementations ...
}
```

也是因為透過 `associatedtype` 的 nested type 特性，我們才能存取到 Sequence 的 Iterator 下的 **Element** `associatedtype`。再配合 **Generic Where Clause**，能夠更靈活運用 Swift 強大的 Generics。

> 我們知道 Swift for-loop 可以用 [where clause][swift-where-clause] 做進一步的判斷來 filter elements，而本節介紹的 [Generic Where Clauses][swift-generic-where-clause] 則是針對泛型的宣告使用，別搞混了。

## Some Thoughts of Generics

靜態定型（Static typing）與動態定型（Dynamic typing）是程式語言的兩大陣營。動態定型的語言強調彈性與可讀性，靜態定型的語言卻堅持宣告需清楚完整。而泛型程式設計的興起，讓靜態定型語言可以更靈活的設計與實作，卻讓宣告式變得又臭又長。

學習泛型語法要花不少精力，讓語言支援泛型更是一大工程。Go 語言的泛型至少從 [2011][go-proposal-generics] 吵到[現在][go-generics-issue]，居然還沒個影子，大家還是趕快去學 [Rust][rust] 吧XDD

## Reference

- [Swift Language Guide - Generics][swift-generics]
- [SwiftDoc.org](http://swiftdoc.org/)
- [Wiki: Generic Programming][wiki-generic-programming]

[swift-generics]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Generics.html
[swift-protocol-composition]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html#//apple_ref/doc/uid/TP40014097-CH25-ID282
[swift-generic-parameter-clause]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GenericParametersAndArguments.html#//apple_ref/swift/grammar/generic-parameter-clause
[swift-generic-argument-clause]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GenericParametersAndArguments.html#//apple_ref/swift/grammar/generic-argument-clause
[swift-associatedtype]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Declarations.html#//apple_ref/doc/uid/TP40014097-CH34-ID374
[swift-where-clause]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Statements.html#//apple_ref/swift/grammar/where-clause
[swift-generic-where-clause]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/GenericParametersAndArguments.html#//apple_ref/swift/grammar/generic-where-clause

[wiki-generic-programming]: https://en.wikipedia.org/wiki/Generic_programming
[wiki-function-overloading]: https://en.wikipedia.org/wiki/Function_overloading
[wiki-dry]: https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[wiki-stl]: https://en.wikipedia.org/wiki/Standard_Template_Library
[wiki-multi-paradigm]: https://en.wikipedia.org/wiki/Programming_paradigm#Multi-paradigm

[swiftdoc-sequence]: http://swiftdoc.org/v3.1/protocol/Sequence/
[swiftdoc-iteratorprotocol]: http://swiftdoc.org/v3.1/protocol/IteratorProtocol/

[github-swift-algorithm-club]: https://github.com/raywenderlich/swift-algorithm-club
[associatedtype-why]: http://www.russbishop.net/swift-why-associated-types
[associatedtype-pokemon]: https://www.natashatherobot.com/swift-what-are-protocols-with-associated-types/
[stackoverflow-associatedtype-why]: https://www.stackoverflow.com/a/26555177

[go-proposal-generics]: https://github.com/golang/proposal/blob/master/design/15292-generics.md
[go-generics-issue]: https://github.com/golang/go/issues/15292

[rust]: https://www.rust-lang.org
