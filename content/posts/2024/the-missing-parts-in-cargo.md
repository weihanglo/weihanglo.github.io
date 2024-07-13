---
title: "The missing parts in Cargo"
date: 2024-07-13T17:00:00+00:00
katex: true
tags:
  - Rust
cover:
  image: https://weihanglo.tw/posts/2024/the-missing-parts-in-cargo/cargo-ship-stagnate.png
  caption: A cargo ship stagnated in March, 2021 (Julianne Cona / Instagram)
---

When people talk about the merits of Rust, they often mention the strict ownership rule, awesome diagnostics, and performance. They also praise Cargo and the crates.io ecosystem. Back in the day, when I just learned Rust, I had no idea why people loved Cargo so much. I wrote JavaScript at work a lot before I met Rust, so that enthusiasm confused me — isn't a convenient package manager a must-have for a serious programming language? It turns out not. Not every programming language has such a great toolchain. Scripting languages tend to have a better story in this regard. When it comes to system-level programming, the solution is nearly empty.

## A sweet meet in the universe

Cargo is quite handy for most individual developers because it JUST WORKS. You create a new package by running `cargo new foo`. Then you `cargo add` some useful dependencies. And `cargo build` the blazingly fast Rust tool. Cool! You then `cargo publish` to crates.io and share the awesome project on `r/rust`. It works just like how npm does in the JavaScript ecosystem — Download. Build. Publish. It is a one-stop shop without you configuring a lot of unnecessary boilerplate or dealing with system dependencies [^1]. It was one of the blessed tools in the universe for individual developers. 

## When Rust grows beyond Cargo

Cargo, while it is advanced as a package manager and build tool that works for developers to work on a pure Rust project, it doesn't really serve well for a more complicated, polyglot project. An enterprise development environment tends to be more resource-constrained. By constrained, I mean there might be no network access, limited access to pre-approved open-source projects, weird linkage setup, ancient or modified C compiler toolchain, strict security audit process, advanced but incompatible cache mechanism. You name it.

It becomes frustrating when people find that Cargo is not suitable for their projects. They either request [CITATION NEEDED] for features for their own needs (sometimes useful in general, sometimes not), or just completely opt out of Cargo. That's sad. Especially when the Cargo project starts losing users from some of the largest companies in the world [^2].

## Most wanted features that never come

By just looking at issues with [most thumb-ups] and [most comments], we can feel the needs from the community. As of 2024-07-11, the rust-lang/cargo repository has 1,398 open issues. It is not really a number beyond management but nearly on the edge. One of the most interesting parts of these issues is that some of them are seemingly duplicates with just slight differences. Those differences, however, are often too essential to neglect, making it way more difficult to find a solution general enough to cover variants for 10 different workflows. 

Alright, let us see what we have hoped Cargo to support these years:

[most thumb-ups]: https://github.com/rust-lang/cargo/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc
[most comments]: https://github.com/rust-lang/cargo/issues?q=is%3Aissue+is%3Aopen+sort%3Acomments-desc

### It's all about cache

There are two major kinds of caches in Cargo:

* A global cache for downloaded dependency sources (`.crate` tarballs and Git repositories under the `~/.cargo` directory). This kind of cache never invalidates.
* A local per-workspace-level cache for intermediate build artifacts (the famous `target` directory). This cache invalidates when a rebuild is needed. We will focus on this.

Cargo relies heavily on file modification times (mtime) reported by the operating system to determine cache freshness. This rebuild detection is notoriously unreliable. For example, the clock may go backward, or the system mtime [has a low precision][#12060] e.g., on Docker or Apple's HFS. People have been looking at [content-hash based solutions][#6529] as a solution, and the main challenge is around performance, which may largely be solved by [reusing hashing results from rustc][zulip-content-hash]. That requires non-trivial investigation and cross-team communication, though.

Rust build time is really bad. People are thinking if we can reuse build artifacts between different projects for common crates like `syn`, `serde`, and `rand`. It sounds valid at first glance but is quite hard. Cargo has a complicated model for conditional compilation based on different [compiler flags][#8716], [Cargo features][#4463], and target platforms. The rebuild detection mechanism (aka fingerprint) tracks [these properties][fingerprint]. If any of them changes, Cargo rebuilds. That means we need to track not only what to build but also how to build. Without the knowledge of "how", it's unlikely to ship a reasonable generalized fix for [docker-cache layers][#2644]. 

Therefore, [reusing compiled artifact caches][#5931] or [sharing target-dirs][#11156] isn't extremely useful if we only roll out a dumb implementation caching everything. We need a design that separates artifacts from different combinations of flags/features/platforms/configs, and provides an easy-to-use interface for users to define how to cache what.

If your CI system generates a random path for each build, you have one more bad news. The seemingly static download sources will also affect cache freshness — [by changing the value of `CARGO_HOME`][#10915]. This is because the `CARGO_HOME` path is embedded in debug symbols.

It's even more fun when looking into non-determinism of build scripts and proc macros, though I shall stop here.

[#6529]: https://github.com/rust-lang/cargo/issues/6529
[#12060]: https://github.com/rust-lang/cargo/issues/12060
[mtime-harmful]: https://apenwarr.ca/log/20181113
[zulip-content-hash]: https://rust-lang.zulipchat.com/#narrow/stream/246057-t-cargo/topic/Implementing.20checksum.20based.20fingerprinting/near/446199539
[fingerprint]: https://doc.rust-lang.org/1.79.0/nightly-rustc/cargo/core/compiler/fingerprint/index.html#fingerprints-and-metadata
[#2644]: https://github.com/rust-lang/cargo/issues/2644
[#8716]: https://github.com/rust-lang/cargo/issues/8716
[#4463]: https://github.com/rust-lang/cargo/issues/4463
[#5931]: https://github.com/rust-lang/cargo/issues/5931
[#10915]: https://github.com/rust-lang/cargo/issues/10915
[#11156]: https://github.com/rust-lang/cargo/issues/11156

### Phases of a `cargo build`

Cargo wasn't designed to be a complete "build system". It was just a package manager that helps fetch dependencies from the internet, simply builds, and publishes them to crates.io. Okay, I guess I just stepped on a trap of defining what a build system should be. A build system, or build orchestrator, is software that generates a set of actions from user-provided build tasks. It can "optionally" execute these actions (Yes, so CMake is a build system in my mind).

The potential of offloading build executions to other tools is essential. It makes transparent how build tasks should be executed with desired inputs and outputs, bringing a more deterministic and analyzable build. By separating the execution phase from a build, Cargo could be able to tell [why a crate is rebuilt][#2904], without actually rebuilding it. Also, clearly no need to [guess the test executable name][#1924] with `jq` and `grep` magics.

To push it further, a build task with well-defined input/output could open a door for different kinds of [pre][#7178]/[post][#545] build processing. Hmm... I shouldn't say pre/post processing. Tasks ought to be composable. Apart from the execution order, the interface of defining a build task should be pretty much the same, regardless of whether it is pre or post processing. Designing such an interface is unfortunately the most difficult part that slows down the design and development. For now, Cargo prefers TOML for build configuration. Its static property ensures Cargo only does things in a defined manner. When you are not on the happy path and need an escape hatch, Cargo provides a complete unsandboxed environment to do arbitrary things. Yes, that's called "build scripts".

These two approaches are at opposite ends of the spectrum. There is a huge gap in between that Cargo doesn't even look into. Why? Because people who look at it often end up inventing a programming language (e.g., [Nickle], [Nix], and [Starlark]). Should Cargo evolve toward that direction? I don't know. There is a proposal for sandboxing build scripts, but it's more like a patch for build scripts themselves, not a total solution for build task composability. [Ed Page's post] last year also provides an overview and potential solutions for it. It's short and worth a read.

Speaking of breaking a build into phases, [Bazel] and [Buck2] are good examples. From my truly belief, by doing so, it also helps achieve distributed executions and remote caching for their use cases. It may not be a necessary feature for indie developers or small startups. Think about it: What if we've solved [the cache issue](#Its-all-about-cache) and somebody just built a [sharable cache service][cachix] that benefits everybody's CI pipeline?

[#2904]: https://github.com/rust-lang/cargo/issues/2904
[#1924]: https://github.com/rust-lang/cargo/issues/1924
[#545]: https://github.com/rust-lang/cargo/issues/545
[#7178]: https://github.com/rust-lang/cargo/issues/7178
[Nickle]: https://nickel-lang.org/
[Nix]: https://nix.dev/manual/nix/2.23/language/
[Starlark]: https://github.com/bazelbuild/starlark
[Ed Page's post]: https://epage.github.io/blog/2023/08/are-we-gui-build-yet/
[Bazel]: https://bazel.build/extending/concepts#evaluation-model
[Buck2]: https://buck2.build/docs/developers/architecture/buck2/
[cachix]: https://www.cachix.org/

### Build script is not a C package manager

Speaking of build scripts, we must give credit to it for Rust's growing popularity. As a tool for a system-level programming language, Cargo is often considered pretty "out-of-the-box" because the only command you need to run is `cargo build`. Even when a package depends on a missing C library, `build.rs` can fetch and build it from source for you.

Everything comes with a cost. A build script is not a proper C package manager. Its imperative and dynamic nature makes the dependency relation nearly untrackable. Let alone the infamous "Cargo feature unification is additive" — Once a `vendored` feature is enabled in a dependency graph, you never have a chance to turn it off. We need a declarative interface like [system-deps] to constrain this. However, how is it possible to model a more versatile build system like CMake in a less powerful language like TOML? So it circles back to [defining the interface of build tasks](#Phases-of-a-cargo-build).

Or, anyone want to write a C package manager and make it mainstream, so Cargo can just call it?

[system-deps]: https://github.com/gdesmott/system-deps

### The unconditional conditional compilation

Okay. Let's move on to the ugly part.

Conditional compilation in Cargo is expressed via "Cargo features". A Cargo feature can:

* Toggle on a code block by passing the corresponding `--cfg` flag to the compiler
* Activate optional dependencies
* Activate other features

This seems more powerful than traditional C's `#ifdef`, but actually not. To prevent excessive compilation overhead, the dependency resolver picks only one compatible version when a crate appears in the dependency graph multiple times, and each is within the SemVer-compatible versions defined. And because they are deemed compatible, Cargo gets one step further that unconditionally merges all activated features into a union of them. This is the "additive" property. You have [no way to opt-out of this behavior][#3126]. If you desperately need [mutually exclusive features][#2980], you and downstream users of your crate likely hit the ground hard, as there is no simple way to support this (yes, please look back [to the `vendored` issue](#Build-script-is-not-a-C-package-manager)). It will become a compatibility hazard if a crate doesn't respect SemVer-compatibility and the additive nature of Cargo features.

To make the situation worse, people want to [activate dependencies based on feature activations][#5954], which may in turn activate more features. How long will it take for a feature unification to converge if that is allowed? I don't really know. That said, it is a valid feature request. Just too hard to make the design right. The Cargo team has made several attempts to make feature resolution better, for example [feature resolver v2]. None of them is a clear win, as users need to know [in which situations a feature resolution may be different][#10112]. Those attempts even [confuse maintainers of Cargo][feature-syntax-confusion]!

A piece of good news is that [RFC 3416](https://rust-lang.github.io/rfcs/3416-feature-metadata.html) was merged, allowing future extensions of feature metadata like public/private or unstable features. It will make feature resolution smarter with the sacrifice of software complexity, from the perspective of both tool users and maintainers.

[#3126]: https://github.com/rust-lang/cargo/issues/3126
[#2980]: https://github.com/rust-lang/cargo/issues/2980
[#5954]: https://github.com/rust-lang/cargo/issues/5954
[#10112]: https://github.com/rust-lang/cargo/issues/10112
[feature resolver v2]: https://doc.rust-lang.org/cargo/reference/resolver.html#feature-resolver-version-2
[feature-syntax-confusion]: https://rust-lang.zulipchat.com/#narrow/stream/246057-t-cargo/topic/Odd.20cargo.20resolver.20behavior
[RFC 3416]: https://github.com/rust-lang/rfcs/pull/3416

### Finger-crossed cross-compilation

When discussing cross-compilation, people always say Rust has built-in cross-compilation thanks to Rustup and Cargo. This is true, but they didn't tell you the full story.

First of all, if you're in a pure Rust world, you are the luckiest person in the world. You don't need to deal with different [compiler flags][#4897] and [linkers][#4133]. You don't need to configure `target.<cfg>.rustflags` and find [the dual behavior][#9453] between build scripts and normal dependencies. While `target-applies-to-host` is a solution to this, it never comes stabilized as it [may break some subtle workflows][#10395] around passing rustflags users already rely on.

Apart from configuring flags for cross-compilation, it is also unable to tell from `Cargo.toml` if a package supports or [requires building on certain platforms][#6179]. We have unstable [per-package-target][#9406] though the semantic of it is quite unclear, especially when interacting with [artifact dependencies][#9096] and [building your own standard library (a.k.a. build-std)][build-std]. An even trickier part is the timing of filtering supported platforms. Should dependency resolution be aware of this? Should we make the lockfile possible to track dependencies only on supported platforms?
All of these questions are not yet answered.

[#4897]: https://github.com/rust-lang/cargo/issues/4897
[#4133]: https://github.com/rust-lang/cargo/issues/4133
[#9453]: https://github.com/rust-lang/cargo/issues/9453
[#10395]: https://github.com/rust-lang/cargo/pull/10395#issuecomment-1051023136
[#6179]: https://github.com/rust-lang/cargo/issues/6179
[#9406]: https://github.com/rust-lang/cargo/issues/9406
[#9096]: https://github.com/rust-lang/cargo/pull/9096
[build-std]: https://github.com/rust-lang/wg-cargo-std-aware

### If all we have is a dependency resolver

As a package manager, selecting the correct dependency versions is the primary goal of Cargo. Cargo has its own ad-hoc dependency resolution algorithm that only a few people understand. Cargo made [conditional compilation](#The-unconditional-conditional-compilation) part of the resolver, so it can pick the correct set of optional dependencies and features within a valid version range. It understands `[patch]` because [the resolver needs to pretend a patched dependency is from the original source][resolver-knows-patch]. It knows the preferred Rust toolchain version in mind so that it can perform an [MSRV-aware resolution][#9930].

While keeping in mind that Cargo's resolver and the entire community follow SemVer strictly, there is still a huge desire for allowing [multiple SemVer-compatible versions][#5640] in a dependency graph. Different strategies have been proposed, such as [resolving to minimal versions][#5657]. Restrictions like [disallowing duplicate native lib linkage in one graph][#5237] are looking for a lift. Besides, there is a potential need for support in resolving [platform-specific](#Finger-crossed-cross-compilation) dependencies.

Every feature request seems minimal. However, every problem becomes a version-solving problem if all we have is a dependency resolver. And that exacerbates the hard-to-maintain situation worse. The resolver is not an LLM, but it is still a myth to some maintainers how it actually works.

We should be glad that one of the Cargo maintainers decided to stand out and pursue a goal to [modularize Cargo's ad-hoc resolver][pubgrub-in-cargo]. To be more precise, it is letting the top-notch dependency resolver library `pubgrub` understand all shenanigans Cargo is doing right now. While this is a bold project, I am really looking forward to the outcome. You can track the progress by subscribing to [this Zulip topic][pubgrub-progress].

[resolver-knows-patch]: https://github.com/rust-lang/cargo/blob/b60a1555155111e962018007a6d0ef85207db463/src/cargo/core/resolver/context.rs#L121-L135
[#9930]: https://github.com/rust-lang/cargo/issues/9930
[#5640]: https://github.com/rust-lang/cargo/issues/5640
[#5657]: https://github.com/rust-lang/cargo/issues/5657
[#5237]: https://github.com/rust-lang/cargo/issues/5237
[pubgrub-in-cargo]: https://rust-lang.github.io/rust-project-goals/2024h2/pubgrub-in-cargo.html
[pubgrub-progress]: https://rust-lang.zulipchat.com/#narrow/stream/260232-t-cargo.2FPubGrub/topic/Progress.20report

## Stability with stagnation

Enough! We've talked too much about open issues. Let's step back and find out why the innovation seems to be stuck.

The stability guarantee of Cargo is both a blessing and a curse to the community. It's a blessing that we don't worry too much when running `rustup update` every six weeks. To make it worse, Cargo is one of the fastest-growing programming languages. Even [an unstable nightly feature cannot be slightly removed][build-plan-remove] due to the large adoption these days.

["Stability without stagnation"] is a principle Rust holds. This is the gist of the 6-weeks "release train" model. However, people are so creative that inventing their own workflows to fix the inability of all the aforementioned missing features. That's nice, but Cargo is stuck in these implicit dependent relations, which makes maintainers[^3] stressed out and reluctant to take risks on new stuff. You can see how the discussion [RFC 3537] went, regardless of the intention of it was finding a middle ground to improve the current situation.

<center><img src="https://imgs.xkcd.com/comics/workflow.png" alt="There are probably children out there holding down spacebar to stay warm in the winter! YOUR UPDATE MURDERS CHILDREN."></center>

Maybe because of the stability guarantee, people put a much higher bar for new features to be "perfect" and satisfy everybody. There is a [summary of the docker cache problem] calling out:

> For a feature to be stablized in cargo, it needs to fit into the cohesive whole, meaning it needs to work without a lot of caveats. _It can't be a second tier solution_

I have a dream. A dream that Cargo has its own release cadence, so it is free from the strict stability curse and can then ship major version releases.

[build-plan-remove]: https://github.com/rust-lang/cargo/issues/7614#issuecomment-1444692932
["Stability without stagnation"]: https://doc.rust-lang.org/book/appendix-07-nightly-rust.html#stability-without-stagnation
[#7614]: https://github.com/rust-lang/cargo/issues/7614#issuecomment-1444692932
[RFC 3537]: https://github.com/rust-lang/rfcs/pull/3537
[docker-cache]: https://hackmd.io/@kobzol/S17NS71bh#Solution-Brainstorming

## Maximize compatibility with minimal compatibility

Well, it might be more than a dream to evolve Cargo without stagnation. A great example is [`cargo-nextest`]. As a non-official third-party Cargo plugin, `cargo-nextest` doesn't need to hold the stability guarantee like other official Rust tools. Instead, it ships a performant test execution model that is [deemed a breaking change][#5609] if it were made to Cargo. It turns out that people love it and are willing to update their test code accordingly in exchange for test execution speed-up. Not to say that in most scenarios, `cargo-nextest` is just a drop-in replacement.

In the success story of `cargo-nextest`, its maintainers got a space to experiment on different design ideas, as well as gain some adoptions for feedback. Is it possible to achieve that for other parts of Cargo? To answer the question, first, we need to figure out the minimal set of functionalities Cargo must provide to be compatible with the crates.io ecosystem. Calling out being compatible with crates.io is because, to be honest, Cargo is nothing if there is no such ecosystem. If we want to see a wide adoption of our `cargo-nextbuild`, `cargo-nextrun`, or else, we would like to maximize compatibility with the crates.io ecosystem. You don't ever want to recreate a whole new ecosystem for Rust, trust me.

Let's see what the minimal set of functionalities a Cargo-compatible tool needs to have to be free from stagnation.

> Note that a Cargo-compatible tool doesn't necessarily need to be done from scratch. It can be a wrapper of Cargo or use cargo-the-library.

[`cargo-nextest`]: https://nexte.st/
[#5609]: https://github.com/rust-lang/cargo/issues/5609

### Matching the result of dependency resolution

In an ideal world, a published crate on crates.io is guaranteed to be buildable. Other developers can fetch its source and build it flawlessly. This guarantee is upheld with the Cargo ad-hoc dependency resolver, and their contract is written in the form of `dependencies` and `features` tables in `Cargo.toml`. 

If we're going to build a new dependency resolver, we don't want to fall into a situation where the old resolver found a solution for a package, whereas the new resolver can't. That makes the package unbuildable, hurting the compatibility.

It is acceptable that two dependency resolvers find different solutions, as long as those solutions are valid for both resolvers.

In summary, a Cargo-compatible tool must produce dependency resolution results that are valid in Cargo, and vice versa [^4]. This also includes correctly parsing dependency information[^5] from `Cargo.toml` and `Cargo.lock`.

[pubgrub-rs]: https://github.com/pubgrub-rs/pubgrub/

### Matching the behavior of running build scripts

In a Cargo package, every dependency is statically known, with one exception: Running build scripts. By the nature of build scripts being able to run arbitrary code, they are considered "dynamic dependencies". Cargo doesn't know what will be produced until a build script has run.

Cargo has a set of [build script instructions] that defines corresponding behavior before, during, and after running a build script. For example, a Cargo-compatible tool must not run if the path given by `cargo::rerun-if-changed=PATH` has no change. When a `cargo::rustc-env=VAR=VALUE` instruction is emitted, the env var must be set for the compiler invocation of the crate-being-built.

That is to say, a Cargo-compatible tool must exactly match the behavior of running build scripts, including:

* Determine whether a rerun is needed.
* Correctly parse the emitted build script instructions.
* Configure the compiler invocation based on emitted instructions.

[build script instructions]: https://doc.rust-lang.org/nightly/cargo/reference/build-scripts.html

### Setting environment variables for crates

This one is relatively straightforward. Cargo [sets environment variables for compiler invocations and build script runs][cargo-set-env]. These variables are either package metadata from `Cargo.toml` or necessary information helping build scripts do dirty jobs. The tricky part is that some variables are pretty Cargo-centric. For example, it's odd that a non-Cargo tool setting a path to cargo because a crate requiring the `CARGO` environment variable to call `cargo` executable recursively. However, it doesn't really make the situation worse, as build scripts are already able to do anything.

[cargo-set-env]: https://doc.rust-lang.org/nightly/cargo/reference/environment-variables.html

## Closing

In this note, we reviewed the current state of Cargo. There are a bunch of feature requests never done. They stagnate because of the pursuit of perfection or fear of breaking unnoticed workflows. They often have a way too large design space with only a tiny place to experiment.

We then looked into a way to break the stagnation. Taking `cargo-nextest` as an example, we need to ensure a minimal compatible interface is implemented for a Cargo-compatible tool when experimenting with new ideas. Surprisingly, the minimal compatible layer is still of a reasonable size, though we might miss some important aspects that should be covered.

So, are we ready for a new adventure?

[^1]: This is a success story for build scripts that they just vendor everything C dependencies, however, silently. It is ironically that it is now considered a failure because silent vendoring is not acceptable from several aspects. See [system-deps#97](https://github.com/gdesmott/system-deps/issues/97).
[^2]: Apparently, Google and Meta don't really use Cargo. Projects like Nix and Rust-for-Linux are willing to roll out their own build system for Rust.
[^3]: At least for me, I often feel incapable of merging a PR, even when it seemed completely harmless but actually [broke 3rd-party plugin users](https://github.com/rust-lang/cargo/issues/11487).
[^4]: This is actually written in the 2024H2 Project Goals ["Extend pubgrub to match cargo's dependency resolution"](https://rust-lang.github.io/rust-project-goals/2024h2/pubgrub-in-cargo.html#milestones). Thanks again to the owner of the goal!
[^5]: Thankfully, not all fields in `Cargo.toml` are needed for the minimal interface. In Cargo, the core fields are defined in [the `Summary` struct](https://github.com/rust-lang/cargo/blob/b31577d43ce235bb77167d399e14a0b5f6fdf584/src/cargo/core/summary.rs#L14-L31). They construct necessary info for the resolver to work.
