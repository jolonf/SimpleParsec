# SimpleParsec

Simple parser combinator library for Swift inspired by NimbleParsec for Elixir.

Each function in the library creates a `Parser` which can be used to
create an AST from text. 

For example the `string(_: String) -> Parser` function returns a `Parser`
which matches the exact string passed to the `string()` function:
```swift
import SimpleParsec

let parser: Parser = string("def")
```
The above example constructs a parser which matches the exact string `"def"`.

`Parser` is just a typealias for a function which we can call to perform the parsing. The `Parser` typealias is defined as:
```swift
public typealias Parser = (Substring) -> ParserResult
```
Therefore we need to invoke the parser with a substring (the text to be parsed) and we get a `ParserResult`.

```swift
let result = parser("def functionName")
```

The above will successfully parse the text as it begins with `"def"`.

Note that the `Parser` parameter type is actually `Substring` and not `String`. This allows for
efficient processing throughout the parsers as substrings don't copy the string instead
represent index locations within the string. Swift automatically converts the string literal
into a `Substring` however if we have an already defined string we will need to convert
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
       ignore(string("(")),
       tag(label: "params", params()),
       ignore(string(")"))
    ]))
}

func params() -> Parser {
   concat([
     times(min: 1, concat([
        param(), 
        ignore(string(",")), 
        ignore(iws()))),
     param()
   ])
}

func param() -> Parser {
    tag(label: "param", alphaString())
}

let parser = functionHeader()

let result = parser("def myFunction(param1, param2, param3)")
```
- `tag()` adds a label to a nested parser result which can be used for processing the AST later.
- `ignore()` will match its parser but not add the results to the AST.
- `concat()` takes an array of parsers and ensures they all occur one after the other.
- `times()` expects the parser to occur a multiple number of times, with a specified minimum.
- `iws()` is short for in-line whitespace, i.e. whitespace that doesn't include new lines, or
simply spaces and tabs. It matches one or more. To match a single character use `iwsChar()`.
See also `ws()` which also matches new lines, and the single character version `wsChar()`.
