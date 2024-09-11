import Foundation

@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "OOGMacros", type: "StringifyMacro")


@freestanding(expression)
public macro URL(_ value: String) -> URL? = #externalMacro(module: "OOGMacros", type: "URLMacro")
