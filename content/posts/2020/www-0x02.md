---
title: "WWW 0x02: Distroless Docker for distressed human"
date: 2020-02-01T00:00:11+08:00
tags:
  - Weekly
  - Rust
  - DevOps
---

這裡是 WWW 第貳期，Wow Weihang Weekly 是一個毫無章法的個人週刊，出刊週期極不固定，從一週到五年都有可能。初期內容以軟體工程為主，等財富自由後會有更多雜食篇章。

## [How to Review a Pull Request](https://github.com/rust-lang/crates.io/blob/master/docs/PR-REVIEW.md)

這份是 Rust 的 crates.io（類似 PyPI 和 rubygems）如何審閱拉取請求的文件， 和 Google 那份不太一樣，更貼近專案一點，節錄重點：

- 先拉到自己的本地分支，看看 PR 是否達到他宣稱的療效（檢查一般行為）
- 嘗試用各種手段打爆他（檢查 edge case）
- 如果有任何失敗，請寫清楚重新產生錯誤的流程
- 再來就是理解這個修改到底合不合理，是不是其實不需要

這篇 review guideline 短短的，剩下的自己看囉。

## [Distroless Docker: Containerizing Apps, not VMs - Matthew Moore](https://youtu.be/lviLZFciDv4)

本文是 Google 雇員介紹 Distroless Image 演講的重點摘要，對容器化和 Docker 最佳化有興趣的朋友千萬別錯過。

> [Distroless GitHub Repo 在此](https://github.com/GoogleContainerTools/distroless)

**Q：何謂 Distroless Image**

**Distroless** 的 distro 是指 Linux 發行版（distro），加了一個 less 就是替 docker image 瘦身，只留 app source 和 runtime 需要的 dependencies，把發行版中不必要的東西都幹掉。

**Q：部署程式的歷史**

1. 部署至 VM，貼近開發環境 -> sshd、systemd、crond、套件管理我們根本不需要
2. Docker 橫空出世，但啥東西要放進 docker？ VM 的 filesystem 很棒，也有所有跑 app 需要的 lib，直接把 VM 塞進去
3. 發現 image 太大？縮小 distroapline + musl libc

**Q：我們真正需要什麼**

- compiled source
- dependencies (lib, ~~assets~~ cat videos)
- runtime (libc, JRE, node)

**Q：誰知道如何做這件事**

build tool（cmake、cargo、`go build`、bazel）

上述這些其實 build tool 都知道，所以 build tool 需要的東西就是該進入 docker 的東西，而 `gcr.io/distroless` 的 image 都是由 bazel 打包構建出來的，這也是 Google production 在用的方法（之一）

https://www.youtube.com/watch?v=lviLZFciDv4


**Q：為什麼不用語言自帶的 build tool**

bazel 很好用，尤其是對 Java、C/C++、Rust 和 Go 這種 AOT-compiling 語言，但其實 distroless 不需要 bazel

distroless image + 編譯好的 binary = 一個 dockerfile 就 OK

```dockerfile
FROM gcr.io/distroless/java
ADD myapp.jar /
CMD /myapp.jar
```

**Q：如果編譯期需要其他 deps 怎麼辦**

Docker 有 multi-stage build 啊幹

```dockerfile
# Start by building the application.
FROM golang:1.13-buster as build

WORKDIR /go/src/app
ADD . /go/src/app

RUN go get -d -v ./...

RUN go build -o /go/bin/app

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian10
COPY --from=build /go/bin/app /
CMD ["/app"]
```

**Q：現在能用嗎**

如果你的 app 是 Rust、Go 這種語言，幾乎 100% 能用。

- Go -> 自己寫了 libc，可以完全不打包 libc 直接用 base image
- C/C++/Rust -> 多打包 libc 的 static image
- Java -> 再多打包 OpenJDK-based runtime

**Q：給個結論吧**

作者本來是做 compiler 了，所以從編譯層面，他給出這段 quote：

> Docker solves static linking at distro level
>
> Bazel solve static linking at language lavel

再節錄另一個面向的思考點：

> 如果將 JDK 看作開發環境，你為什麼會想要將整個 distro 打包進去而不是給使用者 JRE 呢？
>
> JDK 之於 JRE 即是 distro image 之於 distroless image
