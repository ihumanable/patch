# User Tests

User tests provide a set of tests that test Patch from the point of view of the user.

These are high level integration tests that do not interrogate the internals of how patch works but instead just attempt to use the library as it is intended to be used.

## Structure

Each user test should have a minimal support module.  Tests should not share support modules to prevent any support module from becoming too complex.

## Regressions / Bugs

These tests are key to preventing regressions and validating and fixing bugs.  If you believe you have found a bug in Patch, writing a failing user test is a good way to communicate what is expected to happen and provide a reproduction case. 

## Documentation Augmentation

The tests here show simplified but varied use of the library interface.  These test compliment the documentation by providing many approachable examples of all the ways the library affordances can be used that are guaranteed to work correctly since they are tests.

