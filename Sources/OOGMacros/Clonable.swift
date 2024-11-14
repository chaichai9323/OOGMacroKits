//
//  Clonable.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/8.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

fileprivate enum ClonableError: Error, CustomStringConvertible {
    case onlyClassSupport
    
    var description: String {
        switch self {
        case .onlyClassSupport:
            return "只支持class"
        }
    }
}

public struct ClonableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let clsDeclare = declaration.as(ClassDeclSyntax.self) else {
            throw ClonableError.onlyClassSupport
        }
        
        let level = clsDeclare.getAccessLevel
        let clsName = clsDeclare.name.text
        let members = clsDeclare.memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self)?.bindings
            }.flatMap{
                $0
            }
            .filter { member in
                switch member.accessorBlock?.accessors {
                case .getter: return false
                default: return true
                }
            }
            .map {
                $0.pattern.description
            }
        let res = try InitializerDeclSyntax(
            "required \(raw: level)init(source: \(raw: clsName))"
        ) {
            for member in members {
                CodeBlockItemSyntax(
                """
                if let c = DeepClonableWrapper(source.\(raw: member)).clone() {
                    self.\(raw: member) = c
                } else {
                    self.\(raw: member) = source.\(raw: member)
                }
                """
                )
            }
        }
        return [DeclSyntax(res)]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let des = declaration.as(ClassDeclSyntax.self) else {
            return []
        }
        let level = des.getAccessLevel
        let name = des.name.text
        let res = try ExtensionDeclSyntax(
            "extension \(raw: name): ClonableProtocol"
        ) {
            try FunctionDeclSyntax(
                "\(raw: level)func clone() -> Self"
            ) {
                CodeBlockItemSyntax(
                    "return Self.init(source: self)"
                )
            }
        }

        return [res]
    }
    
}
