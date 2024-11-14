import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
import OOGMacros
import OOGMacroKits

final class OOGMacroKitsTests: XCTestCase {
    
    func testURL() {
        let _ = #FileURL("file:/ab/s/f.txt")
        
        let str = "https://www.abc.com/api"
        if let url = #URL(str) {
            XCTAssert(url.scheme == "https")
            XCTAssert(url.host == "www.abc.com")
            XCTAssert(url.path == "/api")
        } else {
            XCTAssert(false)
        }
    }

    func testLocalizedMacro() throws {
        assertMacroExpansion(
        """
        @EnumStringLocalized
        enum Section: String {
            case first = "一"
            case second = "二"
            case third = "三"
            case fourth = "四"
        }
        """,
        expandedSource:
        """
        enum Section: String {
            case first = "一"
            case second = "二"
            case third = "三"
            case fourth = "四"

            var localizedRawValue: String {
                switch self {
                case .first:
                    return #Localized("一")
                case .second:
                    return #Localized("二")
                case .third:
                    return #Localized("三")
                case .fourth:
                    return #Localized("四")
                }
            }
        }
        """,
        macros: ["EnumStringLocalized": EnumStringLocalizedMacro.self]
        )
    }
    
}
