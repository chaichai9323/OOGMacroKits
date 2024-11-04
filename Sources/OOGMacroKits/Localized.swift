//
//  Localized.swift
//  OOGMacroKits
//
//  Created by chai chai on 2024/11/4.
//
import Foundation

@freestanding(expression)
public macro Localized(_ value: String) -> String = #externalMacro(
    module: "OOGMacros",
    type: "LocalizedMacro"
)

/// 给枚举添加 localized[name] 属性
@attached(extension, names: arbitrary)
public macro EnumLocalized(_ name: String) = #externalMacro(
    module: "OOGMacros",
    type: "EnumLocalizedMacro"
)

/// 给字符串类型的枚举添加 localizedRawValue 属性
@attached(extension, names: arbitrary)
public macro EnumStringLocalized() = #externalMacro(
    module: "OOGMacros",
    type: "EnumStringLocalizedMacro"
)
