
# 0.5.0 (2021-09-17)

**Improvements**



- :arrow_up: - Support for mocking erlang modules (both sticky and non-sticky)



**Features**


None


**Bugfixes**



- :bettle: - Mocking erlang modules actually works now



**Deprecations**


None


**Removals**


None



# 0.4.0 (2021-08-09)

**Improvements**



- :arrow_up: - [Testing] Testing Matrix updated to latest versions of Elixir / OTP

- :arrow_up: - [Dependencies] `meck` updated to 0.9.2

- :arrow_up: - [Documentation] README revamped



**Features**



- :gift: - Added the `listen/3` function to support listening to a process's messages

- :gift: - Added the `inject/3` function to support updating the state of a running process.



**Bugfixes**


None


**Deprecations**


None


**Removals**


None



# 0.3.0 (2021-07-12)

**Improvements**



- :arrow_up: - [Internal] `Patch.Function.for_arity/2` now accepts an anonymous function it will call instead of a term to return.

- :arrow_up: - [Internal] `Patch.find_functions/1` and `Patch.find_arities/2` use `__info__/1` now instead of doing 256 `function_exported?` checks per function.



**Features**



- :gift: - Added the `fake/2` function to add support for module fakes.

- :gift: - Added the `real/1` function so module fakes can call the real module.



**Bugfixes**


None


**Deprecations**


None


**Removals**


None



# 0.2.0 (2021-03-03)

**Improvements**



- :arrow_up: - Removed the arity limitation, can now patch functions of any arity



**Features**



- :gift: - Added the `assert_any_call/2` and `refute_any_call/2` assertion functions



**Bugfixes**


None


**Deprecations**


None


**Removals**


None



# 0.1.2 (2021-01-28)

**Improvements**



- :arrow_up: - Relaxed Elixir version requirement down to 1.7



**Features**


None


**Bugfixes**


None


**Deprecations**


None


**Removals**


None



# 0.1.1 (2020-04-27)

**Improvements**



- :arrow_up: - Made the library actually work



**Features**


None


**Bugfixes**



- :bettle: - Bugfix to make the library actually work



**Deprecations**


None


**Removals**


None



# 0.1.0 (2020-04-21)

**Improvements**



- :arrow_up: - Patch released to the world.  Easy to use and ergonomic Mocking for Elixir.



**Features**



- :gift: - `patch/3` allows the patching of a module's function with a function.

- :gift: - `patch/3` allows the patching of a module's function with a static return value.

- :gift: - `spy/1` allows spying on a module.

- :gift: - `restore/1` allows removing patches and spies from a module.

- :gift: - `assert_called/1` allows for asserting that a patched or spied function has been called with the expected pattern of arguments.

- :gift: - `refute_called/1` allows for refuting that a patched or spied function has been called with the expected pattern of arguments.



**Bugfixes**


None


**Deprecations**


None


**Removals**


None


