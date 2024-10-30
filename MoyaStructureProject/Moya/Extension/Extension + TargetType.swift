//
//  Extension + TargetType.swift
//  MoyaStructureProject
//
//  Created by 김현구 on 10/29/24.
//

import Foundation
import Moya

extension TargetType {
    // result - [Moya Target] - Target Enum String
    var typeString: String {
        var result = "[\(type(of: self))] - "
        
        
        let mirror = Mirror(reflecting: self)
        if let child = mirror.children.first {
            result += child.label ?? result
        }
        
        return result
    }
}

