//
//  File.swift
//  
//
//  Created by chai chai on 2024/9/10.
//

import Foundation

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct LocalizedMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let arg = node.argumentList.first?.expression else {
            fatalError("没有参数")
        }
        
        return "String(localized: \(raw: arg.description), bundle: Localized.bundle())"
        
    }
}


fileprivate enum EnumLocalizedError: Error, CustomStringConvertible {
    case onlyEnumSupport
    case onlyEnumStringSupport
    case paramNotFound
    case accessorNotFound(name: String)
    case accessorNotImplement(name: String)
    
    var description: String {
        switch self {
        case .onlyEnumSupport:
            return "只支持枚举类型"
        case .onlyEnumStringSupport:
            return "只支持String类型的枚举"
        case .paramNotFound:
            return "宏参数没有指定"
        case .accessorNotFound(let name):
            return "没有找到指定的计算属性: \(name)"
        case .accessorNotImplement(let name):
            return "var \(name) 没有实现代码, 或者不是 switch case 实现"
        }
    }
}

public struct EnumLocalizedMacro: ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        guard let enumDec = declaration.as(EnumDeclSyntax.self) else {
            throw EnumLocalizedError.onlyEnumSupport
        }
        
        let enumName = enumDec.name.text
        
        let param = enumDec.attributes
            .compactMap{
                $0.as(AttributeSyntax.self)
            }.first {
                guard let att = $0.attributeName
                    .as(IdentifierTypeSyntax.self),
                      att.name.text == "EnumLocalized" else {
                    return false
                }
                return true
            }?
            .arguments?.as(LabeledExprListSyntax.self)?
            .first?
            .expression.as(StringLiteralExprSyntax.self)?
            .segments
            .first?.as(StringSegmentSyntax.self)?
            .content.tokenKind
        
        let varName: String
        switch param {
        case .stringSegment(let name):
            varName = name
        default:
            throw EnumLocalizedError.paramNotFound
        }
        
        let def = enumDec.memberBlock
            .members
            .compactMap { mem -> PatternBindingSyntax? in
                guard let dec = mem.decl.as(VariableDeclSyntax.self),
                      dec.bindingSpecifier.tokenKind == .keyword(.var) else {
                    return nil
                }
                
                guard let res = dec.bindings.first?.as(PatternBindingSyntax.self),
                      res.pattern
                    .as(IdentifierPatternSyntax.self)?.identifier.text == varName,
                      res.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text == "String" else {
                    return nil
                }
                return res
            }.first
        
        guard let enumVar = def else {
            throw EnumLocalizedError.accessorNotFound(name: varName)
        }

        guard let code = enumVar.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self)?.first?.item.as(ExpressionStmtSyntax.self)?.expression.as(SwitchExprSyntax.self)?.cases else {
            throw EnumLocalizedError.accessorNotImplement(name: varName)
        }
        
        let items = code.compactMap {
            $0.as(SwitchCaseSyntax.self)
        }.compactMap { item -> (String, String)? in
            guard let lab = item.label.as(SwitchCaseLabelSyntax.self) else {
                return nil
            }
            let key = lab.caseItems.description
            let vaule = item.statements.first?.item
            if let r = vaule?.as(ReturnStmtSyntax.self),
               let e = r.expression?.as(StringLiteralExprSyntax.self) {
                return (key, e.segments.description)
            } else if let s = vaule?.as(StringLiteralExprSyntax.self) {
                return (key, s.segments.description)
            } else {
                return nil
            }
        }

        let capname = varName.prefix(1).uppercased() + varName.dropFirst()

        let res = try ExtensionDeclSyntax("extension \(raw: enumName)") {
            try VariableDeclSyntax("var localized\(raw: capname): String") {
                try SwitchExprSyntax("switch self") {
                    for (k, v) in items {
                        SwitchCaseSyntax(
                        """
                        case \(raw: k):
                            return #Localized(\(literal: v))
                        """
                        )
                    }
                }
            }
        }
        return [res]
    }
}


public struct EnumStringLocalizedMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDec = declaration.as(EnumDeclSyntax.self) else {
            throw EnumLocalizedError.onlyEnumSupport
        }
        let enumName = enumDec.name.text
        
        guard enumDec.inheritanceClause?.inheritedTypes.compactMap({
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        }).contains("String") == true else {
            throw EnumLocalizedError.onlyEnumStringSupport
        }
        
        let items = enumDec.memberBlock
            .members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements }
            .map { ele  in
                let name = ele.name.text
                if let value = ele.rawValue?.value.as(StringLiteralExprSyntax.self) {
                    return (name, value.segments.description)
                } else {
                    return (name, name)
                }
            }
        
        let res = try ExtensionDeclSyntax("extension \(raw: enumName)") {
            try VariableDeclSyntax("var localizedRawValue: String") {
                try SwitchExprSyntax("switch self") {
                    for (k, v) in items {
                        SwitchCaseSyntax(
                        """
                        case .\(raw: k):
                            return #Localized(\(literal: v))
                        """
                        )
                    }
                }
            }
        }
        return [res]
    }
}
