import Foundation

@freestanding(expression)
public macro URL(_ value: String) -> URL? = #externalMacro(module: "OOGMacros", type: "URLMacro")

@freestanding(expression)
public macro FileURL(_ value: String) -> URL = #externalMacro(module: "OOGMacros", type: "FileURLMacro")

@freestanding(expression)
public macro Localized(_ value: String) -> String = #externalMacro(module: "OOGMacros", type: "LocalizedMacro")
