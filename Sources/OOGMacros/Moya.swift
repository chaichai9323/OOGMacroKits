import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

fileprivate struct MemberManager {
    struct Param {
        var name: String
        var type: String
    }
    struct MoyaAttribute {
        var name: String
        var args: [String]
    }
    var name: String
    var atts: [MoyaAttribute]
    var param: [Param]?
    
    private var pathContent: String {
        guard let arr = param?.map({$0.name}), arr.count > 0 else {
            return ""
        }
        
        guard let args = atts.first(where: { $0.name == "MoyaPath" })?.args else {
            return ""
        }
        let pathUsedParams: [String]
        if args.count > 1 {
            pathUsedParams = Array(args[1...])
        } else {
            pathUsedParams = []
        }
        
        var used = false
        var res = [String]()
        for p in arr {
            let s: String
            if pathUsedParams.contains(p) {
                used = true
                s = p
            } else {
                s = "_"
            }
            res.append(s)
        }
        if used {
            let txt = res.joined(separator: ", ")
            return "(\(txt))"
        }
        return ""
    }
    
    private var urlContent: String {
        guard let arr = param?.map({$0.name}), arr.count > 0 else {
            return ""
        }
        
        guard let args = atts.first(where: { $0.name == "MoyaURL" })?.args else {
            return ""
        }
        let usedParams: [String]
        if args.count > 1 {
            usedParams = Array(args[1...])
        } else {
            usedParams = []
        }
        
        var used = false
        var res = [String]()
        for p in arr {
            let s: String
            if usedParams.contains(p) {
                used = true
                s = p
            } else {
                s = "_"
            }
            res.append(s)
        }
        if used {
            let txt = res.joined(separator: ", ")
            return "(\(txt))"
        }
        return ""
    }
    
    var bodyPath: String? {
        let p = pathContent
        
        let args = atts.first{ $0.name == "MoyaPath" }?.args
        guard let pathSegs = args, pathSegs.count > 0 else {
            return nil
        }
        let path: String
        if pathSegs.count > 1 {
            let s = pathSegs[1...].joined(separator: ", ")
            path = "String(format: \(pathSegs[0]), \(s))"
        } else {
            path = pathSegs[0]
        }
        
        return "case\(p.isEmpty ? "" : " let") .\(name)\(p): return \(path)"
    }
    
    var bodyMethod: String? {
        let m = atts.first{ $0.name == "MoyaMethod" }?.args.first
        guard let method = m else {
            return nil
        }
        return "case .\(name): return \(method)"
    }
    
    var bodyURL: String? {
        let p = urlContent
        
        let args = atts.first{ $0.name == "MoyaURL" }?.args
        guard let urlSegs = args, urlSegs.count > 0 else {
            return nil
        }
        let url: String
        if urlSegs.count > 1 {
            let s = urlSegs[1...].joined(separator: ", ")
            url = "String(format: \(urlSegs[0]), \(s))"
        } else {
            url = urlSegs[0]
        }
        
        return "case\(p.isEmpty ? "" : " let") .\(name)\(p): return URL(string: \(url))!"
    }
    
    var bodyParams: String? {
        guard let list = param, list.count > 0 else {
            return nil
        }
        
        let k = "(" + list.map{"let " + $0.name}.joined(separator: ", ") + ")"
        let v = list.map{"\"\($0.name)\": \($0.name)"}.joined(separator: ", ")
        
        return """
        case .\(name)\(k): return [\(v)]
        """
    }
}

fileprivate extension AttributeSyntax {
    var moyaAtts: MemberManager.MoyaAttribute? {
        guard let name = attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }
        guard let args = arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        
        let atts: [String]
        if name == "MoyaPath" || name == "MoyaURL" {
            let res = args.enumerated().map {
                if $0 == 0 {
                    return $1.expression.description
                } else {
                    if let a = $1.expression.as(StringLiteralExprSyntax.self) {
                        return a.segments.description
                    } else {
                        return $1.expression.description
                    }
                }
            }
            atts = res
        } else {
            let res = args.map {
                $0.expression.description
            }
            atts = res
        }
        return .init(name: name, args: atts)
    }
}

fileprivate extension EnumCaseElementSyntax {
    /// 获取case的参数列表
    var params: [MemberManager.Param]? {
        guard let parameters = self.parameterClause?.parameters else {
            return nil
        }
        
        return parameters.compactMap { param -> MemberManager.Param? in
            guard let n = param.firstName?.text else {
                return nil
            }
            let t = param.type.description
            return MemberManager.Param(name: n, type: t)
        }
    }
}

fileprivate extension DeclGroupSyntax {
    
    var config: String? {
        guard let decl = self.as(EnumDeclSyntax.self) else {
            return nil
        }
        
        let atts = decl.attributes
            .compactMap{ $0.as(AttributeSyntax.self) }
        
        var configDict: [String: String] = [:]
        atts.first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "MoyaConfig" }?
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .forEach{ expr in
                guard let key = expr.label?.text, key.count > 0 else {
                    return
                }
                let value: String
                if let tax = expr.expression.as(DeclReferenceExprSyntax.self) {
                    value = tax.baseName.text
                } else if let tax = expr.expression.as(StringLiteralExprSyntax.self){
                    value = "\(tax.description)"
                } else {
                    value = expr.expression.description
                }
                configDict[key] = value
            }
        
        var cfg: String?
        if configDict.count > 0 {
          let s = configDict.map{ "\($0.key): \($0.value)" }.joined(separator: ",")
            cfg = "private static let moyaConfig = (\(s))"
        }
        return cfg
    }
    
    private var defaultConfig: String {
        return """
        private static let moyaConfig = (baseURL: "", timeout: 30.0)
        """
    }
    
    var provider: String? {
        guard let decl = self.as(EnumDeclSyntax.self) else {
            return nil
        }
        
        let atts = decl.attributes
            .compactMap{ $0.as(AttributeSyntax.self) }
        
        let items = atts.first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "MoyaPlugin" }?.arguments?.description
        
        let res = items ?? ""
        
        return """
\(config ?? defaultConfig)
    
private static let provider: OOGMoyaProvider<Self> = .init(
    requestClosure: { (end, block) in
        do {
            var req = try end.urlRequest()
            req.timeoutInterval = moyaConfig.timeout
            block(.success(req))
        } catch {
            block(.failure(.requestMapping(error.localizedDescription)))
        }
    }, plugins: [\(res)]
)
"""
    }
    
    var moyaContent: String? {
        guard let list = members, list.count > 0 else {
            return nil
        }
        
        let path = list.compactMap { $0.bodyPath }.joined(separator: "\n    ")
        
        let method = list.compactMap{ $0.bodyMethod }.joined(separator: "\n    ")
        
        let url = list.compactMap{ $0.bodyURL }.joined(separator: "\n    ")
        
        let params = list.compactMap{$0.bodyParams}.joined(separator: "\n    ")
        
        return """

var path: String {
    switch self {
    \(path)
    default: return ""
    }
}

var method: OOGMoyaMethod {
    switch self {
    \(method)
    default: return .get
    }
}

var baseURL: URL {
    switch self {
    \(url)
    default: return URL(string: Self.moyaConfig.baseURL)!
    }
}

var defaultParams: [String: Any] {
    switch self {
    \(params)
    default: return [:]
    }
}

"""
    }
    
    var members: [MemberManager]? {
        let decls = memberBlock.members.compactMap{ $0.decl.as(EnumCaseDeclSyntax.self) }
        guard decls.count > 0 else {
            return nil
        }
        
        return decls.flatMap { syntax in
            let atts = syntax.attributes.compactMap { e in
                e.as(AttributeSyntax.self)?.moyaAtts
            }
            return syntax.elements
                .compactMap { ele -> MemberManager? in
                    
                    var m = MemberManager(
                        name: ele.name.text,
                        atts: atts
                    )
                    m.param = ele.params
                    return m
                }
        }
    }
}

public struct MoyaConfigMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        let body = """
extension \(type.trimmed): OOGTargetType {
    \(declaration.provider ?? "")
    \(declaration.moyaContent ?? "")
}
"""
        
        guard let res = DeclSyntax("\(raw: body)").as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [res]
    }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let model = """
        
        func requestModel<T: Codable>(_ model: T.Type) async throws -> T {
            return try await Self.provider.requestModel(self, modelType: model)
        }
        """
      
        let list = """
        
        func requestModelList<T: Codable>(_ model: T.Type) async throws -> [T] {
            return try await Self.provider.requestModelList(self, modelType: model)
        }
        """
        let res = [model, list].compactMap{DeclSyntax("\(raw: $0)")}
        return res
    }
    
}

public struct MoyaPathMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

        return []
    }
}

public struct MoyaURLMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

        return []
    }
}

public struct MoyaPluginMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

        return []
    }
}

public struct MoyaMethodMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {

        return []
    }
}
