import XCTest
@testable import SimpleParsec

final class SimpleParsecTests: XCTestCase {
    
    func testLetter() throws {
        let letterParser = letter()
        
        guard case .ok("bcd", _) = letterParser("abcd")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error("1abcd", _) = letterParser("1abcd")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testCharSet() throws {
        let charSetParser = char(charSet: .alphanumerics)
        
        guard case .ok("abcd", _) = charSetParser("1abcd")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error("%1abcd", _) = charSetParser("%1abcd")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testCharSetWithString() throws {
        let charSetParser = char(charactersIn: "%-/")
        
        guard case .ok("%//", _) = charSetParser("/%//")
        else {
            XCTAssert(false)
            return
        }

        guard case .error("a/%//", _) = charSetParser("a/%//")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testWsChar() throws {
        guard case .ok(" ws", _) = wsChar()("\n ws")
        else {
            XCTAssert(false)
            return
        }

        guard case .error("w\n ws", _) = wsChar()("w\n ws")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testIwsChar() throws {
        guard case .ok("ws", _) = iwsChar()(" ws")
        else {
            XCTAssert(false)
            return
        }

        guard case .error("\n ws", _) = iwsChar()("\n ws")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testStringWhile() throws {
        let whileParser = string(while: { c in
            if c == "a" {
                return true
            } else {
                return false
            }
        })
        
        guard case .ok("bbbb", _) = whileParser("aaaaaabbbb")
        else {
            XCTAssert(false)
            return
        }

        guard case .error("baaaaaabbbb", _) = whileParser("baaaaaabbbb")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testStringCharSet() throws {
        let parser = string(charSet: .letters)
        guard case .ok("6%+", _) = parser("ws6%+")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("6ws6%+", _) = parser("6ws6%+")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testStringCharactersIn() throws {
        let parser = string(charactersIn: "%+-")
        guard case .ok("in", _) = parser("+-%in")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("/+-%in", _) = parser("/+-%in")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testStringCharactersNotIn() throws {
        let parser = string(charactersNotIn: " ")
        guard case .ok(" words", _) = parser("two words")
        else {
            XCTAssert(false)
            return
        }
        guard case .error(" two words", _) = parser(" two words")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testStringCharSetNotIn() throws {
        let parser = string(notIn: .decimalDigits)
        guard case .ok("0.12", _) = parser("number0.12")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("0123number0.12", _) = parser("0123number0.12")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testIws() throws {
        guard case .ok("\n.12", _) = iws()(" \t \t \n.12")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("\n \t \t \n.12", _) = iws()("\n \t \t \n.12")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testWs() throws {
        guard case .ok(".12", _) = ws()(" \t \t \n.12")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("a \t \t \n.12", _) = ws()("a \t \t \n.12")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testAlphaString() throws {
        guard case .ok("123", _) = alphaString()("abc123")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("9abc123", _) = alphaString()("9abc123")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testInteger() throws {
        guard case .ok("abc", _) = integer()("123abc")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("f123abc", _) = integer()("f123abc")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testLine() throws {
        guard case .ok("line 2", _) = line()("there is the line\nline 2")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("there is the lineline 2", _) = line()("there is the lineline 2")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testString() throws {
        let stringParser = string("hello")

        guard case .ok("world", _) = stringParser("helloworld")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("hellloworld", _) = stringParser("hellloworld")
        else {
            XCTAssert(false)
            return
        }

    }
    
    func testConcat() throws {
        let concatParser = concat([
            string("("),
            ws(),
            string(")")
        ])
        
        guard case .ok(" end", _) = concatParser("(  \t  \n  ) end")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("(  \t  \n   end", _) = concatParser("(  \t  \n   end")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testTimes() throws {
        let timesParser = times(min: 2, string("%"))
        
        guard case .ok("--", _) = timesParser("%%%--")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error("%--", _) = timesParser("%--")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testOptional() throws {
        let optionalParser = optional(string("%"))
        
        guard case .ok("---", _) = optionalParser("---")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .ok("--", _) = optionalParser("%--")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testChoose() throws {
        let chooseParser = choose([
            string("%"),
            string("-")
        ])
        
        guard case .ok("--", _) = chooseParser("---")
        else {
            XCTAssert(false)
            return
        }
        guard case .error("/--", _) = chooseParser("/--")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testTag() throws {
        let tagParser = tag(label: "name", string("name:"))
        
        guard case let .ok(" John", astOpt) = tagParser("name: John")
        else {
            XCTAssert(false)
            return
        }
        
        guard let ast = astOpt,
           case .tag("name", _) = ast
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error("lname: John", _) = tagParser("lname: John")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testIgnore() throws {
        let ignoreParser = ignore(string("("))
        
        guard case .ok(")", _) = ignoreParser("()")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error(")", _) = ignoreParser(")")
        else {
            XCTAssert(false)
            return
        }
    }
    
    func testEventually() throws {
        let parser = eventually(string("begin"))
        
        guard case .ok("{}", _) = parser("    begin{}")
        else {
            XCTAssert(false)
            return
        }
        
        guard case .error("    begi{}", _) = parser("    begi{}")
        else {
            XCTAssert(false)
            return
        }
    }
    
    /// This example is from the readme and should be tested.
    func testComplexExample() throws {
        func functionHeader() -> Parser {
            tag(label: "function", concat([
               ignore(string("def")),
               ignore(iws()),
               tag(label: "functionName", alphaString()),
               ignore(string("(")),
               tag(label: "params", optional(params())),
               ignore(string(")"))
            ]))
        }

        func params() -> Parser {
            choose([
               concat([
                 times(min: 1, concat([
                    param(),
                    ignore(string(",")),
                    ignore(optional(iws()))
                 ])),
                 param()
               ]),
               param()
           ])
        }

        func param() -> Parser {
            tag(label: "param", alphaString())
        }

        let parser = functionHeader()

        let result = parser("def myFunction(paramOne, paramTwo, paramThree)")
        
        guard case .ok("", _) = result
        else {
            print(result)
            XCTAssert(false)
            return
        }
    }
}
