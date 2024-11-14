//
//  Declaration.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/8.
//
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

extension DeclGroupSyntax {
    var getAccessLevel: String {
        let list: [Keyword] = [
            .open,
            .public,
            .internal,
            .fileprivate,
            .private
        ]
        
        let level = modifiers.compactMap { mod in
            switch mod.name.tokenKind {
            case .keyword(let k):
                if list.contains(k) {
                    return mod.name.text
                } else {
                    return nil
                }
            default: return nil
            }
        }.first
        
        if let res = level {
            return "\(res) "
        } else {
            return ""
        }
    }
}
