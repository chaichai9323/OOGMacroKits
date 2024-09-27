import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(OOGMacros)
import OOGMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "MakeModel": MakeModelMacro.self,
    "URL": URLMacro.self
]

@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "OOGMacros", type: "StringifyMacro")

@freestanding(expression)
public macro URL(_ value: String) -> URL? = #externalMacro(module: "OOGMacros", type: "URLMacro")

@freestanding(expression)
public macro FileURL(_ value: String) -> URL = #externalMacro(module: "OOGMacros", type: "FileURLMacro")

#endif

final class OOGMacroKitsTests: XCTestCase {

#if canImport(OOGMacros)
    func testResult() {
        let a = 1
        let b = 2
        let (v, s) = #stringify(a + b)
        XCTAssert(v == 3)
        XCTAssert(s == "a + b")
        
        let u = #FileURL("/ab/s/f.txt")
        
    }
    
    func testResult2() {
        let str = "https://www.abc.com/api"
        if let url = #URL(str) {
            XCTAssert(url.scheme == "https")
            XCTAssert(url.host == "www.abc.com")
            XCTAssert(url.path == "/api")
        } else {
            XCTAssert(false)
        }
    }
#endif

    func testMacro() throws {
        #if canImport(OOGMacros)
        assertMacroExpansion(
            """
            #stringify(1 + 2)
            """,
            expandedSource: """
            (3, "1 + 2")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(OOGMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
