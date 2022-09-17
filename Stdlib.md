# 📖 Moose's Standard Library

<!--
    NOTE FOR DEVELOPERS

    For formatting the documentation try to orient  on existing functions, whereas `println` should be an example/template.
-->

<!--
TODO: create a table of contents from the headers with python.

## Contents
-->

## Builtin functions

### `abs(Int) > Int`

Returns the absolute of the input.

### `abs(Float) > Float`

Returns the absolute of input.

### `dbgEnv() > Void`

Prints the current internal environment of the interpreter to stdout.
This is useful for debugging the interpreter.

### `exit() > Void`

Exits the program and interpreter with exitcode `0`.

### `exit(Int) > Void`

Exits the program and interpreter with the exitcode specified.

### `input() > (String, String)`

Reads a line from stdin.

If it succeeds the read line will be in the first string and the second one will be `nil`.

On error the first one will be `nil` and the second one will contain the reason of failure.

### `max(Int, Int) > Int`

Returns the bigger input.

### `max(Float, Float) > Float`

Returns the bigger input.

### `min(Int, Int) > Int`

Returns the smaller input.

### `min(Float, Float) > Float`

Returns the smaller input.

### `min(Int, Int) > Int`

Returns the smaller input.

### `min(Float, Float) > Float`

Returns the smaller input.

### `print(AnyType) > Void`

Prints the object without a newline to stdout.

(`AnyType` is not an actual type but an internal the interpreter uses, so that it can work with any class.)

### `println(AnyType) > Void`

Prints the object with a newline to stdout.

(`AnyType` is not an actual type but an internal the interpreter uses, so that it can work with any class.)

### `range(Int) > [Int]`

Returns a list starting at 0 up to but not including the input.

### `range(Int, Int) > [Int]`

Returns a list starting at the first input up to but not including the second input.

## Integer Methods

### `Int.abs() > Int`

Returns the absolute of the integer.

### `Int.toBool() > Bool`

Returns the integer converted to a bool.

### `Int.toFloat() > Float`

Returns the integer converted to a float.

### `Int.toString() > String`

Returns the integer converted to a String.

## Bool Methods

### `Bool.toInt() > Int`

Returns the bool converted to an Int.

### `Bool.toString() > String`

Returns the bool converted to a String.

## Float Methods

### `Float.abs() > Float`

Returns the absolute of the float.

### `Float.toInt() > Int`

Returns the float converted to a Int.

### `Float.toString() > String`

Returns the float converted to a String.

## String Methods

Not yet documented...

## List Methods

Not yet documented...

## Dict Methods

Not yet documented...
