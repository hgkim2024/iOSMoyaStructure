//
//  CommonApiTarget.swift
//  DStop
//
//  Created by 김현구 on 8/8/24.
//

import Foundation
import Moya

protocol CommonApiTarget: TargetType {
    
}

extension CommonApiTarget {
    var baseURL: URL {
        CommonAPI.shared.baseURL
    }
    
    var headers: [String : String]? {
        CommonAPI.shared.commonHeaders
    }
}
