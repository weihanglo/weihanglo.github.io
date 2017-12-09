---
title: 理解 Swift 的 Error Handling
date: 2017-04-10T16:36:33+08:00
tags:
  - Swift
  - Error Handling
---

![](http://npmawesome.com/wp-content/uploads/2014/08/Catch-All-The-Errors.png)

如何利用 **Swift** 的語言特性來處理例外？使用 **Optional** 是常見的做法。如果成功就返回 **value**，失敗則返回 `nil`，這種模式常用於簡單的狀況。然而，面對複雜的情況，例如網路請求，若只簡單返回 `nil`，調用者並無法得知是 **404**，抑或 **500**。為了解決這個問題，我們必須緊緊抱住[錯誤／例外處理][wiki-exception-handling]的大腿。

_（撰於 2017-04-10，基於 Swift 3.1）_

<!-- more -->

## Intro of Exception Handling

在開始介紹 Swift 例外處理之前，先來了解什麼是例外處理。維基百科道：

> ...is the process of responding to the occurrence, during computation, of exceptions – anomalous or exceptional conditions requiring special processing – often changing the normal flow of program execution.

簡單來說，就是某些例外狀況，需要特別的處理，這個處理過程就稱為**例外處理**，而這個處理常伴隨程式流程轉移改變。

寫習慣 C++／Objective-C 的同學，想必很排斥寫  **try-catch** 這種吃效能、又易出錯的例外處理，明明 **if...else** 就能打遍天下嘛！而喜歡 Python／Ruby 的朋友對 `raise` 和各種 Exceptions 一定不陌生，甚至 Python 底層的 iterator 都是用 `StopIteration` Exception 實作。依照各個程式語言的設計，例外處理大致分為兩類：

- 融入一般的 control flow（Python、Ruby 之流）
- 處理特殊、不正常的情況（C++、Objective-C、C# 等）

大多數程式語言，無論屬於哪一類，只要涉及例外處理，就可能出現[效能上的疑慮][stackoverflow-exception-perf]，很難避開 [Call Stack Unwinding][stack-unwinding] 的問題。能改善的方法之一，就是明確定義哪些 function 能拋出例外，哪些必須拋出例外，哪些錯誤不需要拋出，而是 programmer 自己應該要 handle 的。

要釐清這個問題，首先要定義錯誤，程式錯誤的範疇很廣，不同的狀況有不同的應對方式，大致上可以分為以下幾種類型：

- **Simple Errors**

  一些很明顯可能產生錯誤的操作，例如 type casting、parsing string to integer。這種錯誤通常很容易理解，不需要過多的描述，在 Swift 或其他語言中，一般返回 `nil`／`undefined`／`none` 等值。

  ```swift
  let result = Int("I am not an integer, and will return an Optional")
  ```

- **Logical Failures**

  由 programmer 產生的錯誤，我們給他一個可愛的暱稱「bug」。Swift 強大的編譯器會幫開發者檢查這些問題，減少 logical failures 的數量。

- **Recoverable Errors**

  導致此錯誤的原因複雜，但能夠合理預料的錯誤。例如**開啟檔案**，可能會有 **Permission Denied**、**File Not Found** 等不同的錯誤。這類的錯誤就是 **Exceptions Handling** 主要的目標。

## Swift Error Handling

Swift 在 2.0 版為了妥善處理錯誤，並避免影響效能，決定僅針對 **Recoverable Error** 引入 Error Handling 機制，其他系統底層／語言層的錯誤還是需要 programmer 自行避免。截至 3.1 版，相關的關鍵字如下：

- `do`
- `catch`
- `try`
- `throw`
- `throws`
- `rethrows`
- `defer`
- `Error`

Swift 的錯誤處理與主流設計大相逕庭，不幫 programmer 躲過自作孽的 **Login Failure**，不會 catch **index out of bound** 這類錯誤。實際上，Swift 的錯誤處理就只是[另一種 Return Type，與相關的 Syntax Sugar][andybargh-error-handling]。其[設計理念／特色][swift-20-error-handling]整理如下：

- 拋出錯誤之處需為顯式聲明。
- 函式必須顯式宣告它會**拋出錯誤**，讓 programmer 明確得知哪些程式該處理錯誤。
- 拋出錯誤的效能如同初始化並返回 **Error** 型別一樣簡單，不涉及 stack unwinding。

Swift 有四種方法處理 Error：

1. 轉拋／傳遞錯誤（error propagation）。
2. 使用 **do-catch** 陳述句處理。
3. 將 Error 轉為 **Optional Value**（`try?`）。
4. 停止錯誤傳遞（`try!`）

能被拋出的錯誤需繼承 `Error` protocol，在此先定義一個錯誤類型，爾後再介紹。

```swift
enum DRMError: Error {
    case timeout
    case invalidHeader
    case missingParam(String)
    case responseFailure(code: Int, message: Data)
}
```

### Propagating Errors

第一種處理方法：透過 **throwing function** 轉拋／傳遞錯誤。

任何一個 function、method 或 initializer 若要拋出錯誤，需在參數之後，Return Type 之前加上 `throws` 來宣告一個 **throwing function**，顯式聲明該函式的需要錯誤處理。並利用 `throw` 來拋出錯誤。我們可以利用這個特性，將錯誤轉拋／傳遞出去給外面的作用域。

```swift
func canThrowTimeout() throws { // 可以拋出錯誤
    throw DRMError.timeout
}

func isHeaderEmpty(header: [String: Any]) throws -> Bool { // 可以拋出錯誤
    guard header.count > 0 else { throw DRMError.invalidHeader }
    return true
}

// 這個函式會錯誤轉拋／傳遞出去，將錯誤處理責任轉移到調用它的作用域。
func throwPropagation() throws {
    throw DRMError.missingParam("pubkey")
    try canThrowTimeout()
}

try throwPropagation()
```

> 調用 **throwing function** 時，必須在該函式前使用 `try` 顯式調用，否則編譯不會過。
<!--  -->
> 我們可以把 `throw` 視為一種特殊的 `return`，專門用來返回一個 **Error** 實例。

### Using `do-catch`

第二種處理方法：使用 **do-catch** 來捕獲錯誤。

**do-catch** 就好比 Objective-C 的 `@try-@catch`，在 `do` 區塊內拋出的錯誤會被捕獲，並尋找對應的 `catch` 區塊來處理錯誤。用法如下：

```swift
do {
    try throwPropagation() // 只能從用 try 標註的 throwing function 捕獲錯誤
    // 若調用 `catchFromThis()` 這樣的函式，未使用 `try` 標註，
    // 錯誤無法被捕獲（實際上也沒辦法拋出 custom error）。
    // ...
} catch DRMError.timeout { // 使用 pattern matching 捕獲特定錯誤
    print("Oh No! Timeout!")
} catch DRMError.missingParam(let p) where p == "pubkey" { // pattern matching + generic where clause
    print("\(param) is missing.")
} catch { // 捕獲剩下的所有錯誤（類似 default），並 binding 到區域變數 `error`
    print("Unexpected Error")
}
```

範例中，看到了 `catch` 結合 Swift 強大的 **pattern matching** 來捕獲錯誤，並活用 **value binding** 獲取錯誤的詳細資訊。我們可以把 `catch` 看作 **switch-case** 來使用各種 Swift patterns 的奇技淫巧。唯一不同的是，**do-catch** 不需要枚舉所有可能拋出的錯誤，若有錯誤未被處理，它將會繼續傳遞到周遭的作用域。

### Converting to Optional

第三種處理法：利用 `try?` 將錯誤轉換成 Optional。

這種作法大家應該都很能理解，直接貼官方的例子：

```swift
func someThrowingFunction() throws -> Int {
    // ...
}

let x = try? someThrowingFunction() // `x` 是一個 Optional

let y: Int?
do {
    y = try someThrowingFunction() // 若無拋出錯誤，則將賦值給 `y`
} catch {
    y = nil
}
```

透過 `try?`，將 **throwing function** 的錯誤轉換成 Optional 後，理所當然可以使用 Optional 的所有特性，例如 **optional-binding**，例如官方的範例：

```swift
func fetchData() -> Data? {
    if let data = try? fetchDataFromDisk() { return data }
    if let data = try? fetchDataFromServer() { return data }
    return nil
}
```

### Stopping Propagation

第四種作法：使用 `try!` 停止錯誤繼續傳遞。

當你**非常有信心**錯誤不會發生，可以使用 `try!` 停止錯誤往下傳遞。

```swift
// 接續前一個例子
// `x` 是一個 Int，如果 someThrowingFunction 拋出錯誤，則會得到 runtime error。
let x = try! someThrowingFunction()
```

## Other Handling Keywords

到此，我們介紹了 `do`、`catch`、`try`、`throw`、`throws`，這裡接著介紹 `rethrows`、`defer` 與 `Error`。

### `rethrows` your Error

`rethrows` 這個關鍵字乍看很詭異，但它並非會再拋出錯誤，如果一個函式宣告為 `rethrows`，意指

> 這個 **rethrowing function** 只會在它的函式型別參數（function parameter）拋出錯誤時，才會拋出錯誤。

要宣告為 **rethrowing function**，必須符合幾個要素：

- 至少一個函式型別參數帶有 **throwing function** signature。
- 只能在 **do-catch** 的 `catch` 語句中使用 `throw` 拋出錯誤。
- `do` 語句中只能處理作為參數的 **throwing function** 拋出的錯誤。

簡單的範例如下：

```swift
func rethrowFunction(callback: () throws -> Void) rethrows {
    try callback()
}

try rethrowFunction {
  throw DRMError.timeout
}
```

我們可以看到，許多與函數式程式設計相關 methods，都有帶 `rethrows` 的 signatures，例如 `Collection` 的 `map()` 與 `index(where:)`，讓處理集合時，可以將錯誤傳遞到正確的作用域。

```swift
public protocol Collection : Sequence {
  public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T]

  public func index(where predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Index?
}
```

### `defer` Your Finally

相信熟悉其他語言的童鞋，一定在想「我的 **try-catch-finally** 的 `finally` 呢？」，先前說過，Swift 的 error handling 只是一些甜死人的語法糖，官方並沒有特別為這個 model 增添關鍵字，而是使用大家已知的 `defer`，不懂的趕快[點這裡][swift-defer]惡補一下。

這裡寫段開檔的 pseudo code 給大家瞧瞧：

```swift
func handle(fileError error: FileError) {
  switch error {
  case .notFound: print("File not found.")
  case .permissionDenied: print("Permission denied")
  default: print("Unknown error occurred.")
  }
}

func writeTo(file: File, data: Data) {
    defer { close(file) } // 在這個 code block 結束之前執行

    do {
        try openFile(file)
    } catch let error as FileError {
        handle(fileError: error)
    } catch _ { // wildcard pattern without binding error value to error
        print("This is not a FileError.")
    }
}
```

### Customize Your `Error`

一開始，我們實現了一個 `DRMError` 繼承了 `Error`，讓我們自定義的錯誤能夠正確拋出。那這個 `Error` protocol 究竟葫蘆裡買啥藥？很驚人地，`Error` 是個 empty protocol，沒有任何實現，可說是名副其實的語法糖。

```swift
public protocol Error {
}

extension Error {
}

extension Error where Self.RawValue : SignedInteger {
}

extension Error where Self.RawValue : UnsignedInteger {
}
```

由於 **do-catch** 和 Swift patterns 緊密結合，官方推薦使用 `enum` 客製化我們自己的 Error Type。當有特殊需求，例如 Errors 間有共享的 state 或 data 時，也可用如 `struct` 來實現自定義 Error，舉個官方的 XML Parsing 例子：

```swift
struct XMLParsingError: Error {
   enum ErrorKind {
       case invalidCharacter
       case mismatchedTag
       case internalError
   }

   let line: Int
   let column: Int
   let kind: ErrorKind
}

func parse(_ source: String) throws -> XMLDoc {
   // ...
   throw XMLParsingError(line: 19, column: 5, kind: .mismatchedTag)
}

do {
   let xmlDoc = try parse(myXMLData)
} catch let e as XMLParsingError {
   print("Parsing error: \(e.kind) [\(e.line):\(e.column)]")
} catch {
   print("Other error: \(error)")
}
```

上例可清楚呈現解析 XML 時，Error 共享類似的 states。Swift Error Protocol 設計地非常有彈性。

## Notices and Future

Swift 的 Error Handling 設計得很現代很 functional，也讓錯誤處理不再只存在於醜陋的 code 或是不齊全的 document 中，而是提升至語言層面加以約束、保障。同時，仍有幾點需要注意、了解：

- `throws` 關鍵字是 function type 的一部分，而 non-throwing function 是 throwing function 的 subtype，所以可以在任何宣告 throwing function 處使用 non-throwing。
- 承上，non-throwing method 可以 override throwing method，**反之則否**。
- `throw` 的功能類似 `return`，對 asynchronous operation 不夠友善，因此許多人 porting 等其他語言的 `Promise`/`Future` 的特性，來彌補異步錯誤處理的不足。比較知名的庫有 [PromiseKit][promisekit] 等（想學習 `Promise` 概念，可參考[這個連結][google-promise]）。

如果未來，語言層級的平行運算（並行運算）就像[這篇文章][swift-concurrency]所說的，會在 Swift 5 推出；如果之後 `async`／`await` 如同 **ES7** 一樣納入 Swift 標準，如果 actor system 真的導入 Swift 中，天知道兩年後 Swift 寫起來會有多舒服！

## Reference

- [Swift Language Guide - Error Handling][swift-error-handling]
- [Wiki - Exception Handling][wiki-exception-handling]
- [Error Handling in Swift 2.0][swift-20-error-handling]
- [Andy Bargh - Error Handling in Swift][andybargh-error-handling]

[swift-error-handling]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/ErrorHandling.html
[wiki-exception-handling]: https://en.wikipedia.org/wiki/Exception_handling
[swift-20-error-handling]: https://github.com/apple/swift/blob/master/docs/ErrorHandling.rst
[stackoverflow-exception-perf]: http://stackoverflow.com/search?tab=relevance&q=exception%20performance
[stack-unwinding]: https://en.wikipedia.org/wiki/Call_stack#STACK-UNWINDING
[andybargh-error-handling]: https://andybargh.com/error-handling-in-swift/
[swift-defer]: https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Statements.html#//apple_ref/doc/uid/TP40014097-CH33-ID532
[promisekit]: https://github.com/mxcl/PromiseKit
[google-promise]: https://developers.google.com/web/fundamentals/getting-started/primers/promises
[swift-concurrency]: https://onevcat.com/2016/12/concurrency/
