//
//  ClonableTest.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/8.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import OOGMacros
import OOGMacroKits

@Clonable
public class Person {
    var name: String = ""
    var age: Int = 0
    
    init() {}
}

@Clonable
class Grade {
    let name: String
    let students: [Person]
    
    init(name: String, students: [Person]) {
        self.name = name
        self.students = students
    }
}

final class ClonableTest: XCTestCase {
    
    func test() {
        let p = Person()
        let a = Grade(name: "1年级", students: [p])
        let b = a.clone()
        a.students[0].age = 20
        XCTAssertNotEqual(
            a.students[0].age,
            b.students[0].age,
            "a,b是同一个对象，没有克隆成功"
        )
    }
    
    func testMacco() throws {
        assertMacroExpansion(
            """
            @Clonable
            public class Person {
                var name: String = ""
                var age: Int = 0
                init() {}
            }
            """,
            expandedSource: """
            public class Person {
                var name: String = ""
                var age: Int = 0
                init() {}
            
                required public init(source: Person) {
                    if let c = DeepClonableWrapper(source.name).clone() {
                        self.name = c
                    } else {
                        self.name = source.name
                    }
                    if let c = DeepClonableWrapper(source.age).clone() {
                        self.age = c
                    } else {
                        self.age = source.age
                    }
                }
            }
            
            extension Person: ClonableProtocol {
                public func clone() -> Self {
                    return Self.init(source: self)
                }
            }
            """,
            macros: ["Clonable": ClonableMacro.self]
        )
    }
    
}
