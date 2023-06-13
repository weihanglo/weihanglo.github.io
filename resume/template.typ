#let cv(author: "", img: "", contacts: (), body) = {
  set document(author: author, title: author)

  show heading: it => [
    #pad(bottom: -10pt, [#smallcaps(it.body)])
    #line(length: 100%, stroke: 1pt)
  ]

  if img.len() > 0 {
    align(center)[#image(img, height: 3em)]
  }

  // Author
  align(center)[
    #block(text(weight: 700, 2em, author))
  ]

  // Contact information.
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    align(center)[
      #grid(
        columns: 4,
        gutter: 1em,
        ..contacts
      )
    ],
  )

  // Main body.
  set par(justify: true)

  body
}

#let exp(place, title, location, time, details) = {
  pad(
    grid(
      columns: (auto, 1fr),
      align(left)[
        *#place* \
        #emph[#title]
      ],
      align(right)[
        #location \
        #time
      ]
    )
  )
  pad(bottom: 5%, details)
}

#let ulink(url, name) = {
  underline(link(url, name))
}
