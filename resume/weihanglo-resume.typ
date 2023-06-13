#import "template.typ": *

#show: cv.with(
  author: "Weihang Lo",
  img: "bunny.png",
  contacts: (
    [✉ #link("mailto:me+resume@weihanglo.tw")[email]],
    [🌐 #link("https://weihanglo.tw")[weihanglo.tw]],
    [🐙 #link("https://github.com/weihanglo")[GitHub]],
    [💼 #link("https://www.linkedin.com/in/weihanglo/")[LinkedIn]],
  )
)

= Brief
A Rustacean that believes open source and open community would make the world a better place.

- Professional Rust developer 🦀.
- Maintainer of #ulink("https://github.com/rust-lang/cargo")[the Cargo project].
- Active member and organizer of #ulink("https://rust-lang.tw/")[the Rust Taiwan community].
- Currently focus on build systems and tools development.

= Experience
#exp(
  [#ulink("https://aws.amazon.com/")[Amazon Web Services (AWS)]],
  "Software Engineer",
  "London, United Kingdom",
  "July 2022 – Present",
  [
    - Maintain, design, and develop Cargo, the official Rust package manager and build system.
    - A member of the Rust build experience team, which builds the internal Rust build system at AWS.
    - Contributed to #ulink("https://github.com/awslabs/smithy-rs")[awslabs/smithy-rs], code generators for generating services for Rust in Rust.
  ]
)
#exp(
  [#ulink("https://suse.com")[SUSE]],
  "Senior Software Engineer",
  "Remote, Taiwan",
  "June 2021 – June 2022",
  [
    - Contributed to #ulink("https://harvesterhci.io/")[Harvester] GA release. Work on the control plane, VM integration, and disk management. Harvester is an open source HCI solution originated from SUSE and Rancher.
  ]
)

#exp(
  [#ulink("https://www.linkedin.com/company/hahow/")[Hahow]],
  "Software Engineer",
  "Taiwan",
  "March 2018 – March 2021",
  [
    - Developed autoscaling application to tackle surging demands of online-learning during COVID-19.
    - Administrated Kubernetes clusters, Helm releases, Consul datacenter, and GKE/GCE infrastructures with alert/monitoring systems and CI/CD processes.
    - Upgraded 5-year-old MongoDB cluster with minimum downtime by robust migration plan and monitoring.
    - Designed and developed the migration of legacy order system to decouple business logic from third-party payment service and data storage layer.
  ]
)
#exp(
  [#ulink("https://www.linkedin.com/company/hyweb/")[Hyweb]],
  "Software Engineer",
  "Taiwan",
  "July 2016 – March 2018",
  [
    - Given Outstanding Employee Award of 2017 (among 10 of 300 employees).
    - Hosted front-end/Swift study groups and instructed participants from R&D department.
    - Designed and developed software architecture of HyRead Ebook reader for both web and desktop platforms. HyRead is the largest B2Library Ebook service in Taiwan.
    - Developed multi-threading download scheduler for #ulink("https://apps.apple.com/app/hyread-3-立即借圖書館小說雜誌電子書/id1098612822")[HyRead 3 iOS App], which won #ulink("https://goo.gl/zyNpLq")[2018 Taiwan Excellence Award].
  ]
)

#pagebreak()

= Education
#exp(
  "National Taiwan University",
  "BSc in Agriculture Forestry and Resource Conservation",
  "Taiwan",
  "August 2012 – Jun 2016",
  [
    - Won Academic Excellence Award 3 times (for top 5% students in class each semester).
    - Bachelor thesis: _Developed computer-simulated models to imitate a biodiversity assessment method based on human decision modeling_.
    - Linux system administrator at Forest Mensuration Lab.
    - Built social corpus with data mining and machine learning techs at #ulink("https://lope.linguistics.ntu.edu.tw/")[Lab of Ontologies, Language Processing & e-Humanities].
  ]
)

= Projects
#exp(
  "The Rust Programming Language",
  "Cargo Team Member",
  [#link("https://rust-lang.org")],
  "",
  [
    Have been hacking on #ulink("https://github.com/rust-lang/cargo")[Cargo] since 2020. Became a member of the Cargo Team since 2022. Cargo is the official package manager and build tool for Rust. Some data from 2022-09 to 2023-06:
    - Focus on improving the contributor experience.
    - One of top three contributors of all time for Cargo.
    - Triaged 420+ issue with informative responses and labels.
    - Reviewed 200+ pull requests for rust-lang/cargo
    - Submitted 120+ pull requests to rust-lang/cargo
    - Mentored 11+ people from issue to pull request merged
    - See more #ulink("https://weihanglo.tw/weihanglo-achievements.pdf")[open source achievements here].
  ]
)
#exp(
  "Rust Taiwan Community",
  "Organizer",
  [#link("https://github.com/rust-tw")],
  "",
  [
    - Translated “The Rust Programming Language" book to #ulink("https://rust-lang.tw/book-tw/")[Traditional Chinese].
    - Gave a #ulink("https://bit.ly/2ZzG1iy")[talk about asynchronous programming] in COSCUP 2019.
    - Moderate Rust Taiwan Telegram and Facebook groups.
  ]
)

= Skills
- *Professional:*
  - Open source software developement and management
  - Rust, Cargo, Go, Node.js
  - MongoDB, Redis, React, GCP, NGINX
  - Kubernetes development, OS storage management
- *Has Experiences in Production:*
  - Kotlin, TypeScript, Python, Swift/Objective-C
  - PostgreSQL, SQLAlchemy, Protocol Buffer
  - Consul, Serverless, AWS CloudFormation/Lambda
  - libvirt, kvm

= Miscellaneous
- Languages: English — working proficiency, Chinese — native, Taiwanese — native.
- Open source projects contributions: `git2-rs`, `curl-rust`, `hyper`, `mdBook`, `redis-rs`, and others.
