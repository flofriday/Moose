# Moose

**Moose** is a new programming language. This repo also includes an interpreter
written in [Swift](https://www.swift.org/).

## Build it yourself

**Note:** We only support macOS, iOS and Linux. On Windows you can use WSL.

You need to [install swift](https://www.swift.org/download/), after which you can run:

```bash
swift run Moose
```

## Status

At the moment we have already implemented all features we wanted. However,
please consider that this was mainly a learning experience. We might continue
working on it and playing with things that are interesting to us.

## Types

There are only 4 built in types in Moose: `Int, Float, String, Bool`

## Variables

Moose provides two types of variables: immutable and mutable variables.

### Mutable Variables

Mutable variables are variables that can be reassigned over and over again. To declare a mutable variable, the keyword `mut` must be used.

```jsx
mut a = 2
a = 4
a +: 1

mut b: Int
b = 2
```

### Immutable Variables

While mutable variables need to be declared using the `mut` keyword, immutable variables don’t have such a keyword. They also have to be assigned directly on the declaration, since the declaration without explicit initialisation is initialised with `nil`.

```jsx
a = 3;
a = 2; // Error, cannot reassign immutable variable
```

```jsx
b: Int;
b; // nil
b = 3; // Error, cannot reassign immutable variable
```

```jsx
b: Int = 3;
b; // 3
```

## Nil

Every object can be `nil`, and since even basic types are objects they can be `nil` too.

```tsx
cookie: Int = nil; // Basic types can be nil
strudel: Int; // Implizitly without assigning a value a variable is automatically nil.
```

To make working with null more ergonomic, we introduced the double questionmark operator `??`

```tsx
breakfast: Str = nil;
print(breakfast ?? "Melage and semmel");

// This code is just sytactic sugar and is equivalent to
print(breakfast != nil ? breakfast : "Melage and semmel");
```

## Lists

Lists are arrays that can grow and shrink dynamically. Moreover there is a special syntax to create them, with square brackets. Lists also only contain objects of a single type.

```tsx
wishlist: [String] = ["Computer", "Bicycle", "Teddybear"];

print(wishlist[0]); // "Computer"
print(wishlist[-1]); // "Teddybear"

wishlist.append("car");
wishlist.appendAll(["Aircraftcarrier", "Worlddomination"]);
```

## Dicts

Dictionaries (aka Hashtables or Hashmaps) are also build in.

```tsx
ages: {Str:Int} = {
	"Flo": 23,
  "Paul": 24,
  "Clemens": 7,
}

print(ages["Paul"]) // 24

print(ages.contains("Paul")) // true
ages.remove("Paul")
print(ages.contains("Paul")) // false
```

## If Else

Like go and rust we don’t require Parenteses around the condition but do require braces around the body.

```tsx
age = 23
if age > 18 {
	print("Please enter")
} else if age == 18 {
	print("Finally you can enter")
} else {
  print("I am sorry come back in a year")
}

// Sometimes you need to discriminate against Pauls
name = "Paul"
if (age > 12) && (name != "Paul") {
	print("Welcome to the waterpark")
}

```

## For

`for` is the only loop in the language and is used as a foreach, C-Style for loop or like a while loop.

```tsx
// For-each style
for i in range(10) {
	print("I was here")
}

// C-style loop
for i = 0; i < 100; i +: 3 {
	print(i)
}

// while style loop
for true {
	print("I will never terminate")
}
```

## Comments

Comments are written with `//`, which comments out the rest of the line.

```jsx
a = 3; // this is a comment
```

## Functions and Operators

### Classic Functions

```jsx
func myFunction(age: Int, name: String) > Person {
	return Person(name, age)
}

p = myFunction(12, "Alan Turing")
```

### Operator Functions

Beside classic functions, Moose provides the possibility to write own operators for own types. In fact, all operators have a function implementation. There are 3 types of operator functions: `prefix`, `infix` and `postfix`

```jsx
// from stdlib
infix func (+) (a: [Int], b: [Int]) > [Int] {
	return a.merge(b)
}
prefix func (+) (a: Int) > Int {
	return a.abs()
}

a = [1,2,3]
b = [2,3,4]

c = a + b
print(c) // 1,2,3,2,3,4

d = -2
print(+d) // 2
```

### Print Objects

Each object has a default implementation of `represent()` that returns a string with all the fields and their values of the object. By assigning the object to a `String` variable or a parameter, the `represent()` function is called internally.

```c
p = Person("Alan Turing", 41)

print(p)
// equivalent to
print(p.represent())
// Person: {name: "Alan Turing", age: 41}
```

## Classes and Objects

```tsx
class Person {
	name: Str
  	age: Int

  	func hello() {
		// Instead of this, Moose uses me
    	print("Hey I am " + me.name)
  	}
}

// Classes have a default constructor in which all all fields have to be filled out
anna = Person("Anna", 74)

```

## Inheritance

Moose supports single class inheritance.

```tsx
class Employee < Person {
	work: Str

	func hello() {
    	super.hello()
    	print("And I work at " + me.work)
  	}
}

catrin = Employee("Catrin", 56, "Google")
```

<!-- TODO: we don't implement this and even if the example doesn't work
## Extending Classes

You extend existing classes by using the `extend` construct.

```tsx
extend Person {
	friend: Person
	func add(friend: Person) {
		me.friend = friend
	}
}

a = "Hello"
str.add(" World")

print(str) // "Hello World"
```
-->

<!-- We dont to this anymore
## Copy by reference or value

As described before, Moose only has class object types without primitive types. In addition, all assignments are made by reference.

```jsx
infix func (&) (a: Person, b: Int) {
	a.age +: b
}

p1 = Person("Alan Turing", 41)
p2 = p1

p1 & 4

print(p2.age) // 45
```

In order to assigning a variable by value, you have to use the copy by value operator `*`.

```jsx
print(p1.age) // 41
p2 = *p1
p1 & 4
print(p1.age) // 45
print(p2.age) // 41
```
-->

## Tuple

In Moose, tuples are a standard data type, like Int, String and others. It allows the programmer to return multiple values from a function and also offers the possibility of destructuring.

```jsx
postfix func (/) (a: [Int]) > ([Int], [Int]) {
	firstHalf = a[0:(a.len/2)]
	secondHalf = a[(a.len/2):a.len-1)]
	return (first, second)
}

l = [1,2,3,4]
(a,b) = l/ // destruction of tupel

print(a) // [1,2]
print(b) // [3,4]
```

### Destructuring of Objects

Destructuring is not only possible for tuples themselves, but also for objects, where the tuple contains the first n object fields.

```jsx
p = Person("Alan Turing", 41)
(name, age) = p
```

## Indexing und Unpacking

Accessing data of an object is not only possible for `List` s, but for all datatypes that implement the indexing method.

```jsx
class Person {
	name: Str

	func indexing(i: Int) > (Char) {
		return name[i]
	}
}

p = Person("Alan Turing")

print(p[1]) // "A"

[a,b,c] = p // unpack indexed object
print(b) // "l"
```

It is also possible to unpack the rest of an indexed object by providing the `len()` function for that respective class.

```c
extend Person {
	func len() > Int {
		return self.name.len()
	}
}

[a, rest..] = p
print(rest) // ["l", "a", "n", " ", "T", "u", "r", "i", "n", "g"]
```
