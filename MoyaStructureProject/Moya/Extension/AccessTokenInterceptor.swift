//
//  TokenInterceptor.swift
//  DStop
//
//  Created by DEV IOS on 6/18/24.
//

import Alamofire
import Dependencies
import Foundation
import RxSwift
import RxCocoa
import Foundation

final class AccessTokenInterceptor: @unchecked Sendable, RequestInterceptor {

    static let shared = AccessTokenInterceptor()
    private init() { }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let accessToken = "Add Access Token"
        if accessToken.isEmpty {
            completion(.success(urlRequest))
            return
        }

        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))

//        Log.tag(.API).tag(.INTERCEPTOR).d("Intercepted Token : \(accessToken)")
    }
}

