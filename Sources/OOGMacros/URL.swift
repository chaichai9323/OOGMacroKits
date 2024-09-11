//
//  File.swift
//  
//
//  Created by chai chai on 2024/9/10.
//

import Foundation

import SwiftSyntax
import SwiftSyntaxMacros

struct URLMacro: ExpressionMacro {
    
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        
        guard let arg = node.argumentList.first?.expression else {
            fatalError("没有参数")
        }
        
        return "URL(string: \(raw: arg.description))"
    }
    
}
