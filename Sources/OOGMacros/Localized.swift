//
//  Localized.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/4.
//
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

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

public struct EnumLocalizedMacro: MemberMacro {
    
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let enumDec = declaration.as(EnumDeclSyntax.self) else {
            throw EnumLocalizedError.onlyEnumSupport
        }
        
        let exprList = enumDec.attributes
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
            .arguments?
            .as(LabeledExprListSyntax.self)
        guard let args = exprList else {
            return []
        }
        let params = args.compactMap { lab -> String? in
                guard let exp = lab.expression.as(StringLiteralExprSyntax.self),
                    let param = exp.segments.first?.as(StringSegmentSyntax.self) else {
                    return nil
                }
                return param.content.text
            }
        guard params.count > 0 else {
            throw EnumLocalizedError.paramNotFound
        }
        
        return try params.compactMap { varName -> VariableDeclSyntax? in
            guard let enumVar = findVar(
                enumDec,
                name: varName
            ), let code = findCode(
                enumVar
            ) else {
                throw EnumLocalizedError.accessorNotFound(name: varName)
            }
            let defaults = parseDefauleCode(code)
            let items = parseCode(code)
            guard items.count > 0 || defaults != nil  else {
                throw EnumLocalizedError.accessorNotImplement(name: varName)
            }
            return try generateCode(
                name: varName,
                items: items,
                default: defaults
            )
        }.map { DeclSyntax($0) }
    }
}


public struct EnumStringLocalizedMacro: MemberMacro {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
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
        
        let syn = try VariableDeclSyntax("var localizedRawValue: String") {
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
        return [DeclSyntax(syn)]
    }
}


fileprivate func findVar(_ delc: EnumDeclSyntax, name: String) -> PatternBindingSyntax? {
    return delc.memberBlock
        .members
        .compactMap { mem -> PatternBindingSyntax? in
            guard let dec = mem.decl.as(VariableDeclSyntax.self),
                  dec.bindingSpecifier.tokenKind == .keyword(.var) else {
                return nil
            }
            
            guard let res = dec.bindings.first?.as(PatternBindingSyntax.self),
                  res.pattern
                .as(IdentifierPatternSyntax.self)?.identifier.text == name,
                  res.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text == "String" else {
                return nil
            }
            return res
        }
        .first
}

fileprivate func findCode(_ synx: PatternBindingSyntax) -> SwitchCaseListSyntax? {
    return synx.accessorBlock?.accessors.as(CodeBlockItemListSyntax.self)?.first?.item.as(ExpressionStmtSyntax.self)?.expression.as(SwitchExprSyntax.self)?.cases
}

fileprivate func parseDefauleCode(
    _ synx: SwitchCaseListSyntax
) -> String? {
    let lab = synx.compactMap {
        $0.as(SwitchCaseSyntax.self)
    }.first { lab in
        lab.label.is(SwitchDefaultLabelSyntax.self)
    }?.statements
        .first?
        .item
    
    if let r = lab?.as(ReturnStmtSyntax.self),
       let e = r.expression?.as(StringLiteralExprSyntax.self),
       let a = e.segments.first?.as(StringSegmentSyntax.self) {
        return a.content.text
    } else if let s = lab?.as(StringLiteralExprSyntax.self),
              let a = s.segments.first?.as(StringSegmentSyntax.self) {
        return a.content.text
    } else {
        return nil
    }
}

fileprivate func parseCode(
    _ synx: SwitchCaseListSyntax
) -> [([String], String)] {
    
    return synx.compactMap {
        $0.as(SwitchCaseSyntax.self)
    }.compactMap { item -> ([String], String)? in
        guard let lab = item.label.as(SwitchCaseLabelSyntax.self) else {
            return nil
        }
        let keys = lab.caseItems.compactMap {
            $0.pattern
                .as(ExpressionPatternSyntax.self)?
                .expression
                .as(MemberAccessExprSyntax.self)?
                .declName
                .baseName
                .text
        }.map { "." + $0 }
        
        let vaule = item.statements.first?.item
        if let r = vaule?.as(ReturnStmtSyntax.self),
           let e = r.expression?.as(StringLiteralExprSyntax.self),
           let a = e.segments.first?.as(StringSegmentSyntax.self) {
            return (keys, a.content.text)
        } else if let s = vaule?.as(StringLiteralExprSyntax.self),
                  let a = s.segments.first?.as(StringSegmentSyntax.self) {
            return (keys, a.content.text)
        } else {
            return nil
        }
    }
}

fileprivate func generateCode(
    name: String,
    items: [([String], String)],
    default des: String? = nil
) throws -> VariableDeclSyntax {
    let capname = name.prefix(1).uppercased() + name.dropFirst()
    return try VariableDeclSyntax(
        "var localized\(raw: capname): String"
    ) {
        try SwitchExprSyntax("switch self") {
            for (k, v) in items {
                let keys = k.joined(separator: ", ")
                SwitchCaseSyntax(
                    """
                    case \(raw: keys):
                        return #Localized(\(literal: v))
                    """
                )
            }
            if let d = des {
                SwitchCaseSyntax(
                    """
                    default :
                        return #Localized(\(literal: d))
                    """
                )
            }
        }
    }
}
