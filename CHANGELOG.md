# Change Log

## 0.9.0 (2021-12-02)

Changes how function patches work so that the test author can only patch out a subset of function calls.

### Breaking Changes

- 💔 - When patching a function, calls that fail to match the patched function's clauses will passthrough to the original code.  Tests that relied on the old behavior should add a catch-all clause.
### Improvements

- ⬆️ - Improved experience when working with complex functions.  Consider a callback function like `GenServer.handle_call/3`, a test author may wish to only patch out certain messages, allowing other messages to pass through to the original code.  This is now supported, when a patched function fails to match because of either `BadArityError` or `FunctionClauseError` the original code will be called instead.

### Features

None

### Bugfixes

None

### Deprecations

None

### Removals

None

## 0.8.2 (2021-11-12)

Bugfix for handling module attributes in Call Assertions.  

### Improvements

None

### Features

None

### Bugfixes

- 🐞 - Fix in `Patch.Macro` to properly handle module attributes when matching.

### Deprecations

None

### Removals

None



## 0.8.1 (2021-11-12)

Bugfix for handling modules with aggregate compile attributes.  This fixes a codegen bug introduced in 0.8.0.

### Improvements

None

### Features

None

### Bugfixes

- 🐞 - Fix in `Patch.Mock.Code.Transforms.Clean` to properly handle aggregate compile attributes.

### Deprecations

None

### Removals

None

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

### Deprecations

None

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
- 🎁 - Added the `refute_called/2` assertion.  The second argument is a call count, this assertion will pass as long as the numebr of matching calls does not equal the provided call count.
- 🎁 - Added the `refute_called_once/1` assertion.  This assertion will pass if there are any number of matching calls besides 1.

### Bugfixes

None

### Deprecations

- ⚠️ - Soft Deprecation for `assert_any_call/2`.  This function is **not** slated for removal but should be reserved for advanced use cases.  Test authors should prefer `assert_any_call/1` when possible.
- ⚠️ - Soft Deprecation for `refute_any_call/2`.  This function is **not** slated for removal but should be reserved for advanced use cases.  Test authors should prefer `refute_any_call/1` when possible.

### Removals

None

## 0.6.1 (2021-10-17)

Minor release to improve the documentation and reduce the scope of imported symbols from `Patch.Mock.Value`.

### Improvements

- ⬆️ - \[Documentation\] Guide Book broken into Chapters, additional information about core concepts.

### Features

None

### Bugfixes

None

### Deprecations

None

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

### Bugfixes

None

### Deprecations

None

### Removals

- ⛔️ - \[Dependency\] `meck` was removed as a dependency

## 0.5.0 (2021-09-17)

Better support for mocking erlang modules

### Breaking Changes

None
### Improvements

- ⬆️ - \[Internal\] `patch.release` task to simplify releasing new versions of the library
- ⬆️ - Support for mocking erlang modules (both sticky and non-sticky)

### Features

None

### Bugfixes

- 🐞 - Mocking erlang modules actually works now

### Deprecations

None

### Removals

None

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
### Bugfixes

None
### Deprecations

None

### Removals

None

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

### Bugfixes

None

### Deprecations

None

### Removals

None

## 0.2.0 (2021-03-03)

Removed Arity Limitations

### Breaking Changes

None
### Improvements

- ⬆️ - Removed the arity limitation, can now patch functions of any arity

### Features

- 🎁 - Added the `assert_any_call/2` and `refute_any_call/2` assertion functions

### Bugfixes

None

### Deprecations

None

### Removals

None

## 0.1.2 (2021-01-28)

Increased Elixir Compatibility

### Improvements

- ⬆️ - Relaxed Elixir version requirement down to 1.7

### Features

None

### Bugfixes

None

### Deprecations

None

### Removals

None


## 0.1.1 (2020-04-27)

Bugfix Release

### Improvements

- ⬆️ - Made the library actually work

### Features

None

### Bugfixes

- 🐞 - Bugfix to make the library actually work

### Deprecations

None

### Removals

None

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

### Bugfixes

None

### Deprecations

None

### Removals

None
