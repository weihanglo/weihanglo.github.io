---
title: "Rust: Ownership and References"
date: 2018-09-30T11:07:45+08:00
tags:
  - Rust
---

This is a series of quick notes about the fundamentals of [the Rust programming language](https://rust-lang.org). It would cover parts of basic concepts and patterns in Rust. As a Rust begineer and a non-native English speaker, I may make some silly mistakes in my notes. Please contact me if there are some misleading words.

<!-- more -->

## Ownership and References

While a program runs, it need a way to manage memory . Here are three common approaches of memory management:

- Garbage collection. (Go, Python, Ruby, Swift)
- Explicit allocation and free memory. (C, C++)
- Ownership/move semantic. (Rust, C++11 move constructor)

This note is about core concepts of Rust ownership and how ownership interacts with other features such as references and lifetime.

## Ownership

### Rust Ownership Rules

1. Each value in Rust has a variable that’s called its *owner*.
2. There can only be one owner at a time.
3. When the owner goes out of scope, the value will be dropped.

> Actually, you only need to remember one thing: Rust guarantees its memory safety by **restricting variables from aliasing**.

### Stack v.s. Heap

To determine where to store a variable, Rust categorizes varaibles into two groups - stack and heap allocations. Here are some properties held by each procedure.

**Store in stack**

- Need to know the size of value at compile time. 
- Since the size is known, when the variable get out of scope, the compiler can free the variable automatically.

**Store in heap**

- To store a value in heap, you need to request a region of memory from the operating system. 
- When cleaning up unused data, you need to explicit free the memory.

As same as C++ [RAII pattern](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization), Rust has a special method on object called `drop` that would be called automatically when a variable goes out of scope. For example:

```rust
{                      // s is not valid here, it’s not yet declared
    let s = "hello";   // s is valid from this point forward

    // do stuff with s
}                      // the scope is over. 
                       // `drop` is called, and s is no longer valid.

```

The question is, if a variable is allocated on heap with multiple aliases, we may not be able to track down where all aliases are in used. Explicitly call `drop` can lead some aliases to become dangling pointers or cause a double free error. And ownership to the rescue!

## Move, Clone and Copy

**Move:** To stop from double free errors, Rust utilize *move semantics*. If a variable is aliased to the other. You cannot access underlying value from the former variables.

```rust
let s1 = String::from("hello");
let s2 = s1;

println!("{}, world!", s1); // Error. Value is moved.
```

All the data on heap will move its ownership to `s2`. Now, `s1` is no longer available.

![](https://doc.rust-lang.org/book/second-edition/img/trpl04-04.svg)

**Clone:** When you do want to keep the ownership of the variable, explicitly call `clone` may perform a shallow copy.

```rust
let s1 = String::from("hello");
let s2 = s1.clone();

println!("s1 = {}, s2 = {}", s1, s2);
```

![](https://doc.rust-lang.org/book/second-edition/img/trpl04-02.svg)

**Copy:** Sometimes if a type implements `Copy` trait, it instead has *copy semantics*. That means `clone` would be performed automatically when aliasing variables.

```rust
let s1 = 1234_u8;
let s2 = s1;

println!("s1 = {}, s2 = {}", s1, s2);
// s2 is an copy of s1.
```

### Function and Ownership

**Function parameters:** passing value to function as parameters is semantically same as assignment. For example,


```rust
fn takes_ownership(some_string: String) { // some_string comes into scope
    println!("{}", some_string);
} // Here, some_string goes out of scope and `drop` is called. The backing
  // memory is freed.
```

**Return values:** the ownership can also be transferred out to the caller. 

```rust
// takes_and_gives_back will take a String and return one
fn takes_and_gives_back(a_string: String) -> String { // a_string comes into
                                                      // scope
    a_string  // a_string is returned and moves out to the calling function
}
```

## References

Ownership is about a variable owns the value. What about sharing value among multiple variables? Here comes the concepts of *references*.

The properties of Rust references are described as below:

- Similar behavior comparing to C pointer. 
- Use `&` to annotate reference type.
- Use `*` to dereference.
- Use `.` (dot) to access method/field under a reference to a struct/enum type.
- No null pointer. Use `[Option](https://doc.rust-lang.org/std/option/index.html)` instead.
- Mostly the word “*reference*” is interchangeable with “*borrow*” in Rust.


```rust
let a: &str = "string"; 

fn calculate_length(s: &String) -> usize { // s is a reference to a String
    s.len()
} // Here, s goes out of scope. But because it does not have ownership of what
  // it refers to, nothing happens.
```

### Rules

All references in Rust must follow at lease two rules:

- Having several immutable references (`&T`) or exact one mutable reference (`&mut T`).
- A reference must always be valid even it references to null.
  (use `Option:None` to represent null)

### Lifetime

A reference may be invalid and become a dangling pointer if the owner is dropped. Accessing that reference would cause a undefined behavior. To solve this kind of error, Rust introduces **lifetime** validation for all reference types.

Here are some characteristics of references’ lifetime:

- A lifetime of a reference is the scope for which the reference is valid.
- Every reference in Rust has its own lifetime.
- Lifetimes is a part of Rust type system. Different lifetimes are seem as different types.
- In most cases, lifetimes are implicit inferred as same as how type being inferred.

Rust compiler use a mechanism called *borrow checker* to determine all lifetimes of variables are valid. The following example is invalid due to `x` cannot “outlive” the outer scope which is longer than its lifetime. 

```rust
// would fail to compile
fn main() {
    let r;                // ---------+-- 'a
                          //          |
    {                     //          |
        let x = 5;        // -+-- 'b  |
        r = &x;           //  |       |
    }                     // -+       |
                          //          |
    println!("r: {}", r); //          |
}                         // ---------+
```

To annotate lifetime of a type, Rust use quirk syntax as followings:

```rust
&i32        // a reference
&'a i32     // a reference with an explicit lifetime
&'a mut i32 // a mutable reference with an explicit lifetime
```

A lifetime annotation seldom appears alone. It serves as a annotations to generics to imply how references relate to each other. We will cover this part at [Generics](https://weihanglo.tw/posts/rust-generics).

### No More Null Pointers

In languages with null, variables can always be in one of two states: null or not null. To ensure that accessing your references is safe, you must check whether a reference is null every time you use it.

*Rust does not have null.*

Sounds crazy, huh? Actually, Rust wraps null value into `Option<T>` type to make sure no one would access invalid reference or value. `Option<T>` is defined as an enum:

```rust
    enum Option<T> {
        Some(T),
        None,
    }
```

To access value under an `Option` type, one needs to unwrap it instead of direct manipulation. This extra step throw out the infamous null pointer exception in many languages. For example, 

```rust
let x: i8 = 5;
let y: Option<i8> = Some(5);

let sum = x + y; // cannot compile, you need to unwrap it.
let sum = x + y.unwrap() // Valid!
```

With the power of pattern matching in Rust, you can even handle `Option` type more gracefully without explicit wrapping. Read more about `[enum](https://doc.rust-lang.org/book/second-edition/ch06-00-enums.html)` and `[Option](https://doc.rust-lang.org/std/option/enum.Option.html)` type.

### Raw Pointers

In unsafe Rust world, we have **raw pointers**, `* const T` and `*mut T`, to do more unsafe stuff at your will. That means raw pointers can ignore borrowing rules and is able to be null. We devote the whole [Unsafe Rust](https://weihanglo.tw/posts/2018/unsafe-rust) post to introduce the unsafe concept.

## Further Resources

- [The Rust Programming Language - 2018 Edition](https://doc.rust-lang.org/book/2018-edition/index.html)
- Some images and code snippets are **borrowed** from TRPL.

