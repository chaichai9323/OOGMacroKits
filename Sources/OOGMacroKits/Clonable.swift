//
//  Copy.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/8.
//
import Foundation

public protocol ClonableProtocol {
    func clone() -> Self
}

public struct DeepClonableWrapper<T: Any> {
    private let data: T
    
    public init(_ value: T) {
        self.data = value
    }
    
    public func clone() -> T? {
        guard let v = data as? ClonableProtocol else {
            return nil
        }
        return v.clone() as? T
    }
}

extension Array: ClonableProtocol where Element: ClonableProtocol {
    public func clone() -> Array<Element> {
        return map {
            $0.clone()
        }
    }
}

@attached(member, names: named(init(source:)))
@attached(extension, conformances: ClonableProtocol, names: named(clone))
public macro Clonable() = #externalMacro(
    module: "OOGMacros",
    type: "ClonableMacro"
)
