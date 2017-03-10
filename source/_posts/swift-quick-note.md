---
title: Swift Quick Note
date: 2017-02-06 23:25:19
tags:
  - swift
---

簡單記錄 Apple 官方 Swift Guide 的重點與心得。

_（撰於 2017-02-06，基於 Swift 3.1）_

<!-- more -->

---

# Declaration

宣告變數使用 `var`，宣告常數使用 `let`

- 使用 `var` 宣告，該值為 mutable
- 使用 `let` 宣告，該值為 immutable

```swift
let myConst = "constant"
var myVar = 1234
myVar = 5678
```

> 慣例是都先使用 `let` 宣告，等到之後需求或 compiler 報錯時，再修正為 mutable 的 `var`

## Type Inference

自動透過賦予的值推斷型別，也可以顯式聲明型別。

```swift
let doubleValue = 70.0 // Double type
let myStr: String
myStr = "1234"
```
## Type Safety

Swift 是一個非常嚴謹的語言，注重型別安全（Type Safety）

- 宣告常數、變數時必須賦值或聲明顯示型別
- 常數、變數使用前必須給定初始值
- 型別無法任意轉換，必須顯式指定型別轉換。

# Fundamental data type

Swift Standard Library 定義了許多基本型別：

## Integer/Unsigned Integer, Double, Float

```swift
let myInt = 1234 // integer
let myInt8: Int8 = 1234 // 8-bit integer
let myUInt: UInt = 1234 // unsigned integer

let myDouble = 1234.0 // double
let anotherDouble: Double = 123 // double
let myFloat: Float = 123.0
```

## Boolean

布林值不再用 `YES` `NO`，改為 `true` `false`

```swift
let myBoolean = true
let myFalse: Bool = false
```

## String

是字元集合（但非 Array 這種 collection type）

```swift
let myStr = "hello, world"
let anotherStr: String = "hello, swift"

print(myStr.hasPrefix('hello'))
// true
```
> Swift 字串不僅是簡單的字元集合，有許多針對 Unicode support 與 橋接 NSString 的設計，但由於不太方便調用，預計 [Swift 4 會大幅修正](https://github.com/apple/swift/blob/master/docs/StringManifesto.md)

## Array/Dictionary

最常用的兩種 collection type，字面量使用 `[]` 將值包裹，`Dictionary` 使用 `key: value` 表示。

```swift
var array = [1, 2, 3, 4]
print(array[2]) // 2
array[2] = 3
print(array[2]) // 3

var dict = ["A": 1, "B": 2]
print(dict["A"]) // 1
dict["A"] = 5
print(dict["A"]) // 5
```

> 除了這些基本型別，`import Foundation` 後也可以使用諸如 `NSString`、`NSArray` 這類 Foundation Object。不過 Swift 與 Objective-C 橋接做得很好，建議能用 Stdlib 解決就不要用 Foundation Object。

# Operator

Swift 的 運算子大多都與 C/Objective-C 雷同。
值得一提的是，所有運算子都是在 standard library 中以 function 的形式宣告。

> `i++` `++i` 這種 prefix/postfix increment 在 Swift 3 之後完全移除了

## `===` operator

Swift 中新增的運算子，用來比較 reference type 指向的實例（比較 memory address）是否相同。功能等同 Objective-C 的 `[NSObject isEqual:]`。

## Type checking/casting

- is：檢查實例是否為特定子類別
- as：將實例轉型為其他相關子類別
  - as?：轉型失敗回傳 nil
  - as!：強迫轉型（不建議使用）
- as 也可以和 value-binding 搭配服用

```swift
let myInt: Int = 10

myInt is Int // true
myInt as? String // nil

// value-binding 搶先看 -----------

func testType(_ variable: Any) {
    switch variable {
    case let variable as Double:
        print("Double \(variable)")
    case let variable as Int:
        print("Int \(variable)")
    case let variable as String:
        print("String \(variable)")
    default:
        print("Unknown Type")
    }
}

let a: Any = 10
let b: Any = String(10)
let c: Array = [1, 2, 3, 4]

testType(a)
testType(b)
testType(c)

// Int 10
// String 10
// Unknown Type
```

# Control Flow

與 C/Objective-C 的共通點：

- 大多數寫法類似
- statements 內宣告的變數生命週期只在該 code block 內，不污染 outer scope

## if/else

- condition 可省略 `()`（主流 coding style 會省略）
- 無論 statement 有幾行，都一定要用 `{}` 包裹起來。

```swift
let a = 6

if (a > 5) print(a) // compile error

if a > 5 { print(a) }

if a > 5 {
  // true go here
} else {
  // false go here
}
```

## for

- 使用 `for ... in` 的寫法
- condition **不可以加上** `()`
- 無論 statement 有幾行，都一定要用 `{}` 包裹起來。

```swift
let abcd = ["A", "B", "C", "D"]
for i in abcd {
  print(i)
}
```

Swift 3 後，無法使用傳統 C style for loop `for (int i = 0; i < 5; i++)`，若需取得 index，可以：

- 使用 `enumerated` 方法。
- 使用 `Range Operator` 產生 `Range` Object (不推薦，容易 out of range)

```swift
let abcd = ["A", "B", "C", "D"]
for (idx, val) in abcd.enumerated() {
  print(idx, val)
}

for val in 0..<abcd.count {
    print(val)
}
```

## while/repeat-while

- condition 可省略 `()`（主流 coding style 會省略）
- 無論 statement 有幾行，都一定要用 `{}` 包裹起來。

> `repeat...while` 等同於 C 的 `do...while`

```swift
var i = 0

while i < 5 {
  print(i)
  i += 1
}

i = 0

repeat {
  print(i)
  i += 1
} while i < 5
```

## switch

- condition 可省略 `()`（主流 coding style 會省略）
- 可以比對許多不同的型別，不限制於 character 或 integer
- 預設每個 case 會自動 break，不需加上 `break`
- case statements 不需要加上 `{}`
- 如不加 `default` case，**需枚舉所有 case**，否則 compiler 會 murmur
- 如需 C style 的 statements fall through，請加 `fallthrough`
- 配合 **pattern matching** 可以玩很多花樣

```swift
let number = "A"
switch aString {
case "A":
  print("Got")
case "B":
  print("Got B")
  fallthrough
default:
  print("Got B with fallthrough")
}
```

Pattern matching 搶先看（with value-binding）

```swift
let point = (1, 0)

switch point {
case (_, 0):
  print("on x axis")
case (0, _):
  print("on y axis")
case (0, 0):
  print("at origin")
case let (x, y):
  print("point at (\(x), \(y))")
}
```

## guard-else

- 用途：檢查是否符合 requirement，用於 Early Exit（作用類似 `if (!...) return`）
- guard 的 condition 為 requirement，與 `if` 相反
- 須與 `else` 搭配，該 `else` 內必須有轉換 control flow 的動作，如 `break`、`return`等
- 與 optional binding 搭配，可以節省寶貴的 indentation
- 慣例寫在該 code block 的最頂層

```swift
let aNil: Int? = 5
guard true else {
  fatalError("you won't fail here")
}

// optional-binding
guard let integer = aNil else {
  fatalError("you won't fail here")
}

print(integer) // no need to wrap the optional

guard int < 5 else {
  fatalError("you failed")
}
```

> 由於 `guard` 關鍵字用在 Early exit，`else` clause 裡不應有太複雜的邏輯


## defer

- 用途：在該 code block 返回之前，執行 `defer` 的動作
- 若有多個 `defer`，以相反方向執行（由下而上）
- 類似其他語言 try-catch-finally 的 finally
- 慣例寫在該 code block 的最頂層

```swift
func f() {
  defer { print("Last") }
  defer { print("Third") }
  defer { print("Second") }
  print("First")
}
```

> 個人認為 `defer` 本身執行順序相反，比較不推薦使用多個 defer，會減少 readability

# Type system

Swift 除了 builtin types 以外，還有許多方式可以宣告 custom type，介紹常見的幾種

- value types
  - enum
  - struct
- reference types
  - class
  - function
- others
  - tuple
  - protocol
  - extension

Swift 中，struct、enum、function 皆與 class 一樣是 [first-class citizen][first-class_citizen]，可以賦值、 作為 function 參數或 function 的返回值。

## Value Type V.S. Reference Type

Swift 的世界中，把 type 分為 value type 與 reference type，和 Objective-C 萬物皆繼承 `NSObject` 很不一樣。

|Behavior      |Value Type    |Reference Type                    |
|--------------|--------------|----------------------------------|
|copy          |複製一份 copy  |分享同一份 value（複製新的reference） |
|function call |call by value |call by reference                 |
|修改屬性的method|inhibited (func 需用 mutating 修飾）|allowed      |

簡而言之 value type 賦值到新的 variable 時，會複製整個實例；reference type 則只會指向同一個實例。

如果 value type 的 method 需要改變自己的 property 時，該 method 需要使用 `mutating` 修飾。

```swift
// Value Type ----------
let array1 = [1, 2, 3]
var array2 =  array1
array2[0] = 4

print(array1) // still the same value
// [1, 2, 3]

print(array2) // copied and modified
// [4, 2, 3]

// Reference Type -------
class MyClass {
  var prop = 1
}

let instance1 = MyClass()
var instance2 = instance1 // a new reference to instance1
instance2.prop = 2

print(instance1)
// 2
print(instance2)
// 2

print(instance1 === instance2)
// true
```

慣例上，在需求允許的情況，推薦使用 value type（struct、enum）創建新的型別，在 assign/copy 時不會造成太多 side effect。例如在與 database 溝通等 object mapping 的情境下。

> 小提醒：Stdlib 的 Array/Dictionary 皆為 value type

# Class

## Declaration

class 的宣告方式和大多數程式語言相似

```swift
class MyClass {
  // ...
}
```

繼承其他 class 或 protocol 則在 classname 後加上 `: MySuperClass`

```swift
class MySubClass: MyClass {
  // ...
}
```

Swift 的 class 依然不允許多重繼承，但可以繼承多個 **protocol**，以 `,` 分隔不同的繼承來源。
```swift
class AnotherSubClass: MyClass, MyProtocol, AnotherProtocol {
  // ...
}
```

## Properties

class 的 property 分為兩種

- Stored Property
- Computed Property

### Stored Property

getter／setter 就是 property 本身

```swift
class Rect {
  var width = 10
  var height = 20
}

let rect = Rect()
rect.width = 20
print(rect.width)
```

### Computed Property

- getter／setter 透過計算得來
- setter 透過 `newValue` 變數取得新值
- 只有 getter 時，可以直接 return 該值（Objective-C readonly property）

```swift
class Rect {
  var width = 10
  var height = 20

  var x = 0
  var y = 0

  var centerX: Int {
    get {
      return x + width / 2
    }
    set {
      x = newValue - width / 2
    }
  }

  var area: Int { // readonly
    return width * height
  }
}
```

### Property Observers

- property willSet/didSet 時做對應的動作
- 可取代部分 Objective-C 的 key-value Observing 的功能
- willSet 可以從 `newValue` 變數取得新值
- didSet 可以從 `oldValue` 變數取得舊值

```swift
class PropObserve {
  var aVar: Int = 0 {
    willSet {
      print("New Value: \(newValue)")
    }
    didSet {
      print("Old Value: \(oldValue)")
    }
  }
}
```

## Initialization

- Designated initializer： 完全初始化所有 stored property 的 initializer
- Designated initializer： 皆須調用 superclass 的 designated initializer
- Convenience initiailzer： 用 `convenience` 修飾，必須調用其他 initializer
- `convenience` init chain 的最末一個必須調用 self 的 designated initializer
- 利用 `required` 修飾詞來指定 subclass 必須實作的 initializer
- 底層與 Objective-C 同為 Two-Phase Initialization，但會賦予 stored property 實值而非 `nil`
- subclasses 在滿足下列條件之一，就會自動繼承 superclass 的 initis（**預設不繼承**）：
  1. subclass 沒有宣告任何 init -> 自動繼承所有 **designated init**
  2. subclass 實作所有 superclass 的 designated inits -> 自動繼承所有 **convenience init**

```swift

class MyClass: CustomStringConvertible {
    var a: Int
    var b: Int

    var description: String {
        return "\(a), \(b)"
    }

    init(a: Int, b: Int) {
        self.a = a
        self.b = b
    }
    required init(a: Int, b: Int, c: Int) {
        self.a = a * 5
        self.b = b * c
    }
    convenience init() {
        self.init(a: 0, b: 0)
    }
}

class SubClass: MyClass {
    override init(a: Int, b: Int) {
        super.init(a: a, b: b)
    }
    required init(a: Int, b: Int, c: Int) {
        super.init(a: a, b: b)
        self.a = 10
        self.b = 15
    }
}

let my = MyClass()
print("my: \(my)")

let my2 = MyClass(a: 1, b: 2, c: 3)
print("my2: \(my2)")


let sub = SubClass()
print("sub: \(sub)")
let sub2 = SubClass(a: 1, b: 2, c: 3)
print("sub2: \(sub2)")
let sub3 = SubClass(a: 1, b: 2)
print("sub3: \(sub3)")
```

# Struct

- 和 class 相似，但為 value type，且無法繼承
- Default Initializer 是 memberwise initializer（須賦值給所有 properties）
- mutating method: 改變自身 property

```swift
struct Origin {
  let x: Int
  let y: Int
}
let origin = Origin(x: 0, y: 1) // 提供 default init

struct Point {
  let x: Int
  let y: Int
  init() {
    self.x = 0
    self.y = 0
  }
  mutating func multiplyX(x: Int) {
    self.x *= x
  }
}

let point = Point(x: 0, y: 1)
// Error： custom init 會取代 default memberwise init
```

- **Extra**: inherit `OptionSet` protocol for `NS_OPTIONS` (不是用 enum)

```swift
public struct Direction: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let north = Direction(rawValue: 1 << 0)
    static let east = Direction(rawValue: 1 << 1)
    static let south = Direction(rawValue: 1 << 2)
    static let west = Direction(rawValue: 1 << 3)

    static let none: Direction = []
    static let all: Direction = [.north, .east, .south, .west]
}

let dir: Direction = [.north, .east]
```

# Enum

- 不需指定 rawValue
- 每個 case 都是被定義好的類型，不需害怕比對到 `0`（legacy Objective-C NS_ENUM issue）
- mutating method: 改變自身 properties 的值
- 很容易與 `switch` 配合
- Advance：可以宣告 indirect enum (recursive enum)

# Optional

Swift 中很神奇的 Optional，實際上就只是一個 enum，實作上大概長這樣

```swift
public enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}
```

## Unwrapping

- forced unwrapped：強迫解析／取值（不建議使用）
- implicit wrapped：自動解析／取值（Apple 官方用在 xib／storyboard 的 IBOutlet property）
- Nil-coalescing: 提供 Optional 一個 default value

```swift
let a: Int? = 10
let b: Int! = 10

print(a!)                 // print 需傳入非 optional 的型別，必須強迫解析
print(a ?? "This is nil") // a 若是 nil 則 print 出 "This is nil"
print(b)                  // b 已自動解析（不建議使用，除非完全確定不會取得 nil）
```

## Optional Chaining

- 在 optional 後加上 `?`，遇到 `nil` 停止，不會 crash（類似 Objective-C 對 nil msgSend）
- 可以 chaining protocol 的 optional method，不需要 `respondToSelector:` 檢查


```swift
let array: [Int]? = [1, 2, 3]
print(array?.count)
// 3
```

## Optional Binding

- 解析 optional 中的 value，有值則將其 binding 到 variable 上，不需再解析
- `if let`
- `case let`
- `guard let`

```swift
let x: Int? = 1000

if let x = x {
  print(x) // no need to unwrap
} else {
  // if x == nil goes here
}

if x != nil {
  print(x!) // Need a forced unwrapping. Unsafe.
}
```

# Tuple

- 輕巧的 container，除了儲存 value，沒有其他功能
- tuple elements 可以有 name
- tuple elements 可以是不同型別
- function 可利用 tuple 產生多個 return value
- 可與強大 pattern matching 配合

```swift
let voidTuple = ()

let tuple = (1, "A")
print(tuple.0, tuple.1)
// 1 A

let namedTuple = (a: "a", b: "b", "c")
print(namedTuple.a, namedTuple.b, namedTuple.2, namedTuple.0)
// a b c a
```

```swift
let point = (3, 5)
switch point {
  case (_, 0):
    print("on the x axis")
  case (0, _):
    print("on the y axis")
  case (0, 0):
    print("at origin")
  case let (x, y): // value-binding
    print("at (\(x), \(y))")
}
```

# Function & Method & Closure

- 皆是 reference type，型別為 parameter types + return type，類似 method signature。
- closure 可以利用 capture list 獲取外部變數，防止 retain cycle
- escaping closure：作為參數傳遞時，會延遲至 function return 後執行，逃出 function scope
- 預設 closure 作為 parameter 時為 @noescaing，escaping closure 需以 @escaping 特別修飾

```swift
// function witn 0 param, return an Int

func function1() -> Int {
}

// function with 2 params, return a closure with 1 param and return a String
func function2(x: Double, y: String) -> (Int) -> (String) {
    return { Int in
        return "a string"
    }
}

// closure with 2 params, no return value
let closure1 = { (a: Int, b: Int) in
    print(a, b)
}

// closure with explicit type declaration (implicit return & shorthand argument)
let closure2: (String, String) -> ([String: String]) = { [$0: $1] }
```


# Protocol

- 與 Objective-C 的 protocol 雷同
- 可以透過 `@objc optional` 修飾為 optional 的 requirement
- 可繼承，也可透過 extension 提供 default implementations

```swift
protocol Car {
    var tireCount: Int { get set }
    var isDriving: Bool { get }
    func drive()
}

// Optional 需要 import Foundation 才能利用 Objective-C 的 runtime 特性

import Foundation

@objc protocol Flyable {
    func fly()
    @objc optional func landing()
}
```

# Extension

- class/struct/enum 皆可宣告 extension
- protocol 的 extension 為該 protocol 的 default implementations
- 同一個 type 可以有多個 extesions
- extension 可以使用 `where` 來限制 extension 的範圍

```swift
import UIKIt

protocol SomeViewProtocol {}

extension SomeViewProtocol where Self: UIButton {
  // 作用在 UIButton 的 default implementations
}

extension SomeViewProtocol where Self: UILabel {
  // 作用在 UILabel 的 default implementations
}
```

# Access Control

- open/public: 公開
- internal: 模組層（預設的 ACL）
- fileprivate: 文件層
- private: 宣告層（class／struct 內部等）
- patial access control: setter 需要較高權限時（外部 readonly）
  - internal(set)
  - fileprivate(set)
  - private(set)

```swift
class MyClass {
  open func test() {}
  public private(set) var readonlyVar: Int = 0
}
```
> public 與 open 的差異在與 **subclassable**，open 可以在模組外 subclass，但 public 不能在模組外 subclass

# Ecosystem

- [SwiftLint](https://github.com/realm/SwiftLint): Coding style linter written in Swift
- [Carthage](https://github.com/Carthage/Carthage): Package Manager written in Swift
- [Jazzy](https://github.com/realm/jazzy): Swift documentation generator (written in Ruby)
- [Awesome-Swift](https://github.com/matteocrippa/awesome-swift): curated list for Swift library/fraemwork
- Server-side Swift
  - [Vapor](https://github.com/vapor/vapor): 最活躍的 web framework
  - [Perfect](https://github.com/PerfectlySoft/Perfect): 最多 Star 的 web framework
  - ...More
- functional/reactive programming
  - [RxSwift](https://github.com/ReactiveX/RxSwift): ReactiveX Community Support
  - [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa): Most Popular RX library


# Reference

- [Apple Swift Documentation][swift-doc]

[swift-doc]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/
[first-class_citizen]: https://en.wikipedia.org/wiki/First-class_citizen
