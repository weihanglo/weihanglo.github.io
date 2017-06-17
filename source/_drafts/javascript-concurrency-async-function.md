---
title: Modern Concurrency in JavaScript - Async Functions
tags:
  - JavaScript
  - Concurrency
  - Async Function
  - Front-End
---

在前一篇介紹 [JavaScript Concurrency 的文章](https://weihanglo.github.io/2017/javascript-concurrency-promise/)中，Promise 提供開發者安全統一的標準 API，透過 `thenable` 減少 callback hell，巨幅降低開發非同步程式的門檻，大大提升可維護性。不過，Promise 仍沒達到 JS 社群的目標「Write async code synchronously」。本篇文章將介紹 Concurrency 最新的 Solution「Async Functions」，利用同步的語法寫非同步的程式，整個人都變潮了呢！

_（撰於 2017-06-17，基於 ECMAScript 7+）_
