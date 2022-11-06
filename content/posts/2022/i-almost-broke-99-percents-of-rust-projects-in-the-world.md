---
title: "I (almost) broke 99% of Rust prjects in the world"
date: 2022-11-06T20:19:00+00:00
katex: true
tags:
  - Rust
---

> Title is boasting but indeed could have broken builds of a lot of projects.

Once upon a time (2022-10),
I was trying to fix [a tricky bug] regarding the feature “artifact dependencies”.
[Artifact dependencies] is a humongous feature too hard to implement it 100% right,
as it touches almost every components of Cargo.
There's a saying from an anonymous Cargo maintainer,
“I am mostly confident to make a change until it touches the dependency resolver.”
Unfortunately, the root cause of that bug was exactly related to dependency resolution,
specifically feature resolution in Cargo.
“Well, it is still fixable”, I told myself.

<img src="./artifact-deps.png" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

<small>_A gigantic pull request_</small>

[a tricky bug]: https://github.com/rust-lang/cargo/issues/10526
[Artifact dependencies]: https://rust-lang.github.io/rfcs/3028-cargo-binary-dependencies.html

After some researches and experiments,
I became more confident in my knowledge of feature resolver and artifact dependencies,
so I submitted [a pull request] fixing the bug.
Discussing back and forth with other Cargo maintainers,
we finally reached an agreement and merged my patch.
Everything went smoothly than expected.
Really happy to see myself expanding my comfort zone and being more helpful
in the area of feature resolution.

[a pull request]: https://github.com/rust-lang/cargo/pull/11183

I then did a [sync update] from rust-lang/cargo repository to rust-lang/rust.
The purpose of the update was to land changes from Cargo master branch
into the next Rust nightly channel release.
Then every nightly Rust users in the world will receive those changes.
We merged that sync update soon and everything looked normal as usual.
Those patches was about to hit nightly users within less than 16 hours at the end of that day.

[sync update]: https://github.com/rust-lang/rust/pull/103860

However, there is always a new bug following a new fix.
The performance benchmark bot in rust-lang/rust [found abnormal failures].
After investigations,
the official Rust compiler-perfomance team suspected there was a bug rooted in Cargo.
They immediately notified the Cargo Team to take a look.
I was there and realized I messed up something. With my fix to artifact dependencies,
Cargo refused to compile any project depending on `serde_derive`.
`serde`, along with its companion crate `serde_derive`,
are the cornerstone of a huge amount of Rust project in the ecosystem.
I could say 99% of projects doing serialization use `serde`. So does Rust compiler itself.
We figured out that the fastest way to fix it was [reverting the Cargo sync update].
I was also trying to find a way to fix the bug,
but it was nearly impossible to find an nonintrusive and sensible way to
fix the bug within such a limited time frame.
So yeah, I chose to [revert it from Cargo side] as well.

<img src="./stats.png" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

<small>_Download stats of `serde_derive`_</small>

[found abnormal failures]: https://github.com/rust-lang/rust/pull/103860#issuecomment-1301898101
[reverting the Cargo sync update]: https://github.com/rust-lang/rust/pull/103922
[revert it from Cargo side]: https://github.com/rust-lang/cargo/pull/11331

The feature and the patch lived happily ever after, right? No exactly.
Since the sync update PR had already been merged,
if the revert PR hadn’t made it merged before midnight,
the bug could have sneaked in the next nightly release.
That meant everyone using nightly channel suddenly failed to build their projects
if it depends on `serde_derive`.
I was really worried that day, as I knew that the Rust CI queue is always way too long.
A member of Rust Infra Team set a higher priority on the revert PR,
so that it was expected to get merged before midnight.
We were all relieved and had a good sleep.

Oops! The CI build of revert PR failed. [A mysterious timeout].
Well, fine.
We could always kick off a new build and get it merged and then everyone is happy.
But, no. Not this time.
It was already 21:40 when we spotted the timeout,
and a full CI build on rust-lang/rust usually takes around 3 hours.
That is to say, we were too late to ship the revert to the next nightly release,
and My bug could have started biting everyone after midnight!
I [begged Rust Infra Team] to disable the nightly auto-release temporarily,
and thankfully people were around to help.
They disabled the CI pipeline and [did a manual release].

<img src="./timeout.png" style="box-shadow: 0 0 1em rgba(168, 168, 168)">

<small>_bors timeout!!!_</small>

[A mysterious timeout]: https://github.com/rust-lang/rust/pull/103922#issuecomment-1302686811
[begged Rust Infra Team]: https://rust-lang.zulipchat.com/#narrow/stream/247081-t-compiler.2Fperformance/topic/cargo.20and.20rustc.20benchmarks.20broken/near/307851302
[did a manual release]: https://rust-lang.zulipchat.com/#narrow/stream/247081-t-compiler.2Fperformance/topic/cargo.20and.20rustc.20benchmarks.20broken/near/307872225

Although the story ended here, I still couldn’t make myself calm
until we can prevent this from happening again.
I [posted a pull request] adding tests to ensure the behaviour always successful.
I also plan to add a new CI pipeline to verify builds of some real world projects
during the CI of rust-lang/cargo.
Thanks [@lqd] for always keeping an eye on abnormal performance build.
Thanks [@Mark-Simulacrum] for helping trigger the manual release process at midnight.
Also thanks [@ehuss] for trusting me with dealing with the entire incident.
I couldn’t have had this precious experience without their helps and trust.

[posted a pull request]: https://github.com/rust-lang/cargo/pull/11342
[@lqd]: https://github.com/lqd
[@Mark-Simulacrum]: https://github.com/Mark-Simulacrum
[@ehuss]: https://github.com/ehuss

Just realized that I lost an opportunity to become famous 😗.
