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
]
#endif

final class OOGMacroKitsTests: XCTestCase {
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
