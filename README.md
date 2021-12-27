# SimpleParsec

Simple parser combinator library inspired by NimbleParsec for Elixir.

Each function in the library returns a `Parser` which is just a type alias for a 
function which takes a substring and returns a `ParserResult`:
```swift
public typealias Parser = (Substring) -> ParserResult
```
For example to parse for the exact string `def`, use the `string(_: String) -> Parser` function:
```swift
import SimpleParsec

let parser = string("def")
```
The returned value is a function (of type `Parser`) which can be passed a string to parse:
```swift
let result = parser("def name")
```
Note that the parameter type is actually `Substring` and not `String`. This allows for
efficient processing throughout the parsers as substrings don't copy the string instead
represent index locations within the string. Swift automatically converts the string literal
into a `Subtring` however if we have an already defined string we will need to convert
it to a substring first:
```swift
let text = "def name"
let result = parser(Substring(text))
```
A parser returns a `ParserResult` which is an `enum` with two cases, either
`.ok` or `.error`. 
```swift
public enum ParserResult {
    case ok(Substring, AST?)
    case error(Substring, String)
}
```
Both include the remaining text that still needs to be parsed (the `Substring`)
and `.ok` also includes the AST constructed up to this point whereas `.error`
includes an error message. We can desconstruct the enum using an `if case let`:
```swift
if case let .ok(remain, astOpt) = result,
    let ast = astOpt {
    print(ast)
}
```
Note that `astOpt` is an optional, i.e. it can be `nil` even if the result is `.ok`. 
The AST can be `nil` for parsers such as `ignore` and `optional` where no match is okay
or the result is not intended to be added to the AST.
Here is a more complex example:
```swift
func functionHeader() -> Parser {
    tag(label: "function", concat([
       ignore(string("def")),
       ignore(iws()),
       tag(label: "functionName", alphaString()),
       string("("),
       params(),
       string(")")
    ]))
}
func params() -> Parser {
   concat([
     times(min: 1, concat([alphaString(), string(","), iws())),
     alphaString()
   ])
}
```
## `tag()`
`tag()` adds a label to a nested parser result which can be used for processing the AST later.
## `ignore()`
`ignore()` will match its parser but not add the results to the AST.
## `concat()`
`concat()` concat takes an array of parsers and ensures they all occur one after the other.
## `times()`
`times()` expects the parser to occur a multiple number of times, with a specified minimum.
## `iws()`
`iws()` is short for in-line whitespace, i.e. whitespace that doesn't include new lines, or
simply spaces and tabs. It matches one or more. To match a single character use `iwsChar()`.
See also `ws()` which also matches new lines, and the single character version `wsChar()`.
