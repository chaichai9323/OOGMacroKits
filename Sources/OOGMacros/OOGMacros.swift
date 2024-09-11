import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OOGMacroKitsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        URLMacro.self,
        
        
        MoyaConfigMacro.self,
        MoyaPathMacro.self,
        MoyaURLMacro.self,
        MoyaPluginMacro.self,
        MoyaMethodMacro.self
    ]
}
