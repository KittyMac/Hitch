import XCTest
@testable import HitchKit

final class HitchFormatTests: XCTestCase {
    
    func testFormatOperator() {
        let halfHitch = "{0} {1}" << ["hello", "world"]
        let hitch = "{0} {1}" <<< ["hello", "world"]
        
        XCTAssertEqual(halfHitch, "hello world")
        XCTAssertEqual(hitch, "hello world")
    }
    
    func testFormatOperator2() {
        let format = "{0} {1}"
        let halfHitch = format << ["hello", "world"]
        let hitch = format <<< ["hello", "world"]
        
        XCTAssertEqual(halfHitch, "hello world")
        XCTAssertEqual(hitch, "hello world")
    }
    
    func testFormatOperator3() {
        let format: Hitch = "{0} {1}"
        let halfHitch = format << ["hello", "world"]
        let hitch = format <<< ["hello", "world"]
        
        XCTAssertEqual(halfHitch, "hello world")
        XCTAssertEqual(hitch, "hello world")
    }
    
    func testFormatOperator4() {
        let format: HalfHitch = "{0} {1}"
        let halfHitch = format << ["hello", "world"]
        let hitch = format <<< ["hello", "world"]
        
        XCTAssertEqual(halfHitch, "hello world")
        XCTAssertEqual(hitch, "hello world")
    }
    
    func testNoFormat() {
        let hello = Hitch("hello", "this", "is", "a", "test")
        XCTAssertEqual(hello, "hello")
    }
    
    func testStringFormat() {
        let hello = Hitch("{0} {1}", "hello", "world")
        XCTAssertEqual(hello, "hello world")
    }
    
    func testIntFormat() {
        let hello = Hitch("{0} {1} {2}", 0, 1, 2, 3)
        XCTAssertEqual(hello, "0 1 2")
    }
    
    func testDoubleFormat() {
        let hello = Hitch("{0} {1} {2} {3}", 8.0123456789, 12345.12345, 3.02, 0.0)
        XCTAssertEqual(hello, "8.0123456789 12345.12345 3.02 0.0")
    }
    
    func testFloatFormat() {
        XCTAssertEqual(Hitch("{        ~0.4         }", 8.0123456789), "        8.0123         ")
        XCTAssertEqual(Hitch("{        ~0.4         }", "8.0123456789x"), "        8.0123x        ")
    }
    
    func testBooleanFormat() {
        let hello = Hitch("{0} {1}", true, false)
        XCTAssertEqual(hello, "true false")
    }
    
    func testExample() {
        
        let value = Hitch("""
            {0}
            +----------+----------+----------+
            |{-0      }|{~0      }|{0       }|
            |{-??     }|{~?      }|{?       }|
            |{-?      }|{~?      }|{+?      }|
            |{-?.2    }|{~8.3    }|{+?.1    }|
            |{-1      }|{~2      }|{1       }|
            +----------+----------+----------+
            {{we no longer escape braces}}
            {These don't need to be escaped because they contain invalid characters}
            """, "This is an unbounded field", "Hello", "World", 27, 1, 2, 3, 1.0/3.0, 543.0/23.0, 99999.99999)
        print(value)
        
        XCTAssertEqual(value, """
        This is an unbounded field
        +----------+----------+----------+
        |This is an|This is an|This is an|
        |Hello     |  World   |        27|
        |1         |    2     |         3|
        |0.33      |  23.608  |      23.6|
        |Hello     |  World   |     Hello|
        +----------+----------+----------+
        {{we no longer escape braces}}
        {These don't need to be escaped because they contain invalid characters}
        """)
    }
    
    func testExample2() {
        
        let value = Hitch("""
            function {?} {
                if true {
                    print("Hello World")
                }
            }
            """, "printHelloWorld")
        print(value)
        
        XCTAssert(value == """
        function printHelloWorld {
            if true {
                print("Hello World")
            }
        }
        """)
    }
    
    func testExample3() {
        
        let value = Hitch("""
            @dynamicMemberLookup
            public enum Pamphlet {
                subscript(dynamicMember member: String) -> (_ input: String) -> Void {
                    switch input {
                        {0}
                    }
                }
            }
            """, "printHelloWorld")
        print(value)
        
        XCTAssert(value == """
            @dynamicMemberLookup
            public enum Pamphlet {
                subscript(dynamicMember member: String) -> (_ input: String) -> Void {
                    switch input {
                        printHelloWorld
                    }
                }
            }
            """)
    }
    
    func testExample4() {
        
        let value = Hitch("""
            extension {?} { public struct {?} { } }
            """, "Hello", "World")
        print(value)
        
        XCTAssertEqual(value, """
            extension Hello { public struct World { } }
            """)
    }
    
    func testToStringOperator() {
        
        let value = "extension {?} { public struct {?} { } }" <<~ ["Hello", "World"]
        print(value)
        
        XCTAssertEqual(value, "extension Hello { public struct World { } }")
    }
}

extension HitchFormatTests {
    static var allTests: [(String, (HitchFormatTests) -> () throws -> Void)] {
        return [
            ("testFormatOperator", testFormatOperator),
            ("testFormatOperator2", testFormatOperator2),
            ("testFormatOperator3", testFormatOperator3),
            ("testFormatOperator4", testFormatOperator4),
            ("testNoFormat", testNoFormat),
            ("testStringFormat", testStringFormat),
            ("testIntFormat", testIntFormat),
            ("testDoubleFormat", testDoubleFormat),
            ("testFloatFormat", testFloatFormat),
            ("testBooleanFormat", testBooleanFormat),
            ("testExample", testExample),
            ("testExample2", testExample2),
            ("testExample3", testExample3),
            ("testExample4", testExample4)
        ]
    }
}
