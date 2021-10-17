# Patch

[![CI](https://github.com/ihumanable/patch/workflows/CI/badge.svg)](https://github.com/ihumanable/patch/actions)
[![Hex.pm Version](http://img.shields.io/hexpm/v/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![Hex.pm License](http://img.shields.io/hexpm/l/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![HexDocs](https://img.shields.io/badge/HexDocs-Yes-blue)](https://hexdocs.pm/patch)

Patch - Ergonomic Mocking for Elixir

Patch makes it easy to replace functionality in tests with test specific functionality.  Patch augments ExUnit with several utilities that make writing tests in Elixir fast and easy.  Patch includes unique functionality that no other mocking library for Elixir provides, Patch's [Super Powers](#super-powers).

## Features

Why use Patch instead of meck, Mock, Mockery, Mox, etc?  

Here are the key features of Patch.

1. Easy-to-use and composable interface with sensible defaults.
2. First class support for working with Processes.
3. No testing code in non-test code.

In addition to these features which many libraries aspire to, Patch has 2 additional features that no other mocking library for Elixir / Erlang seem to have.  These two "Super Powers" are 

1.  Patch makes it possible to test your private functions without changing their visibility via the `expose/2` functionality.  
2.  Patch mocks are effective for both local and remote calls.  This means a patched function **always** resolves to the patch.

See the [Mockompare](https://github.com/ihumanable/mockompare) companion project for a comparison of Elixir / Erlang mocking libraries.  If there is a way to accomplish the following with another library, please open an issue so this section and the comparisons can be updated.

For more information about Patch's Super Powers see the [Super Powers Documentation](https://hexdocs.pm/patch/super-powers.html)

## Table of Contents

- [Installation](#installation)
- [Quickstart](#quickstart)
  - [Core Functions](#core-functions)
  - [Assertions](#assertions)
  - [Value Builders](#value-builders)
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
    {:patch, "~> 0.5.0", only: [:test]}
  ]
end
```

## Quickstart

After adding the dependency just add the following line to any test module after using your test case

```elixir
use Patch
```

This library comes with a comprehensive suite of unit tests.  These tests not only verify that the library is working correctly but are designed so that for every bit of functionality there is an easy to understand example for how to use that feature.  Check out the [User Tests](https://github.com/ihumanable/tree/master/test/user) for examples of how to use each feature.

Using Patch adds 10 core functions, 4 assertions, and 7 mock value builders to the test.

### Core Functions

| Core Function                                                | Description                                                                |
|--------------------------------------------------------------|----------------------------------------------------------------------------|
| [expose/2](https://hexdocs.pm/patch/Patch.html#expose/2)     | Expose private functions as public for the purposes of testing             |
| [fake/2](https://hexdocs.pm/patch/Patch.html#fake/2)         | Replaces a module with a fake module                                       |
| [history/1,2](https://hexdocs.pm/patch/Patch.html#history/2) | Returns the call history for a mock                                        |
| [inject/3](https://hexdocs.pm/patch/Patch.html#inject/3)     | Injects state into a GenServer                                             |
| [listen/3](https://hexdocs.pm/patch/Patch.html#listen/3)     | Intercepts messages to a process and forwards them to the test process     |
| [patch/3](https://hexdocs.pm/patch/Patch.html#patch/3)       | Patches a function so that it returns a mock value                         |
| [private/1](https://hexdocs.pm/patch/Patch.html#private/1)   | Macro to call exposed private functions without raising a compiler warning |
| [real/1](https://hexdocs.pm/patch/Patch.html#real/1)         | Resolves the real module for a patched module                              |
| [restore/1](https://hexdocs.pm/patch/Patch.html#restore/1)   | Restores a module to its pre-patched form                                  |
| [spy/1](https://hexdocs.pm/patch/Patch.html#spy/1)           | Patches a module so calls can be asserted without changing behavior        |

### Assertions

| Assertion                                                                  | Description                                                                              |
|----------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [assert_called/1](https://hexdocs.pm/patch/Patch.html#assert_called/1)     | Asserts that a particular call has occurred on a mocked module                           |
| [assert_any_call/2](https://hexdocs.pm/patch/Patch.html#assert_any_call/2) | Asserts that any call of any arity has occurred on the mocked module for a function name |
| [refute_called/1](https://hexdocs.pm/patch/Patch.html#refute_called/1)     | Refutes that a particular call has occurred on a mocked module                           |
| [refute_any_call/2](https://hexdocs.pm/patch/Patch.html#refute_any_call/2) | Refutes that any call of any arity has occured on the mocked module for a function name  |

### Value Builders

| Value Builder                                                             | Description                                                                              |
|---------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [callable/1,2](https://hexdocs.pm/patch/Patch.Mock.Value.html#callable/2) | Callable that will be invoked on every patch invocation, dispatch mode can be customized |
| [cycle/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#cycle/1)         | Cycles through the values provided on every invocation                                   |
| [raises/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#raises/1)       | Raises a RuntimeException with the given message upon invocation                         |
| [raises/2](https://hexdocs.pm/patch/Patch.Mock.Value.html#raises/2)       | Raises the specified Exception with the given attribtues upon invocation                 |
| [scalar/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#scalar/1)       | Returns the argument as a literal, useful for returning functions                        |
| [sequence/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#sequence/2)   | Returns the values in order, repeating the last value indefinitely                       |
| [throws/1](https://hexdocs.pm/patch/Patch.Mock.Value.html#throws/1)       | Throws the given value upon invocation                                                   |


## Guide Book

Patch comes with [plenty of documentation](https://hexdocs.pm/patch) and a [Suite of User Tests](https://github.com/ihumanable/tree/master/test/user) that show how to use the library.  

For a guided tour and deep dive of Patch, see the [Guide Book](https://hexdocs.pm/patch/guide-book.html)

## Support Matrix

Tests automatically run against a matrix of OTP and Elixir Versions, see the [ci.yml](https://github.com/ihumanable/patch/tree/master/.github/workflows/ci.yml) for details.

| OTP \ Elixir | 1.7  | 1.8  | 1.9  | 1.10 | 1.11 | 1.12 |
|:------------:|:----:|:----:|:----:|:----:|:----:|:----:|
| 20           | ✅   | ✅   | ✅   | N/A  | N/A  | N/A  |
| 21           | ✅   | ✅   | ✅   | ✅   | ✅   | N/A  |
| 22           | ✅   | ✅   | ✅   | ✅   | ✅   | ✅   |
| 23           | N/A  | N/A  | N/A  | ✅   | ✅   | ✅   |
| 24           | N/A  | N/A  | N/A  | N/A  | ✅   | ✅   |

## Limitations

Patch works by recompiling modules, this alters the global execution environment. 

Since the global execution environment is altered by Patch, **Patch is not compatible with async: true**.

## Prior Art

Up to version 0.5.0 Patch was based off the excellent [meck](https://hex.pm/packages/meck) library.  Patch [Super Powers](https://hexdocs.pm/patch/super-powers.html) required a custom replacement for meck, `Patch.Mock`.  

Patch also takes inspiration from python's [unittest.mock.patch](https://docs.python.org/3/library/unittest.mock.html#patch) for API design.
## Changelog

See the [Changelog](CHANGELOG.md)