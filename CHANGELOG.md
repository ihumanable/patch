# Change Log

## 0.14.0 (2024-10-15)

Changes where mocks are evaluated to prevent misuse and allow for common patterns that were not previously supported.

Pre-0.14.0 mocks would be intercepted by the `Patch.Mock.Server` and the mock value would be calculated by the server.  This works for most cases, but has surprising behavior when the mock function cares about the process executing the function.  Consider the following example.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  use Patch

  test "example" do
    patch(Example, :get_pid, fn -> self() end)

    assert Example.get_pid() == self()
  end
end
```

This would fail in pre-0.14.0 because the `fn -> self() end` would be executed by the `Patch.Mock.Server` and the pid returned would be the pid for the `Patch.Mock.Server` and not the caller's pid as the test author might expect.

0.14.0 changes this behavior and now will execute the `fn -> self() end` in the caller and return the expected result.  

This also makes it much more difficult to address the `Patch.Mock.Server` directly, which is generally discouraged as this server is an implementation detail and should only be addressed by the Patch code itself.  This should prevent a class of errors and confusing bugs caused by tests accidentally capturing the pid of, monitoring, or linking to the `Patch.Mock.Server`

### Improvements

- ⬆️ - \[Internal\] Mocks are now evaluated in the caller process instead of the `Patch.Mock.Server` process, see above for details.

### Breaking Changes

- 💔 - Mocks are now evaluated in the caller process instead of the `Patch.Mock.Server` process.  Using the `Patch.Mock.Server` pid or interacting with the process is not advised but if your tests relied on being able to do this they may break due to this change.

## 0.13.1 (2024-05-02)

Minor bugfix to correct an issue with negative step ranges in `String.slice/2` raised by 
- [Josephine](https://github.com/josephineweidner)
- [Hissssst](https://github.com/hissssst) 
- [Luca Corti](https://github.com/lucacorti)

### Bugfixes

- 🐞 - Fixed a warning raised from using a range with a negative step in `String.slice/2`

## 0.13.0 (2023-10-17)

Added the ability to control how Patch functions are imported in test modules.  Added the ability to `listen/3` without a target, useful when a process is spawned by another process and the spawning of that process is not within the testing boundaries.

### Features

- 🎁 - `listen/1` can now be used to construct a listener without a target.
- 🎁 - `inject/4` can now be used to inject a listener without a target.
- 🎁 - `use Patch` now accepts `:alias`, `:only`, and `:except` to control exactly which Patch helpers are being pulled in and how they will be named.

### Breaking Changes

None

## 0.12.0 (2022-02-08)

Fixed a bug where defective mock functions would be incorrectly classified as unmocked functions, this would engage the passthrough functionality and call the original function.

If a passthrough mock function's implementation raised `BadArityError` or `FunctionClauseError` it would be incorrectly classified by the mock system as an unmocked function.  The internal mechanisms have been updated to differentiate between exceptions arising directly from the function call vs exceptions in caused by executing the code in the function.

Added a new `debug/0,1` facility that can be used to enable library level debugging in for a test function.  This functionality can also be controlled by the `:patch` `:debug` configuration value.

### Features

- 🎁 - `debug/0,1` has been added. By default it will enable debugging for the test it is invoked in.  If debugging has been enabled suite wide via the `:patch` `:debug` configuration value, then `debug/1` can be used with the argument `false` to disable testing for the test it is invoked in.

### Bugfixes

- 🐞 - Fixed the issue where defective mocks would cause the mock system to call the original function.

### Improvements

- ⬆️ - \[CI\] Updated CI tests from 1.12.2 to 1.12.3 and added 1.13.2 tests to the compatibility matrix.

### Breaking Changes

None

## 0.11.0 (2022-01-21)

New `private/2` macro to assist with using exposed functions.  

Introduces "Tagged Histories" to prevent a race condition that causes confusing output when using Patch assertions.

Race Condition Description:

1. Assertion function checks the history for a matching call, none is found.
2. Assertion function pulls the history to format an error message.

Between 1 and 2 if a matching call arrived then the assertion would fail but print out a message with a matching call.

This race condition has been defeated by only pulling the history once and using it for both checking for the existence of a call and formatting an error message.

In addition a bunch of code that was littering Patch.Mock has been moved to a more appropriate location by introducing the concept of a "Tagged History" (Patch.Mock.History.Tagged)

Tagged Histories have the same entries as a History.  One generates a Tagged History from a History and some matching criteria.  Ever entry in the Tagged History is the entry from the History tagged with a boolean that indicates whether or not it matched the construction criteria.

### Features

- 🎁 - `private/2` has been added, it's similar to `private/1` but allows the test author to pipe a value into `private/2` and have it end up in the call that's being wrapped.

### Bugfixes

- 🐞 - Fixed the behavior of Patch Assertion functions to prevent the race condition described above.

### Breaking Changes

None

## 0.10.2 (2022-01-20)

Major fix to `Patch.Mock.Code.Transforms.Remote`.  Previously this transform completely ignored remote calls.  This would cause an issue when one of the arguments to the remote call was itself a local call.  This has been corrected and the `Patch.Test.User.Patch.LocalCallTest` was updated to prevent regressions.

### Bugfixes

- 🐞 - Fixed the `Patch.Mock.Code.Transforms.Remote` transformer to correctly handle the arguments of a Remote Call.

## 0.10.1 (2021-12-07)

Minor fix to `.formatter.exs`.  Exported format options were not being honored because of a typo, `export` is the honored key but `exports` was being used.

### Improvements

- ⬆️ - \[Change Log\] Removed sections that have no content, except for `Breaking Changes`.  Sections will only be included in the Change Log if some change has actually occurred.  To aid developers upgrading where between versions where breaking changes are allowed, `Breaking Changes` will be included when there are no breaking changes with the description `None` to clearly indicate that no breaking changes have occurred.
### Bugfixes

- 🐞 - Fixed the `.formatter.exs` so assertion functions won't be parenthesized by projects using `import_deps`



## 0.10.0 (2021-12-05)

Changes how function patches work by introducing "Stacked Callables."  

Stacked Callables are a large new feature that builds on the passthrough evaluation feature introduced in v0.9.0.

[Chapter 2 of the Guidebook](https://hexdocs.pm/patch/02-patching.html#stacked-callables) has a new section that explains this design in detail.

### Breaking Changes

- 💔 - Subsequent calls to patch a function with a callable result in the callables stacking.  This may break some tests if the tests rely on one callable completely replacing the previous callable.  Use `restore/2` to clear the manually clear the previous callable.

### Improvements

- ⬆️ - Stacked Callables provide a more ergonomic way to deal with multiple arities than the previous solution of using `:list` dispatch.  See [Stacking and Multiple Arities](https://hexdocs.pm/patch/02-patching.html#stacking-and-multiple-arities)
- ⬆️ - Stacked Callables provide a more composable way to deal with multiple patches that rely on pattern matching. See [Stacking and Matching](https://hexdocs.pm/patch/02-patching.html#stacking-and-matching)
- ⬆️ - `callable/2` now allows the caller to configured both the `dispatch` mode and the `evaluation` mode.  This provides a cleaner upgrade path for anyone impacted by the breaking change introduced in v0.9.0.  Using `evaluate: :strict` on a callable will make the callable act like a pre-v0.9.0 callable.

### Features

- 🎁 - `restore/2` has been added, it's similar to `restore/1` but allows the test author to restore a function in a module instead of the entire module.
- 🎁 - `callable/2` has a new clause that accepts a `Keyword.t` of options.  Supports `dispatch` which has the current dispatch modes (`:apply`, the default, or `:list`) as well as a new option `evaluate` which accepts either `:passthrough` (the default) or `:strict`.  Strict evaluation behaves like pre-v0.9.0

### Deprecations

- ⚠️ - `callable/2` will still accept an `atom` as the second argument.  When it is provided it will be used as the `dispatch` mode and the `evaluate` mode will be set to `passthrough` (the default).  This is a candidate for removal in future versions.

## 0.9.0 (2021-12-02)

Changes how function patches work so that the test author can only patch out a subset of function calls.

### Breaking Changes

- 💔 - When patching a function, calls that fail to match the patched function's clauses will passthrough to the original code.  Tests that relied on the old behavior should add a catch-all clause.

### Improvements

- ⬆️ - Improved experience when working with complex functions.  Consider a callback function like `GenServer.handle_call/3`, a test author may wish to only patch out certain messages, allowing other messages to pass through to the original code.  This is now supported, when a patched function fails to match because of either `BadArityError` or `FunctionClauseError` the original code will be called instead.

## 0.8.2 (2021-11-12)

Bugfix for handling module attributes in Call Assertions.  

### Bugfixes

- 🐞 - Fix in `Patch.Macro` to properly handle module attributes when matching.


## 0.8.1 (2021-11-12)

Bugfix for handling modules with aggregate compile attributes.  This fixes a codegen bug introduced in 0.8.0.

### Bugfixes

- 🐞 - Fix in `Patch.Mock.Code.Transforms.Clean` to properly handle aggregate compile attributes.

## 0.8.0 (2021-11-11)

Improved call assertion to use full pattern matching.  Pattern matching works like ExUnit's `assert_receive/3` and `assert_received/2`.  Unpinned variables will be bound when asserting.

### Breaking Changes

- 💔 - Matching has been improved to use full pattern semantics.  Call matching that uses `:_` should be updated to `_`.  Call assertions can now use the full range of Elixir pattern matching.
- 💔 - `inject/3` has been renamed to `replace/3`

### Improvements

- ⬆️ - Call Assertions now support full pattern matching.
- ⬆️ - \[Internal\] Code Freezer for freezing the modules that Patch uses so test authors can patch modules Patch relies on without breaking the library.

### Features

- 🎁 - Renamed `inject/3` to `replace/3` which better conveys its functionality
- 🎁 - Added `inject/4` which injects a listener into a running process.

### Bugfixes

- 🐞 - Code Freezer fixes a bug where patching `GenServer` caused Patch to deadlock.

### Removals

- ⛔️ - `inject/3` was removed and renamed to `replace/3`

## 0.7.0 (2021-10-21)

Support for call counts in assertions.  `assert_called/1` and `refute_called/1` are unchanged.

### Breaking Changes

None

### Improvements

- ⬆️ - Exception messages have been improved to clearly indicate which calls have matched.
- ⬆️ - Assertion Macros have been refactored to minimize injected code in line with Elixir best practices.  Macros now defer to `Patch.Assertions`
- ⬆️ - Increased test coverage for assertions including improved message formatting.

### Features

- 🎁 - Added the `assert_any_call/1` macro.  This is now the preferred over `assert_any_call/2`, it allows the test author to write `assert_any_call Module.function` instead of `assert_any_call Module, :function`
- 🎁 - Added the `assert_called/2` assertion.  The second argument is a call count, this assertion will only pass if there is exactly call count matching calls.
- 🎁 - Added the `assert_called_once/1` assertion.  This assertion only passes if there is one and only one matching call.
- 🎁 - Added the `refute_any_call/1` macro.  This is now preferred over `refute_any_call/2`, it allows the test author to write `refute_any_call Module.function` instead of `refute_any_call Module, :function`
- 🎁 - Added the `refute_called/2` assertion.  The second argument is a call count, this assertion will pass as long as the number of matching calls does not equal the provided call count.
- 🎁 - Added the `refute_called_once/1` assertion.  This assertion will pass if there are any number of matching calls besides 1.

### Deprecations

- ⚠️ - Soft Deprecation for `assert_any_call/2`.  This function is **not** slated for removal but should be reserved for advanced use cases.  Test authors should prefer `assert_any_call/1` when possible.
- ⚠️ - Soft Deprecation for `refute_any_call/2`.  This function is **not** slated for removal but should be reserved for advanced use cases.  Test authors should prefer `refute_any_call/1` when possible.

## 0.6.1 (2021-10-17)

Minor release to improve the documentation and reduce the scope of imported symbols from `Patch.Mock.Value`.

### Improvements

- ⬆️ - \[Documentation\] Guide Book broken into Chapters, additional information about core concepts.

### Removals

- ⛔️ - `Patch.Mock.Value.advance/1` and `Patch.Mock.Value.next/2` used to be imported into the test when `use Patch` was present.  This was an oversight and these two functions are not meant to be called directly by the test author, the imports have been reduced to remove these symbols.

## 0.6.0 (2021-10-16)

Major internal refactor.  This version removes `meck` as a dependency and implements a Patch specific replacement, `Patch.Mock`.  This allows us to have a new set of functionality that no other mocking library for Elixir / Erlang has today.  

Patch Mocks can now be said to obey a single simple rule, public or private, local or remote.

A patched function **always** returns the mock value to all callers.

Two new bits of functionality make this true.

1.  All calls, local or remote, end up intercepted and the mock value returned.
2.  Private functions can be mocked.

And as a bonus

1.  Private functions can be converted into public functions for direct testing.

### Breaking Changes

- 💔 - Matching semantics have changed since `meck` is no longer the matching engine.  Matching is now literal instead of pseudo-matching, upgrade to version 0.8.0+ for improved matching.

### Improvements

- ⬆️ - \[Internal\] `Patch.Mock` introduced to replace `meck`
- ⬆️ - \[Documentation\] README revamped again, new Super Powers documentation and Guide Book.

### Features

- 🎁 - Added the `expose/2` function to support testing private functions.
- 🎁 - Added the `history/1,2` function so the history of calls to a mock can be retrieved.
- 🎁 - Added the `private/1` macro to prevent compiler warnings when calling private functions.
- 🎁 - Added the `callable/1,2` value builder to create explicit callable mock values.
- 🎁 - Added the `cycle/1` value builder to create a cycle mock values.
- 🎁 - Added the `raises/1` value builder to cause a mocked function to raise a RuntimeError.
- 🎁 - Added the `raises/2` value builder to cause a mocked function to raise any other Exception.
- 🎁 - Added the `scalar/1` value builder to create explicit scalar mock values.
- 🎁 - Added the `sequence/1` value builder to create sequence mock values.
- 🎁 - Added the `throws/1` value builder to cause a mocked function to throw a value.

### Removals

- ⛔️ - \[Dependency\] `meck` was removed as a dependency

## 0.5.0 (2021-09-17)

Better support for mocking erlang modules

### Breaking Changes

None
### Improvements

- ⬆️ - \[Internal\] `patch.release` task to simplify releasing new versions of the library
- ⬆️ - Support for mocking erlang modules (both sticky and non-sticky)

### Bugfixes

- 🐞 - Mocking erlang modules actually works now

## 0.4.0 (2021-08-09)

Support for working with Processes

### Breaking Changes

None
### Improvements

- ⬆️ - \[Testing\] Testing Matrix updated to latest versions of Elixir / OTP
- ⬆️ - \[Dependencies\] `meck` updated to 0.9.2
- ⬆️ - \[Documentation\] README revamped

### Features

- 🎁 - Added the `listen/3` function to support listening to a process's messages
- 🎁 - Added the `inject/3` function to support updating the state of a running process.
## 0.3.0 (2021-07-12)

Support for replacing a module wholesale via the `fake/2` function

### Breaking Changes

None
### Improvements

- ⬆️ - [Internal] `Patch.Function.for_arity/2` now accepts an anonymous function it will call instead of a term to return.
- ⬆️ - [Internal] `Patch.find_functions/1` and `Patch.find_arities/2` use `__info__/1` now instead of doing 256 `function_exported?` checks per function.

### Features

- 🎁 - Added the `fake/2` function to add support for module fakes.
- 🎁 - Added the `real/1` function so module fakes can call the real module.

## 0.2.0 (2021-03-03)

Removed Arity Limitations

### Breaking Changes

None
### Improvements

- ⬆️ - Removed the arity limitation, can now patch functions of any arity

### Features

- 🎁 - Added the `assert_any_call/2` and `refute_any_call/2` assertion functions

## 0.1.2 (2021-01-28)

Increased Elixir Compatibility

### Improvements

- ⬆️ - Relaxed Elixir version requirement down to 1.7

## 0.1.1 (2020-04-27)

Bugfix Release

### Improvements

- ⬆️ - Made the library actually work

### Bugfixes

- 🐞 - Bugfix to make the library actually work

## 0.1.0 (2020-04-21)

Initial Release

### Breaking Changes

None

### Improvements

- ⬆️ - Patch released to the world.  Easy to use and ergonomic Mocking for Elixir.

### Features

- 🎁 - `patch/3` allows the patching of a module's function with a function.
- 🎁 - `patch/3` allows the patching of a module's function with a static return value.
- 🎁 - `spy/1` allows spying on a module.
- 🎁 - `restore/1` allows removing patches and spies from a module.
- 🎁 - `assert_called/1` allows for asserting that a patched or spied function has been called with the expected pattern of arguments.
- 🎁 - `refute_called/1` allows for refuting that a patched or spied function has been called with the expected pattern of arguments.