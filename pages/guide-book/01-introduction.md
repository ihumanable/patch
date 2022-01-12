# Chapter 1: Introduction

This guide book will walk you through using all the features and functionality of `Patch` to make great unit tests.

## One Big Idea

Patch is founded on One Big Idea

> Patched functions should **always** return the mock value they are given.

This is how patched functions behave in `Patch`.  Every function is a valid target for patching and once patched the function will always return the mock value given.  If you ever feel lost, remember this One Big Idea.

## Terminology

Throughout this guide book we are going to use some common terminology, let's define them.

### Patch

Patch is used as both a verb and a noun.  To "patch" a function is to replace it with an alternative implementation.  The alternative implementation is the noun form of "patch" sometimes called the "patched function."  

```elixir
patch(Example, :example, :patched)
```

> `Example.example` has been "patched" with a "patch" that always returns the value `:patched`

### Mock Value

The value returned by a "patch" is referred to as the "mock value".  There are a number of types of "mock values" that will be covered in detail in this guide book.

### Observed Call

After a module has been patched, the calls to the module can be observed by `Patch`.  `Patch` comes with utilities to assert or refute that certain calls have been observed.

Calls that happen before the module has been patched are unobserved, the test author can not assert or refute anything about the calls to a module before it has been patched.
