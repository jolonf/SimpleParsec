/// # Simple parser combinator library inspired by NimbleParsec for Elixir.
///
/// Each function in the library returns a Parser which is just a type alias for a function
/// which takes a substring and returns a ParserReslt.
/// For example to parse for the exact string `def` use the `string()` function:
/// ```swift
/// import SimpleParsec
/// 
/// let parser = string("def")
/// ```
/// The parser is used by simply treating it as a function and passing a string to parse:
/// ```swift
/// let result = parser("def name")
/// ```
/// Note that the parameter type is actually `Substring` and not `String`. This allow for
/// efficienty processing throughout the parsers as substrings don't copy the string instead
/// represent index locations within the string. Swift automatically converted the string literal
/// into a `String` however if we have an already defined string we will need to convert
/// it to a substring first:
/// ```swift
/// let text = "def name:
/// let result = parser(Substring(text))
/// ```
/// A parser returns a `ParserResult` which is an enum with two cases, either
/// `.ok` or `.error`. Both include the remaining text that still needs to be parsed
/// and `.ok` also includes the AST constructed up to this point whereas `.error`
/// includes an error message. We can desconstruct the enum using an if:
/// ```swift
/// if case let .ok(remain, astOpt) = result,
///     let ast = astOpt {
///     print(ast)
/// }
/// ```
/// Note that `ast` is an optional, i.e. it can be nil even if the result is `.ok`. This
/// is permitted for parsers like `ignore` and `optional` where no match is okay
/// or the result is not intended to be added to the AST.
///
/// Here is a more complex example:
/// ```swift
/// func functionHeader() -> Parser {
///     tag(label: "function", concat([
///        ignore(string("def")),
///        ignore(iws()),
///        tag(label: "functionName", alphaString()),
///        string("("),
///        params(),
///        string(")")
///     ]))
/// }
///
/// func params() -> Parser {
///    concat([
///      times(min: 1, concat([alphaString(), string(","), iws())),
///      alphaString()
///    ])
/// }
/// ```
/// ## `tag()`
/// `tag()` adds a label to a nested parser result which can be used for processing the AST later.
/// ## `ignore()`
/// `ignore()` will match its parser but not add the results to the AST.
/// ## `concat()`
/// `concat()` concat takes an array of parsers and ensures they all occur one after the other.
/// ## `times()`
/// `times()` expects the parser to occur a multiple number of times, with a specified minimum.
/// ## `iws()`
/// `iws()` is short for in-line whitespace, i.e. whitespace that doesn't include new lines, or
/// simply spaces and tabs. It matches one or more. To match a single character use `iwsChar()`.
/// See also `ws()` which also matches new lines, and the single character version `wsChar()`.
///

import Foundation

/// Represents the Abstract Syntax Tree
public indirect enum AST {
    case value(String)
    case list([AST])
    case tag(String, AST)
}

/// Represents the result from a parser.
/// The first value in `.ok` and `.error` represents the remaining substring to be parsed.
/// The second value in `.error` is an error message.
public enum ParserResult {
    case ok(Substring, AST?)
    case error(Substring, String)
}

/// Functions in this library construct and return parsers which are simply
/// functions that take text to be parsed and return a `ParserResult`.
/// Note that the parameter is a `Substring` instead of a `String`
/// which is more efficient as it won't copy the string.
public typealias Parser = (Substring) -> ParserResult

/// Tries each subsequent character until the parser succeeds.
/// Note that this can be slow for large strings.
/// Useful for parsing text where the syntax is not fully supported and to
/// skip to the section to parse.
public func eventually(_ parser: @escaping Parser) -> Parser {
    { (text: Substring) -> ParserResult in
        var newText = text
        var result = parser(newText)
        // Advance character until successful parse
        while case .error = result {
            newText = newText.dropFirst()
            if newText.isEmpty {
                return .error(text, "eventually")
            }
            result = parser(newText)
        }
        return result
    }
}

/// Ensures that the parser succeeds but doesn't add its result ot the AST.
/// Useful for syntax that is required but not important later such as punctuation
/// and keywords.
public func ignore(_ parser: @escaping Parser) -> Parser {
    { (text: Substring) -> ParserResult in
        // Ditch the AST
        if case let .ok(result, _) = parser(text) {
            return .ok(result, nil)
        } else {
            return .error(text, "ignore")
        }
    }
}

/// Allows you to tag a branch of the AST with a string label, which is useful
/// for processing the AST later on.
public func tag(label: String, _ parser: @escaping Parser) -> Parser {
    { (text: Substring) -> ParserResult in
        if case let .ok(result, ast) = parser(text) {
            // If the AST is a list of values then
            // concat them into a single string
            switch ast {
            case let .list(list) where list.allSatisfy(isValue):
                return .ok(result, .tag(label, .value(listToString(list))))
            case nil:
                return .ok(result, nil)
            default:
                return .ok(result, .tag(label, ast!))
            }
        } else {
            return .error(text, "tag")
        }
    }
}

/// If ast is a `.list` and all of its elements are `.value`s then concat into a single string and return.
func listToString(_ list: [AST]) -> String {
    var result = ""
    
    for ast in list {
        if case let .value(value) = ast {
            result += value
        }
    }
    
    return result
}

/// Returns true if ast is a .value, used by `listToString()`.
func isValue(ast: AST) -> Bool {
    if case .value = ast {
        return true
    } else {
        return false
    }
}

/// Tries each parser provided until one succeeds and returns that result.
public func choose(_ parsers: [Parser]) -> Parser {
    { (text: Substring) -> ParserResult in 
        for parser in parsers {
            if case let .ok(result, ast) = parser(text) {
                return .ok(result, ast)
            }
        }
        return .error(text, "choose, expecting...")
    }
}

/// Will succeed even if the provided parser does not however if the provided
/// parser doesn't succeed it will return a `nil` AST.
public func optional(_ parser: @escaping Parser) -> Parser {
    { (text: Substring) -> ParserResult in 
        switch parser(text) {
            case let .ok(result, ast):
                return .ok(result, ast)
            case let .error(result, _):
                // Error is fine, but we need to return
                // the consumed text and no AST.
                return .ok(result, nil)
        }
    }
}

/// Expects the parser to succeed a minimum number of times and will consume
/// text until the parser fails. i.e. times is min or more. Result AST is a `.list`.
public func times(min: Int, _ parser: @escaping Parser) -> Parser {
    { (text: Substring) -> ParserResult in
        // Perform mandatory min times
        var newText = text
        var list: [AST] = []
        for _ in 1...min {
            if case let .ok(result, astOpt) = parser(newText) {
                newText = result
                // Only add the ast if it isn't empty (nil)
                if let ast = astOpt {
                    list.append(ast)
                }
            } else {
                return .error(text, "times")
            }
        }
        // Repeat until fail
        while case let .ok(result, astOpt) = parser(newText) {
            newText = result
            if let ast = astOpt {
                list.append(ast)
            }
        }
        return .ok(newText, .list(list))
    }
}

/// All parsers must succeed one after each other or all fail. Result is returned
/// as a `.list`.
public func concat(_ parsers: [Parser]) -> Parser {
    { (text: Substring) -> ParserResult in
        var newText = text
        var list: [AST] = []
        for parser in parsers {
            if case let .ok(result, astOpt) = parser(newText) {
                newText = result
                if let ast = astOpt {
                    list.append(ast)
                }
            } else {
                return .error(text, "concat")
            }
        }
        return .ok(newText, .list(list))
    }
}

/// Parsers matches the exact string passed.
public func string(_ s: Substring) -> Parser {
    { (text: Substring) -> ParserResult in
        if text.starts(with: s) {
            return .ok(text.dropFirst(s.count), .value(String(s)))
        } else {
            return .error(text, "string(\"\(s)\")")
        }
    }
}

/// Matches string of digits 0-9.
public func integer() -> Parser {
    string(charSet: .decimalDigits)
}

/// Matches string of letters according to `CharacterSet.letters`.
public func alphaString() -> Parser {
    string(charSet: CharacterSet.letters)
}

/// Also consumes the new line character
public func line() -> Parser {
    concat([
        string(charactersNotIn: "\n\r"),
        ignore(char(charactersIn: "\n\r"))
    ])
}

/// Consumes string while each character matches the predicate function passed in.
/// Used by other string parser functions.
public func string(while predicate: @escaping (Character) -> Bool) -> Parser {
    { (text: Substring) -> ParserResult in
        var newText = text
        var result = ""
        
        // Should be at least one matching character
        if let first = newText.first,
           predicate(first) {
            newText = newText.dropFirst()
            result += String(first)
        } else {
            return .error(newText, "string while")
        }
        
        while let first = newText.first,
              predicate(first) {
            newText = newText.dropFirst()
            result += String(first)
        }
        
        return .ok(newText, .value(result))
    }
}

/// Series of whitespace characters
public func ws() -> Parser {
    string(charactersIn: " \t\n\r")
}

/// Series of in-line whitespace characters,i.e.  not including newline
public func iws() -> Parser {
    string(charactersIn: " \t")
}

/// Matches a string where each character must match any of the characters in the provided string..
public func string(charactersIn s: String) -> Parser {
    string(charSet: CharacterSet(charactersIn: s))
}

/// Matches a string where each character must not match any of the characters in the provided string.
public func string(charactersNotIn s: String) -> Parser {
    string(notIn: CharacterSet(charactersIn: s))
}

/// Matches a string where all characters must be in the provided `CharacterSet`.
/// See also `string(charactersIn: String)`
public func string(charSet: CharacterSet) -> Parser {
    string(while: { c in 
        if let firstUnicode = c.unicodeScalars.first,
        charSet.contains(firstUnicode) {
            return true
        } else {
            return false
        }
    })
}

/// Matches a string where all characters must not be in the provided `CharacterSet`.
/// See also `string(charactersNotIn: String)`
public func string(notIn charSet: CharacterSet) -> Parser {
    string(while: { c in 
        if let firstUnicode = c.unicodeScalars.first,
        !charSet.contains(firstUnicode) {
            return true
        } else {
            return false
        }
    })
}

/// Inline whitespace char, e.g. space or tab
public func iwsChar() -> Parser {
    char(charactersIn: " \t")
}

/// Whitespace char, e.g. space, tab, or newline
public func wsChar() -> Parser {
    char(charactersIn: " \t\n\r")
}

/// Matches a character which is one of the characters in the provided string.
public func char(charactersIn s: String) -> Parser {
    char(charSet: CharacterSet(charactersIn: s))
}

/// Matches a character which is one of the characters in the `CharacterSet`.
public func char(charSet: CharacterSet) -> Parser {
    { (text: Substring) -> ParserResult in
        if let first = text.first,
           let firstUnicode = first.unicodeScalars.first,
           charSet.contains(firstUnicode) {
            return .ok(text.dropFirst(), .value(String(first)))
        } else {
            return .error(text, "char")
        }
    }
}

/// Matches a character which is in `CharacterSet.letters`.
public func letter() -> Parser {
    char(charSet: .letters)
}
