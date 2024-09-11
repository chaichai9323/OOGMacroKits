// The Swift Programming Language
// https://docs.swift.org/swift-book

import OOGMoya
import Moya

public typealias OOGMoyaMethod = Moya.Method

@attached(member, names: arbitrary)
@attached(extension, conformances: OOGTargetType, names: arbitrary)
public macro MoyaConfig(baseURL: String, timeout: Double) = #externalMacro(module: "OOGMacros", type: "MoyaConfigMacro")

@attached(peer)
public macro MoyaPlugin(_ plugin: any PluginType ...) = #externalMacro(module: "OOGMacros", type: "MoyaPluginMacro")

@attached(peer)
public macro MoyaMethod(_ m: Moya.Method) = #externalMacro(module: "OOGMacros", type: "MoyaMethodMacro")

@attached(peer)
public macro MoyaPath(_ path: String, _ arguments: any CVarArg...) = #externalMacro(module: "OOGMacros", type: "MoyaPathMacro")

@attached(peer)
public macro MoyaURL(_ url: String, _ arguments: any CVarArg...) = #externalMacro(module: "OOGMacros", type: "MoyaURLMacro")

