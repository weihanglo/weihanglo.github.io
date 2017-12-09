---
title: Carthage 套件管理工具
date: 2017-03-05T08:45:57+08:00
tags:
  - Carthage
  - Swift
---

[Carthage][carthage] 是一個較新的 Cocoa 開發第三方套件管理工具，相較於知名 [CocoaPods][cocoapods] 管理工具的複雜配置，輕巧的 Carthage 在推出之後廣受 Swift 社群喜愛。

_（撰於 2017-03-05，基於 Carthage 0.20: Unary, Binary, Ternary）_

<!-- more -->

## 特色

- 時代潮流：Written in Swift! (v.s. CocoaPods in _Ruby_)
- 主流現代：iOS 8+, dynamic framework only
- 去中心化：無提供類似 cocoapods、npm 這種中心儲存庫。
- 非入侵式：不會修改 Xcode 相關配置，耦合性低。

## 快速上手

0. 從終端環境安裝 Carthage
  ```bash
  brew install carthage
  ```
  > 如果還沒有裝 homebrew，[請來這下載](https://brew.sh/)

1. 建立一個 `Carfile`，列出欲使用的模組，例如：

  ```ruby
  github "Alamofire/Alamofire" ~> 4.4
  github "ReactiveX/RxSwift" ~> 3.0
  ```

2. 在終端環境輸入 `carthage update`，Carthage 將自動下載所有相依模組至 `Carthage/Checkouts` 資料夾中，並編譯成 frameworks（或直接下載 pre-compiled framework）。
3. 將 `Carthage/Build` 資料夾內編譯好的 frameworks 拖拉進你的 **app target** => **General** => **Linked Frameworks and Libraries**
4. 在 **app target** => **Build Phases** 下新增一個 **New Run Script Phase**

  ```bash
  # 自動將 framework 複製到 target app 的 bundle中
  /usr/local/bin/carthage copy-frameworks
  ```

  並在 **Input Files** 加入相依的 frameworks 路徑，例如：

  ```bash
  $(SRCROOT)/Carthage/Build/iOS/Alamofire.framework
  $(SRCROOT)/Carthage/Build/iOS/RxSwift.framework
  ```

## Cartfile 版號語法簡介

Cartfile 版號語法與 Podfile 雷同：

```ruby
# 版號 >= 3.1.2
github "ReactiveX/RxSwift" >= 3.1.2

# 版號 3.x (3.0 <= ver < 4.0)
github "SnapKit/SnapKit" ~> 3.0

# 僅匹配版號 0.4.1
github "jspahrsummers/libextobjc" == 0.4.1

# 最新版
github "jspahrsummers/xcconfigs"

# 指定 Git branch
github "jspahrsummers/xcconfigs" "branch"

# 其他 Git Server Repository 的 develop 分支
git "https://agitserver.com/swift-test/swift-test.git" "develop"

# 本地 local Git Repository
git "file:///directory/to/project" "branch"
```

## 常見議題

### Q：Carthage 資料夾裡面究竟有啥？

```
Carthage/
├── Build/
│   ├── iOS/
│   │   ├── Alamofire.framework
│   │   ├── Alamofire.framework.dSYM
│   │   ├── SnapKit.framework
│   │   └── SnapKit.framework.dSYM
│   └── macOS/
│       └── ... macOS 等其他平台 的 framework
└── Checkouts/
    ├── Alamofire/
    │   ├── ... Alamofire clone 下來的原始碼
    └── SnapKit/
        └── ... SnapKit clone 下來的原始碼
```

- Carthage/Build: 打包好的 framework（pre-built 或是從 checkouts build 出來的）
- Carthage/Checkouts: 所有相依模組的 source code

### Q：如何避免 `carthage udpate` 取得的模組版號不同？

Carthage 提供一個鎖定文件 `Cartfile.resolved`，記錄了當前被確切安裝的模組精確版號。每次更動新增相依模組時，`Cartfile.resolved` 即會自動更新。可預防部分模組版號沒有完全遵循 [語意化版本（SEMVER）][SEMVER] 時產生的問題。

建議將 `Cartfile.resolved` 提交至版本管理系統中。之後將遠端儲存庫 clone 下來，只需要執行

```bash
carthage bootstrap
```

就可以取得與提交時版號完全相同的模組了。

### Q：我不想提交 Carthage 資料夾到 Git Server，怎辦？

一般而言，我們會將 Carthage 加入 Project 的 `.gitignore` 中：

```bash
# in .gitignore
Carthage
```

除非另有需求，不然 `Cartfile.resolve` 應足以還原 project 與提交時相同版號的模組環境。

### Q：我需要開發用但非 Project 相關的模組，該如何？

Carthage 提供另一個 `Cartfile.private`，配置方法與 `Cartfile` 相同。`Cartfile.private` 內的相依模組不會被作為主模組的 dependency。可用來配置開發用模組，譬如使用 testing framework。

### Q：如何只提供 binary framework，不開放 source code？

Carthage 提供的來源除了 Git 以外，事實上[最近才提供 binary][binary-imp] 這個選項。

**Cartfile** 範例如下：

```ruby
binary "https://example.com/release/ExampleFramework.json" ~> 1.4.0
```

這裡的 json 檔應描述該 framework 對應版號的下載路徑，配置範例如下：

```json
{
    "1.3.5": "https://example.com/release/1.3.5/framework.zip",
    "1.4.3": "https://example.com/release/1.4.3/framework.tar.gz"
}
```

除此之外，目前只接受 `https` url 連結，且 version 只能對應[語意化版本][SEMVER]， Git branch／tag／commit 都暫時無法使用。

### Q：如何同時修改相依模組的 code，並在 Run 時同步更新嗎？

可以，請新增一個 **Run Script** build phase，在 Run App 後會自動 build 新的 framework：

```bash
/usr/local/bin/carthage build --platform "$PLATFORM_NAME" --project-directory "$SRCROOT"
```

**！！！！！注意！！！！！**

所有在 Carthage/checkouts 內的 source 隨時可能改變。如果確定需要改動相依模組，請利用 [carthage 指令將相依模組加入 Git submodules][carthage-submodules]。

```bash
carthage update --use-submodules
# or
carthage checkout --use-submodules
```

之後就可以直接操作 Git submodules 了！


[carthage]: https://github.com/Carthage/Carthage
[cocoapods]: https://cocoapods.org/
[SEMVER]: http://semver.org/lang/zh-TW/
[carthage-submodules]: https://github.com/Carthage/Carthage#using-submodules-for-dependencies
[binary-imp]: https://github.com/Carthage/Carthage/commit/3a151a413350b980c68b2f1be8ca234e7947d575
