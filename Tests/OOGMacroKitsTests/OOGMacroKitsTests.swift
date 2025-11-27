import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
import OOGMacros
import OOGMacroKits

@EnumLocalized("title", "name", "address")
enum Section {
    case first
    case second
    case third

    var title: String {
        switch self {
        case .first: "first"
        case .second: "second"
        case .third: "third"
        }
    }
    var name: String {
        switch self {
        case .first, .second:
            "firstName"
        default: 
            "thirdName"
        }
    }
    
    var address: String {
        switch self {
        case .first, .second: 
            return "firstAddress"
        default: return "thirdAddress"
        }
    }
}

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

    func testMultiLocalizedMacro() throws {
        assertMacroExpansion(
        """
        @EnumLocalized("title", "name", "address")
        enum Section: String {
            case first
            case second
            case third
        
            var title: String {
                switch self {
                case .first: "first"
                case .second: "second"
                case .third: "third"
                }
            }
            var name: String {
                switch self {
                case .first, 
                     .second:
                    "firstName"
                default: "thirdName"
                }
            }
            var address: String {
                switch self {
                case .first, .second: return "firstAddress"
                default: return "thirdAddress"
                }
            }
        }
        """,
        expandedSource:
        """
        enum Section: String {
            case first
            case second
            case third

            var title: String {
                switch self {
                case .first: "first"
                case .second: "second"
                case .third: "third"
                }
            }
            var name: String {
                switch self {
                case .first: "firstName"
                case .second: "secondName"
                case .third: "thirdName"
                }
            }
            var address: String {
                switch self {
                case .first: "firstAddress"
                case .second: "secondAddress"
                case .third: "thirdAddress"
                }
            }
        }
        """,
        macros: [
            "EnumLocalized": EnumLocalizedMacro.self]
        )
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
