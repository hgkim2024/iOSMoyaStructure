//
//  CommonAPI.swift
//  MoyaStructureProject
//
//  Created by 김현구 on 10/29/24.
//

import Foundation
import Dependencies
import Moya
import RxSwift
import RxCocoa
import UIKit

enum URLType {
    case base
    
    var url: URL {
        switch self {
        case .base:
            return CommonAPI.shared.baseURL
        }
    }
}

class CommonAPI {
    static var shared = CommonAPI()
    private init() { }
    
    private var commonURLString: String {
#if DEBUG
        return "TEST_SERVER_URL"
#else
        return "SERVER_URL"
#endif
    }
    
    var timeout: TimeInterval = 15.0
    var resourceTimeout: TimeInterval = 60.0
    
    var baseURL: URL {
        return URL(string: "\(commonURLString)/api/v1")!
    }
    
    var commonHeaders: [String : String]? {
        return ["x-client": "UbiplusDstop"]
    }
  
    var multipart: [String : String]? {
        return ["Content-type" : "multipart/form-data"]
    }
    
    private let loadingProgressSubject = BehaviorSubject<Bool>(value: false)
    var loadingObservable: Observable<Bool> {
        return loadingProgressSubject.asObservable()
    }
    
    var loadingWorkItem: DispatchWorkItem?
    
    func setLoadingProgress(_ value: Bool, log: String, isMultipart: Bool = false, ignore: Bool = false) {
        if ignore {
            return
        }
        
        let isLoading = value
        DispatchQueue.main.async {
            self.loadingProgressSubject.onNext(isLoading)
        }
    
        if isLoading {
            loadingWorkItem?.cancel()
            loadingWorkItem = DispatchWorkItem {
                DispatchQueue.main.async {
                    self.loadingProgressSubject.onNext(false)
                }
            }
            
            if let workItem = loadingWorkItem {
                let timeout = isMultipart ? resourceTimeout : timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
            }

        } else {
            loadingWorkItem?.cancel()
        }
        
        assert(!log.isEmpty)
        Log.tag(.LOADING).d("isLoading: \(isLoading), log: \(log)")
    }
}

