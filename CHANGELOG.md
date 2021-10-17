# Change Log

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
