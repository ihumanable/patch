# Change Log

## 0.5.0 (2021-09-17)

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

### Improvements



- ⬆️ - [Testing] Testing Matrix updated to latest versions of Elixir / OTP

- ⬆️ - [Dependencies] `meck` updated to 0.9.2

- ⬆️ - [Documentation] README revamped



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


