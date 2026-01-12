---
title: Thoughts on React Native from an iOS developer
tags:
  - React Native
  - Mobile App Development
date: 2017-07-30T18:16:45+08:00
---

![React Native](https://i.imgur.com/Ya2NnLz.png)

About two month ago, I started making a React Native app ["PyConTW 17"][pycontw-mobile] for the biggest annual Python conference in Taiwan ([PyCon Taiwan][pycontw]). The app is quite simple, but still took some efforts for me to build. As a complete React newbie, I would like to share some of my thoughts about React Native.

_(written on 2017-07-30, based on React Native 0.44.2)_

<!-- more -->

> **Disclaimer**: I am a junior iOS developer (about 1 year experience) without any computer science degree. This article is based on my 2 weeks React Native experience developing "PyConTW 17" and React knowledge gained from my job recently.

[pycontw-mobile]: https://github.com/weihanglo/pycontw-mobile
[pycontw]: https://tw.pycon.org

## What I've done

Before sharing my point of view, let's learn what features are included in this conference app:

- A user could view all event/talk information of the whole conference.
- A user could save some favorite events for quick access (saved locally).
- A user could filter events by pre-defined tags of category.
- Events would update automatically if any data in database changes.

As an iOS developer, you may feel familiar with these requirements. The app may be just a tabbar-based app with some customized table view to display contents. No database. No synchronization for user-generated data. Our React Native version app share with this basic anatomy mentioned above. Therefore, the UI architecture only contains some views such as list views, detail views of event/speaker, and the main app container. That's all in this app.

## The good part

### Shared codebase

This project seems to only contain trivial implementation details from an veteran iOS developer's perspective. What if you need to target at both Android and iOS in one week? Learning Android development from scratch may not be suitable with an approaching deadline, and the separation of codebase may be prone to maintenance issues in the long run. To achieve the goal, you could choose React Native in order to **wrap the core logic into one codebase**. No more switches between Android Studio and Xcode. React Native would give us a truly native app. That's why React Native hypes.

### Faster development iteration

We are all tired of write-compile-debug iteration for our daily mobile app development. With the growth of the bundle size, it would take more time to build our app (especially in Swift). React Native uses some tricks like [Hot and Live Reloading][hot-live-reloading] to refresh your simulator/emulator instantly without recompilation. That's really an incredible time saver.

Moreover, if you choose [Create React Native App][create-rn-app] as the scaffolding tool, you can gain benefits from [Expo][expo] platform to test your app in real devices without any wired connection. What you need to do is scanning the QR code and coding. This is a huge leap from traditional mobile native development cycle.

[hot-live-reloading]: http://facebook.github.io/react-native/releases/next/docs/debugging.html#reloading-javascript
[expo]: https://expo.io/
[create-rn-app]: https://github.com/react-community/create-react-native-app

### Clever devtools

Did you remember the last time using the **View Hierarchy Debugger** in Xcode? This tool is very awesome for visually debugging, but sometime it's quite laggy with complicated views hierarchy (improved in Xcode 8), and that leads to frustration. The solution React Native providing is a web-browser-like `inspector` for us to inspect elements on simulators. With the inspector, you can see box model, styles and even inheritance hierarchy of the selected component without long wait for the rainbow ball rotating. Additional, React Native also has a performance panel to help you achieve 60 FPS animations.

If you need more advanced debug tools, there is also a [remote debugging plugin][react-devtools] available. You can **download it from Chrome Web Store or Firefox Add-ons**. This debugger allows inspection of React component instances, and you can also see logs from browser console.

There are still lots of tools that did not cover in this article. Either tools offered by Facebook or contribute by communities (like [Redux Devtools][redux-devtools]) are convenient for daily use. Feel free from escaping Xcode!

> To be honest, Xcode provides plenty of excellent debugging and profiling tools which are greater than those browsers have. However, they are not easy to start with, and every iOS developer I met seldom uses them.

[react-devtools]: https://github.com/facebook/react-devtools
[redux-devtools]: https://github.com/gaearon/redux-devtools

### Modern JavaScript

JavaScript is very promising these years. ES2015 introduced lots of anticipating modern feature such as `Promise` and `Generator`. However, due to the diversity of browser ecosystem, if one wants to use new features to support most browser vendors, it will need to add some polyfills or transpile all code to the target version. However, the setup procedure of build environment for transpilation is annoying to some extent.

In React Native development, this is no longer a problem. All we need are done by a scaffolding tool called `react-native-cli`. This tool will setup a modern JavaScript development environment with all new JavaScript features. We can boldly use `async/await` syntax to avoid callback hell, and even use the new `fetch` Web API for HTTP requests. In comparison of old web-based hybrid technology such as Cordova, React Native eliminates the scary setup process and brings all pleasant stuff to live!

### Dependency management

Another sweet point of React Native is the dependency management. **CocoaPods** is de facto dependency manager for Cocoa development, yet it is written in Ruby that increases costs to learn. Nowadays we get **Carthage** which is written in pure Swift, though it still has [some issues][carthage-nested-deps] as dependencies being more complex and nested. No one want drag all dependencies of 3rd module manually.

As for React Native, we can use **Npm** (or [Yarn][yarn] I recommended), one the best dependency management and ecosystem in the world. Npm reduces the painful **workspace** regeneration and sharing issue with CocoaPods, as well as manages dependencies with nested resolution to avoid incorrect versioning. Though the whole packages may be a little bit large, it may not be a problem for a mobile app. After all, the connection status on the internet is more strict than native app. We should be content that we do not need to download all resources on every single launch.

[yarn]: https://yarnpkg.com
[carthage-nested-deps]: https://github.com/Carthage/Carthage#nested-dependencies

### Community

There are always a strong community behind a successful open source project. So does React Native. The community of React Native is one of the most active open source communities. Developers proficient in Android or iOS create lots of useful native modules to break down the barrier between native code and JavaScript. A famous example is [React Native SVG][react-native-svg] which implements SVG rendition with native rendering API (on iOS, it use `CoreGraphics` to accomplish).

 <!-- such as   -->
Other developers coming from React community bring more new web development concepts to mobile land. For instance, unidirectional data flow, state management, component-based architecture, router patterns and many others. These concepts also have influenced back on pure native development, and invoke the reconsideration of traditional MVC/MVP/MVVM architecture. More and more talks discuss about view purification and state centralization. Some enthusiasts even started to develop a new state management module called [ReSwift][reswift], which is inspired by Redux.

The benefit of these abstractions is not only full of cool jargons but predictable, making views become testable. The most important impact on native development in my opinion is the concept of predictable unit tests, which is absent in traditional MVC architecture.

[react-native-svg]: https://github.com/react-native-community/react-native-svg
[reswift]: https://github.com/ReSwift/ReSwift

## The pain points

![pain points](https://images.pexels.com/photos/34667/person-human-male-man.webp)

### One codebase cannot rule them all

If you have read the official React Native website thoroughly, you will notice that the slogan of React Native is _"Learn once, **write** anywhere"_ instead of _"**run** anywhere"_. One can realize that **React Native does not aim to be shareable between different platforms**. Actually, Facebook suggests that developers should [design different components for different platforms to match platform-specified user experience][f8app-design]. For example, an Android app may not need an back button for navigations because each Android device has a physical back button.

Another issue is related to platform differences. Not all API on iOS could meet a compatible API on Android. For examples, `shadowProps` have no effect on Android yet Android has another `elevation` style to generate a shadow-like visual effect. We may also face on some bug in old buggy webview of iOS like not calling `WebView#onLoadEnd` after loaded. When it comes to build system, you may overwhelm by diverse toolsets for each platform. For me, I must learn groovy to write some gradle scripts which only read `keystore` property for app signing and submission. How painful!

As far as you dive into mobile app development, you will find that the basic API of React Native are always not enough to use. Instead, you would aware yourself stackoverflowing around and looking for other out-of-the-box libraries to use immediately. Although there are hundreds of open source libraries for cross platform React Native development, every single library is written in at least two different programming language to accomplish its purpose, and that means double knowledge and cost are included. From build system to rendering API, each platform needs specific approaches to optimize all aspects. Therefore, you shall not treat those libraries as normal JavaScript modules. Native development is that hard.

> As an iOS developer, if there is no any React Native module that meets your needs, you need to tell your boss to recruit a real Android man for help, or pay you double to learn the whole new Android development stack.

[f8app-design]: http://makeitopen.com/tutorials/building-the-f8-app/design/

### Steep learning curve

As a traditional mobile app developer, you are familiar with object-oriented programming. Factory pattern, adapter pattern appear all of your daily life. What if someone told you that your function is **not pure** enough and suggest to use **monad** to wrap your API? These are all functional programming buzz words. Despite of flexibility of React Native, the [Thinking in React][thinking-in-react] concept makes React fit for functional programming paradigm. Most of the open source libraries built around React ecosystem conform to functional programming pattern. If you determine to adopt React Native into your development stack, it may spend additional efforts to learn with [all those jargons][fp-jargons]. From a manager's perspective, it is hard to recruit a well trained programmer equipped with functional programming skills (at least in Taiwan).

[thinking-in-react]: https://facebook.github.io/react/docs/thinking-in-react.html
[fp-jargons]: https://git.io/fp-jargons

### Concurrency

React Native uses `JavaScriptCore` to handle all JavaScript code, request for resources, and communicate with native code. Under the hood, all JavaScript code run in JS thread. This JS thread is a real system-level thread which would work asynchronously with the main thread (UI thread). Here is one thing you must know: **UI thread and JS thread are the only two threads developers will get in an pure React Native app**. That's where the problem begins.

When we wants to do some heavy computation like encryption or data transformation, all user interactions will be stuck without any feedback because all JavaScript code is run under a single-threaded JavaScript engine. That's not acceptable for an app concerned with user experience. Though we can [do some tricks][perf-responsive] with the help of JavaScript message queue, the heavy computation still awaits there and gets ready for blocking the main thread.

On Cocoa, we have the wonderful [Grand Central Dispatch][gcd] (`Dispatch` framework in Swift 3), which abstracts thread management for us to do concurrent jobs. In React Native, if we want to manage real threads on our own, the only way is leaking abstractions. We need to write a native module creating another `JSVirtualMachine` and expose API to React Native. Sounds great, but also like an terrifying obstacle to those not familiar with native. You should always consider performance issue in comparison between JavaScript and native solutions (Hi Electron, I am talking to you).

[perf-responsive]: https://facebook.github.io/react-native/docs/performance.html#my-touchablex-view-isn-t-very-responsive
[gcd]: https://en.wikipedia.org/wiki/Grand_Central_Dispatch

## Is React Native worth learning?

The short answer is: **yes**.

The long answer is: **definitely yes for your next application**. Learning React Native can leverage your knowledge to another level. Those impressive, promising concepts will sharpen your skills and bring great ideas to your software development knowledge. If you are still concerning about the cost of switch to React Native, here are some scenarios for you to choose React Native over native platform:

- Need to build this app within a short period of time.
- Single purpose app like "PyConTW 17" is most suitable.
- Not heavily rely on native API (sorry to HealthKit, ARKit and SiriKit).
- User interface is relative simple.
- Have teammate with strong native experience (we need both Android and iOS).
- Your team applies [Hype Driven Development][hdd].

After all, _everything in life is a trade off._ Just ship your code and enjoy the evolving mobile app development world!

[hdd]: https://blog.daftcode.pl/hype-driven-development-3469fc2e9b22
