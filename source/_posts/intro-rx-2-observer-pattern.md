---
title: Intro Rx - 2. Observer Pattern
tags:
  - Design Patterns
  - Observer Pattern
  - Swift
  - ReactiveX
date: 2017-08-15 16:32:39
---

聽過 Reactive Programming 嗎？ReactiveX（Rx）是近來火紅的技術，帶動函數響應式程式設計的熱潮。本系列將從 Rx 最原始的概念解釋起，一步步認識 Rx 巧妙的設計理念。期盼讀完後，人人心中都能有 Reactive 的思維！

本篇介紹 Rx 另一個重要的基礎概念 **Observer pattern**。

_（撰於 2017-08-15，基於 Swift 3.1）_

<!-- more -->

## Definition

[觀察者模式（Observer pattern）][wiki-observer-pattern]定義出一對多的相依關係，一個目標物件（subject）負責管理所有相依的觀察者（observer），「當 subject 自身的狀態發生變化時，自動通知所有觀察者」。

## Application

Observer pattern 是一個非常泛用的設計模式，幾乎各種語言都有類似的設計。例 DOM Event 架構利用 `dispatchEvent` 及 `EventListener` 達成 observer pattern。Cocoa programming 有著名的 [Key-Value Observing][cocoa-kvo] 來觀察物件上特定 key 的 value 變化。

## Pros and Cons

- Pros
  - 只要介面符合，任何物件都可以是 Observer。
  - 可確認該狀態變化是由該 subject 通知，有較高的控制權。
  - 熱門且容易理解的設計模式。
- Cons
  - Subject 和 Observer 通常必須知道彼此之間的部分屬性，有較緊的耦合性。
  - Subject 管理所有 observer，容易因 reference cycle 產生 memory leak。
  - 部份實作並無法保證不同的 observer 接收到通知的時間順序。
  - 承上，因此 thread-safe 與 asynchronous 的 observer pattern 不容易實作。

## First attempt

Swift 中實作 observer pattern 非常容易，除了透過 Objective-C 傳統的 Key-value observing 以外，直觀的 **Property Observer** 是最好的實作方式了。以下示範 property observer 實作 observer pattern。

> 不示範 KVO 是因為 [Swift 4 KVC 又大改了][swift4-kvc]！這次 keyPath 不再是易出錯的 string，改為實實在在的 KeyPath 型別，期待一下吧。

首先，我們先建立一個 protocol，裡面有幾個 requirements，`willChange`、`didChange` 會在 subject 狀態變更時調用。由於需要獨立辨識每個的 observer，所以會是一個 class-only protocol，才能透過 `===` identity operator 比較 reference。

```swift
// 建立一個 protocol 給 observer 實作，subject 會呼叫
protocol PropertyObserver: AnyObject { // class-only
  func willChange(to newValue: Any?)
  func didChange(from oldValue: Any?)
}
```

再來，我們建立 `Subject` 型別，裡面有

- `observers` array，管理所有觀察者（需注意 memory leak，必要時可利用 weak reference wrapper）。
- 一個用來示範的 `name` property，實作 `willSet`、`didSet` 兩個 property observer，裡面分別調用 `PropertyObserver` 的 `willChange` 與 `didChange` 方法。
- `add` 與 `remove` 兩個對應的新增／移除 observer 的方法。

```swift
struct Subject {
  // 建立一個 observers array
  private var observers: [PropertyObserver] = []

  // 利用 Swift 自帶的 property observer，通知每個 observer
  var name: String = "empty" {
    willSet {
      observers.forEach { $0.willChange(to: newValue) }
    }
    didSet {
      observers.forEach { $0.didChange(from: oldValue) }
    }
  }

  // 新增 observer
  mutating func add(observer: PropertyObserver) {
    observers.append(observer)
  }

  // 移除 observer
  mutating func remove(observer: PropertyObserver) {
    observers = observers.filter { $0 !== observer }
  }
}
```

最後，我們實作 `Observer`。

```swift
class Observer: PropertyObserver {
  let name: String // Demo 用
  init(name: string) { self.name = name }
  func willChange(to newValue: Any?) {
    print("\(name) will change to \(newValue ?? "nil").")
  }
  func didChange(from oldValue: Any?) {
    print("\(name) did change from \(oldValue ?? "nil").")
  }
}
```

測試看看吧！

```swift
var subject = Subject()
var observerA = Observer(name: "A")
var observerB = Observer(name: "B")
subject.add(observer: observerA)
subject.add(observer: observerB)
subject.name = "1234"
print("---------- Remove observerA ----------")
subject.remove(observer: observerA)
subject.name = "4321"

/// A will change to 1234.
/// B will change to 1234.
/// A did change from empty.
/// B did change from empty.
/// ---------- Remove observerA ----------
/// B will change to 4321.
/// B did change from 1234.
```

以上的是非常簡單的 Observer pattern 實作，但也有許多缺陷，例如：

- 不易指定 property，互相都需要了解內部屬性。
- 僅能從 Subject 移除 observer，observer 無法主動停止觀察。
- 一定要建立完整的 Observer，才能觀察變化。

## Second attempt

根據上述缺點，我們可以從幾個面向加強：

- Subject 的 observer 可以是 closure，解耦 `willChange` 與 `didChange`。
- `Subject.add` 之後可回傳一個 `Disposable` 的物件，讓觀察者可以透過這個物件停止觀察。

首先，建立一個新的 `Disposable` protocol，包含 `dispose` method，可以自行停止觀察。

```swift
protocol Disposable {
  func dispose()
}
```

再來是新的 `Subject`，這邊比較多繁瑣的實作細節，主要實作：

- `observers` 改成兩個 `willChangeObservers`、`didChangeObservers` array，分別存放不同的觀察者。
- `Observer` 的型別改為 closure，讓調用者更易於使用。
- `observe` 要傳入欲觀察的對應 `ObservationType`。

```swift
class Subject {
  enum ObservationType {
    case willChange
    case didChange
  }
  typealias Observation = Int
  typealias Observer = (Any?) -> Void

  private static var id = 0
  private var willChangeObservers: [(Observation, Observer)] = []
  private var didChangeObservers: [(Observation, Observer)] = []

  var name: String = "empty" {
    willSet { willChangeObservers.forEach { $0.1(newValue) } }
    didSet { didChangeObservers.forEach { $0.1(oldValue) } }
  }

  func observe(type: ObservationType, with closure: @escaping Observer) -> ClosureDisposable {
    Subject.id += 1
    switch type {
    case .willChange: willChangeObservers.append((Subject.id, closure))
    case .didChange: didChangeObservers.append((Subject.id, closure))
    }
    return ClosureDisposable(owner: self, id: Subject.id, type: type)
  }

  func remove(observer: ClosureDisposable) {
    switch observer.type {
    case .willChange:
      if let index = willChangeObservers.index(where: { $0.0 == observer.id }) {
        willChangeObservers.remove(at: index)
      }
    case .didChange:
      if let index = didChangeObservers.index(where: { $0.0 == observer.id }) {
        didChangeObservers.remove(at: index)
      }
    }
  }
}
```

這裡實作前面的 `Disposable`，為了符合 `Subject` 的需求，我們暴露 `Observation` 與 `ObservationType` 給 `ClosureDisposable`。  
實務上，可再訂定更詳細的泛型，或直接將 Disposable 的實際型別定義在 `Subject` 的 nested class。

```swift
class ClosureDisposable: Disposable {
  private(set) weak var owner: Subject?
  let id: Subject.Observation
  let type: Subject.ObservationType
  init(owner: Subject, id: Subject.Observation, type: Subject.ObservationType) {
    self.owner = owner
    self.id = id
    self.type = type
  }
  func dispose() {
    owner?.remove(observer: self)
  }
}
```

最後，讓我們來看看結果吧！

```swift
var subject = Subject()

let observerA = subject.observe(type: .willChange) { val in
  print("A will change to \(val ?? "")")
}

let observerB = subject.observe(type: .willChange) { val in
  print("B will change to \(val ?? "")")
}

let observerC = subject.observe(type: .didChange) { val in
  print("C did change to \(val ?? "")")
}

subject.name = "1234"
print("---------- Remove observerB & C ----------")
// subject 移除觀察
subject.remove(observer: observerB)
// Observer 使用 dispose 主動停止觀察
observerC.dispose()
subject.name = "4321"

/// A will change to 1234
/// B will change to 1234
/// C did change to empty
/// ---------- Remove observerB & C ----------
/// A will change to 4321
```

這是我們的第二次嘗試，雖然仍有 `ClosureDisposable` 與 `Subject` 耦合性的問題，也暴露太多類別的細節。不過對比第一次，對外接口使用 closure 來綁定 subject，勉強稱得上乾淨利落。

## Pub-sub pattern

一些狀況下，若需要完全解耦合，或許 [Pub-sub pattern][wiki-pub-sub-pattern] 會比 observer pattern 更適合。

**Pub-sub pattern**（Publish-subscribe，訂閱／發佈模式）是一種訊息傳遞設計模式，概念是利用中介 message 做為 publisher（對應 subject）及 subscriber（對應 observer）的溝通橋樑，subscriber 只需訂閱特定 message，而 publisher 則僅負責發佈（broadcast）message。兩者耦合性低，可作為 observer pattern 替代品，但程式也容易變得更複雜。

實務上，Cocoa 的 `NSNotification` 是徹底實踐 pub-sub pattern 的範例；以高效著稱的 in-memory database [Redis][redis] 也有強大的 Pub／Sub 功能。此外，Modern web app 的狀態管理架構兩大陣營 [Redux][redux] 與 [MobX][mobx]，也可以視為 pub-sub pattern 與 observer pattern 的對抗。

## Conclusion

Swift 的 Property observer 讓實作 observer 的門檻降低了，很多有趣的實現，例如 Cocoa Bindings，在 iOS 上變得更簡潔更 Swifty。了解 observer pattern 與組件間的通訊運作原理，勢必能夠帶來更多不同的設計架構，Rx 就是如此孕育而生。

## Reference

- [Wiki: Observer pattern][wiki-observer-pattern]
- [Wiki: Publish-subscribe pattern][wiki-pub-sub-pattern]

[cocoa-kvo]: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html
[mobx]: https://mobx.js.org/
[redis]: https://redis.io/
[redux]: http://redux.js.org/
[swift4-kvc]: https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md
[wiki-observer-pattern]: https://en.wikipedia.org/wiki/Observer_pattern
[wiki-pub-sub-pattern]: https://en.wikipedia.org/wiki/Publish-subscribe_pattern
