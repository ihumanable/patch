# Patch

[![CI](https://github.com/ihumanable/patch/workflows/CI/badge.svg)](https://github.com/ihumanable/patch/actions)
[![Hex.pm Version](http://img.shields.io/hexpm/v/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![Hex.pm License](http://img.shields.io/hexpm/l/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![HexDocs](https://img.shields.io/badge/HexDocs-Yes-blue)](https://hexdocs.pm/patch)

Patch - Ergonomic Mocking for Elixir

Patch makes it easy to replace functionality in tests with test specific functionality.  Patch augments ExUnit with several utilities that make writing tests in Elixir fast and easy.  Patch includes unique functionality that no other mocking library for Elixir provides, Patch's [Super Powers](https://hexdocs.pm/patch/super-powers.html).

## Features

Why use Patch instead of meck, Mock, Mockery, Mox, etc?  

Patch starts with a very simple idea for how a patched function should work.

> Patched functions should **always** return the mock value they are given.

Here are the key features of Patch.

1. Easy-to-use and composable interface with sensible defaults.
2. First class support for working with Processes.
3. No testing code in non-test code.

In addition to these features which many libraries aspire to, Patch has 3 additional features that no other mocking library for Elixir / Erlang seem to have.  These [Super Powers](https://hexdocs.pm/patch/super-powers.html) are 

1. Patch mocks are effective for both local and remote calls.  This means a patched function **always** resolves to the patch.
2. Patch can patch private functions without changing their visibility.
3. Patch makes it possible to test your private functions without changing their visibility via the `expose/2` functionality.  

See the [Mockompare](https://github.com/ihumanable/mockompare) companion project for a comparison of Elixir / Erlang mocking libraries.  If there is a way to accomplish the following with another library, please open an issue so this section and the comparisons can be updated.

For more information about Patch's Super Powers see the [Super Powers Documentation](https://hexdocs.pm/patch/super-powers.html)

## Table of Contents

- [Installation](#installation)
- [Quickstart](#quickstart)
  - [Core Functions](#core-functions)
  - [Assertions](#assertions)
  - [Value Builders](#value-builders)
  - [Customizing Imports](#customizing-imports)
- [Guide Book](#guide-book)
- [Support Matrix](#support-matrix)
- [Limitations](#limitations)
- [Prior Art](#prior-art)
- [Changelog](#changelog)

## Installation

Add patch to your mix.exs

```elixir
def deps do
  [
    {:patch, "~> 0.14.0", only: [:test]}
  ]
end
```

## Quickstart

After adding the dependency just add the following line to any test module after using your test case

```elixir
use Patch
```

This library comes with a comprehensive suite of unit tests.  These tests not only verify that the library is working correctly but are designed so that for every bit of functionality there is an easy to understand example for how to use that feature.  Check out the [User Tests](https://github.com/ihumanable/patch/tree/master/test/user) for examples of how to use each feature.

Using Patch adds 11 core functions, 10 assertions, 7 mock value builders, and 1 utility function to the test.  These imports can be controlled, see the [Customizing Imports](#customizing-imports) for details.

See the [Cheatsheet](https://hexdocs.pm/patch/cheatsheet.html) for an overview of how the library can be used and as a handy reference.  Continue below for links to more in-depth documentation including the [Guidebook](https://hexdocs.pm/patch/01-introduction.html).

### Core Functions

Core functions let us apply patches, patch processes, intercept messages, and query our patched modules.

| Core Function                                                | Description                                                                          |
|--------------------------------------------------------------|--------------------------------------------------------------------------------------|
| [expose/2](https://hexdocs.pm/patch/Patch.html#expose/2)     | Expose private functions as public for the purposes of testing                       |
| [fake/2](https://hexdocs.pm/patch/Patch.html#fake/2)         | Replaces a module with a fake module                                                 |
| [history/1,2](https://hexdocs.pm/patch/Patch.html#history/2) | Returns the call history for a mock                                                  |
| [inject/3,4](https://hexdocs.pm/patch/Patch.html#inject/4)   | Injects a listener into a GenServer                                                  |
| [listen/3](https://hexdocs.pm/patch/Patch.html#listen/3)     | Intercepts messages to a process and forwards them to the test process               |
| [patch/3](https://hexdocs.pm/patch/Patch.html#patch/3)       | Patches a function so that it returns a mock value                                   |
| [private/1](https://hexdocs.pm/patch/Patch.html#private/1)   | Macro to call exposed private functions without raising a compiler warning           |
| [real/1](https://hexdocs.pm/patch/Patch.html#real/1)         | Resolves the real module for a patched module                                        |
| [replace/3](https://hexdocs.pm/patch/Patch.html#replace/3)   | Replaces part of the state of a GenServer                                            |
| [restore/1,2](https://hexdocs.pm/patch/Patch.html#restore/1) | Restores an entire module or just a function within a module to its pre-patched form |
| [spy/1](https://hexdocs.pm/patch/Patch.html#spy/1)           | Patches a module so calls can be asserted without changing behavior                  |

### Assertions

Assertions make it easy to assert that a patched module has or has not observed a call.

| Assertion                                                                        | Description                                                                                                   |
|----------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| [assert_any_call/1](https://hexdocs.pm/patch/Patch.html#assert_any_call/1)       | Asserts that any call of any arity has occurred on the mocked module for a function name (preferred macro)    |
| [assert_any_call/2](https://hexdocs.pm/patch/Patch.html#assert_any_call/2)       | Asserts that any call of any arity has occurred on the mocked module for a function name (advanced use cases) |
| [assert_called/1](https://hexdocs.pm/patch/Patch.html#assert_called/1)           | Asserts that a particular call has occurred on a mocked module                                                |
| [assert_called/2](https://hexdocs.pm/patch/Patch.html#assert_called/2)           | Asserts that a particular call has occurred a given number of times on a mocked module                        |
| [assert_called_once/1](https://hexdocs.pm/patch/Patch.html#assert_called_once/2) | Asserts that a particular call has occurred exactly once on a mocked module                                   |
| [refute_any_call/1](https://hexdocs.pm/patch/Patch.html#refute_any_call/1)       | Refutes that any call of any arity has occurred on the mocked module for a function name (preferred macro)    |
| [refute_any_call/2](https://hexdocs.pm/patch/Patch.html#refute_any_call/2)       | Refutes that any call of any arity has occurred on the mocked module for a function name (advanced use cases) |
| [refute_called/1](https://hexdocs.pm/patch/Patch.html#refute_called/1)           | Refutes that a particular call has occurred on a mocked module                                                |
| [refute_called/2](https://hexdocs.pm/patch/Patch.html#refute_called/2)           | Refutes that a particular call has occurred a given number of time on a mocked module                         |
| [refute_called_once/1](https://hexdocs.pm/patch/Patch.html#refute_called_once/1) | Refutes that a particular call has occurred exactly once on a mocked module                                   |

### Value Builders

Patched functions aren't limited to only returning simple scalar values, a host of Value Builders are provided for all kinds of testing scenarios.  See the [patch](https://hexdocs.pm/patch/Patch.html#patch/3) documentation for details.

| Value Builder                                                             | Description                                                                                              |
|---------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| [callable/1,2](https://hexdocs.pm/patch/Patch.Mock.Value.html#callable/2) | Callable that will be invoked on every patch invocation, dispatch and evaluation modes can be customized |
| [cycle/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#cycle/1)         | Cycles through the values provided on every invocation                                                   |
| [raises/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#raises/1)       | Raises a RuntimeException with the given message upon invocation                                         |
| [raises/2](https://hexdocs.pm/patch/Patch.Mock.Value.html#raises/2)       | Raises the specified Exception with the given attribtues upon invocation                                 |
| [scalar/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#scalar/1)       | Returns the argument as a literal, useful for returning functions                                        |
| [sequence/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#sequence/2)   | Returns the values in order, repeating the last value indefinitely                                       |
| [throws/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#throws/1)       | Throws the given value upon invocation                                                                   |

### Utility Functions

Patch comes with some utilities that can assist when tests aren't behaving as expected.

| Utility Function                                         | Description                                   |
|----------------------------------------------------------|-----------------------------------------------|
| [debug/0,1](https://hexdocs.pm/patch/Patch.html#debug/1) | Enable or Disable debug mode for a given test |

### Customizing Imports

By default, Patch will import the functions listed in the previous sections.  Imports can be customized through the `:only`, `:except` and `:alias` options.

`:only` and `:except` work similiarly to how they work for the `import` except the values are either a list of symbol atoms or the special atom `:all`.

Here's how only the `expose`, `patch`, and `private` symbols can be imported.

```elixir
use Patch, only: [:expose, :patch, :private]
```

Here's how every symbol except `throws` can be imported

```elixir
use Patch, except: [:throws]
```

Patch also allows you to alias imported symbols, to import `patch` as `mock` the following would be used.

```elixir
use Patch, alias: [patch: :mock]
```

## Guide Book

Patch comes with [plenty of documentation](https://hexdocs.pm/patch) and a [Suite of User Tests](https://github.com/ihumanable/patch/tree/master/test/user) that show how to use the library.  

For a guided tour and deep dive of Patch, see the [Guide Book](https://hexdocs.pm/patch/01-introduction.html)

## Support Matrix

Tests automatically run against a matrix of OTP and Elixir Versions, see the [ci.yml](https://github.com/ihumanable/patch/tree/master/.github/workflows/ci.yml) for details.

| OTP \ Elixir | 1.9  | 1.10 | 1.11 | 1.12 | 1.13 | 1.14 | 1.15 | 1.16 | 1.17 | 1.18 |
|:------------:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
| 20           | ✅   | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  |
| 21           | ✅   | ✅   | ✅   | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  | N/A  |
| 22           | ✅   | ✅   | ✅   | ✅   | ✅   | N/A  | N/A  | N/A  | N/A  | N/A  |
| 23           | N/A  | ✅   | ✅   | ✅   | ✅   | ✅   | N/A  | N/A  | N/A  | N/A  |
| 24           | N/A  | N/A  | ✅   | ✅   | ✅   | ✅   | ✅   | N/A  | N/A  | N/A  |
| 25           | N/A  | N/A  | N/A   | N/A   | ✅   | ✅   | ✅   | ✅   | ✅   | ?    |
| 26           | N/A  | N/A  | N/A   | N/A   | N/A   | ✅   | ✅   | ✅   | ✅   | ✅   |
| 27           | N/A  | N/A  | N/A   | N/A   | N/A   | N/A   | N/A   | N/A   | ✅   | ✅   |

## Limitations

Patch works by recompiling modules, this alters the global execution environment. 

Since the global execution environment is altered by Patch, **Patch is not compatible with async: true**.

## Prior Art

Up to version 0.5.0 Patch was based off the excellent [meck](https://hex.pm/packages/meck) library.  Patch [Super Powers](https://hexdocs.pm/patch/super-powers.html) required a custom replacement for meck, `Patch.Mock`.  

Patch also takes inspiration from python's [unittest.mock.patch](https://docs.python.org/3/library/unittest.mock.html#patch) for API design.

## Contributors

Patch is made better everyday by developers requesting new features.  

- [daisyzhou](https://github.com/daisyzhou)
  - Suggested the new function pass through behavior introduced in v0.9.0
- [likeanocean](https://github.com/likeanocean)
  - Suggested `assert_called/2`, `assert_called_once/1`, `refute_called/2`, and `refute_called_once/1` introduced in v0.7.0
- [birarda](https://github.com/birarda)
  - Suggested `assert_any_call/2`, `refute_any_call/2` introduced in v0.2.0
  - Suggested `listen/1` introduced in v0.13.0 to listen without a target.
- [kianmeng](https://github.com/kianmeng)
  - Corrected several typographical errata
  - Improved the ci.yml, brining it up to date with best practices.
- [Dorgan](https://github.com/doorgan)
  - Reported erratum in the Patch Cheatsheet
- [Luca Corti](https://github.com/lucacorti)
  - Reported an issue with warning being emitted by the library on Elixir 1.16 which served as the basis for a bugfix in v0.13.1

If you have a suggestion for improvements to this library, please open an issue.

## Changelog

See the [Changelog](CHANGELOG.md)