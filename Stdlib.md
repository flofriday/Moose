# 📖 Moose's Standard Library

<!--
    NOTE FOR DEVELOPERS

    For formatting the documentation try to orient  on existing functions, whereas `println` should be an example/template.
-->

<!--
TODO: create a table of contents from the headers with python.

## Contents
-->

## Builtin variables

### `args: List[String]`

The command line arguments provided to the script.

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

### `String.capitalize() > String`

Returns a capitalized version of the string.

### `String.contains(String) > Bool`

Returns wether or not the string contains the other one.

### `String.getItem(Int) > String`

Returns the character at the index and returns it in a new string.

### `String.length() > Int`

Returns the length of the string.

### `String.lines() > List[String]`

Returns a list where each item is a line in the original string.

### `String.lower() > String`

Returns a version of the string without upper letters.

### `String.parseBool() > (Bool, String)`

Returns a tuple where the bool is the parsed bool and the string is `nil` if it succeeds.

On error the bool is `nil` and the string contains the reason why it failed.

### `String.parseFloat() > (Float, String)`

Returns a tuple where the float is the parsed float and the string is `nil` if it succeeds.

On error the float is `nil` and the string contains the reason why it failed.

### `String.parseInt() > (Int, String)`

Returns a tuple where the integer is the parsed integer and the string is `nil` if it succeeds.

On error the integer is `nil` and the string contains the reason why it failed.

### `String.split(String) > List[String]`

Splits the string by the separator provided.

### `String.strip() > String`

Returns a version with all whitespaces at the start and end of the string removed.

### `String.upper() > String`

Returns a version with all characters capitalized.

## List Methods

Lists are a generic datastructure and with that an exception as Moose doesn't allow you to define custom generic Classes.

### `List[T].append(T) > Void`

Appends the provided item to the end of the list.

### `List[T].append(List[T]) > Void`

Appends the rest the provided list to the end of the first one.

### `List[T].enumerated() > List[(Int, T)]`

Returns a list where each item is wrapped in a tuple with the first element being the index in the original list and the second being the original item.

### `List[T].getItem(Int) > T`

Returns the item at the provided index.

This method panics with `OutOfBoundsPanic` if the item at the index doesn't exist.

There is syntactic sugar for this function:

```dart
l = [1, 77, 3, 4]
println(l[1])
```

### `List[T].setItem(Int, T) > Void`

Updates the item at the provided index.

This method panics with `OutOfBoundsPanic` if the item at the index doesn't exist.

There is syntactic sugar for this function:

```dart
l = [1, 77, 3, 4]
l[1] = 2
```

### `List[T].length() > Int`

Returns the length of the list.

<!-- TODO: min, max but how do they work? -->

### `List[T].reverse() > Void`

Reverses the List in place.

### `List[T].reversed() > List[T]`

Returns a reversed copy of the list and leaves the original intact.

## Dict Methods

Dicts are a generic datastructure and with that an exception as Moose doesn't allow you to define custom generic Classes.

### `Dict[K, V].length() > Int`

Returns the number of key-value pairs.

### `Dict[K, V].flat() > List[(K, V)]`

Converts the dictionary to a list where each item is a tuple with the key and value from the dictionary.

### `Dict[K, V].getItem(K) > V`

Gets the item with the provided key.

If the key doesn't exist, it will return `nil`.

There is syntactic sugar for this function:

```dart
dict = {"flo": true, "lisa": false}
println(dict["lisa"])
```

### `Dict[K, V].setItem(K, V) > Void`

Updates the provided key with the provided value.

There is syntactic sugar for this function:

```dart
dict = {"flo": true, "lisa": false}
dict["luis"] = false
```
