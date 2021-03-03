# 0.2.0 (2021-03-03)

## Improvements

- :arrow_up: - Removed the arity limitation, can now patch functions of any arity

## Features

- :gift: - Added the `assert_any_call/2` and `refute_any_call/2` assertion functions

## Bugfixes

None

## Deprecations

None

## Removals

None

# 0.1.2 (2021-01-28)

## Improvements

- :arrow_up: - Relaxed Elixir version requirement down to 1.7

## Features

None

## Bugfixes

None

## Deprecations

None

## Removals

None

# 0.1.1 (2020-04-27)

## Improvements

- :up_arrow: - Made the library actually work

## Features

None

## Bugfixes

- :beetle: - Bugfix to make the library actually work

## Deprecations

None

## Removals

None


# 0.1.0 (2020-04-21)

## Improvements

- :up_arrow: - Patch released to the world.  Easy to use and ergonomic Mocking for Elixir.

## Features

- :gift: - `patch/3` allows the patching of a module's function with a function.
- :gift: - `patch/3` allows the patching of a module's function with a static return value.
- :gift: - `spy/1` allows spying on a module.
- :gift: - `restore/1` allows removing patches and spies from a module.
- :gift: - `assert_called/1` allows for asserting that a patched or spied function has been called with the expected pattern of arguments.
- :gift: - `refute_called/1` allows for refuting that a patched or spied function has been called with the expected pattern of arguments.

## Bugfixes

None

## Deprecations

None

## Removals

None