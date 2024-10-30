//
//  Extension + MoyaProvider.swift
//  DStop
//
//  Created by DEV IOS on 7/22/24.
//

import Foundation
import Moya
import UIKit

extension MoyaProvider {
    static func build() -> MoyaProvider<Target> {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = CommonAPI.shared.resourceTimeout
        configuration.timeoutIntervalForResource = CommonAPI.shared.resourceTimeout
        
#if DEBUG
        return MoyaProvider<Target>(
            session: Moya.Session(configuration: configuration, interceptor: AccessTokenInterceptor.shared),
            plugins: [MoyaLoggerPlugin()]
        )
#else
        return MoyaProvider<Target>(
            session: Moya.Session(configuration: configuration, interceptor: AccessTokenInterceptor.shared),
            plugins: []
        )
#endif
    }
    
    func request<T: Decodable>(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false, repeatCount: Int = 3) async -> T? {
        CommonAPI.shared.setLoadingProgress(true, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
        do {
            let t: T = try await request(target, isLoading: isLoading, isMultipart: isMultipart)
            CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
            return t
        } catch {
            if await responseErrorHandle(error, repeatCount, ignore: !isLoading) {
                return await request(target, isMultipart: isMultipart, repeatCount: repeatCount - 1)
            } else {
                CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
                return nil
            }
        }
    }
    
    private func request<T: Decodable>(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.request(target) { response in
                switch response {
                case .success(let result):
                    do {
                        let networkResponse = try JSONDecoder().decode(HttpResponse<T>.self, from: result.data)
                        if let errorResponse = networkResponse.toHttpErrorResponse() {
                            continuation.resume(throwing: errorResponse)
                        } else {
                            continuation.resume(returning: networkResponse.body)
                        }
                    } catch {
                        let errorResponse = (try? JSONDecoder().decode(HttpErrorResponse.self, from: result.data)) ?? .base
                        continuation.resume(throwing: errorResponse)
                    }

                case .failure(let error):
                    if let response = error.response?.data {
                        let errorResponse = try? JSONDecoder().decode(HttpErrorResponse.self, from: response)
                        continuation.resume(throwing: errorResponse ?? .base)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func noBodyForRequested(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false, repeatCount: Int = 3) async -> HttpResponseNoBody? {
        CommonAPI.shared.setLoadingProgress(true, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
        
        do {
            let response = try await noBodyForRequested(target, isLoading: isLoading, isMultipart: isMultipart)
            CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
            return response
        } catch {
            if await responseErrorHandle(error, repeatCount, ignore: !isLoading) {
                return await noBodyForRequested(target, isLoading: isLoading, isMultipart: isMultipart, repeatCount: repeatCount - 1)
            } else {
                CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
                return nil
            }
        }
    }
    
    private func noBodyForRequested(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false) async throws -> HttpResponseNoBody {
        return try await withCheckedThrowingContinuation { continuation in
            self.request(target) { response in
                switch response {
                case .success(let result):
                    do {
                        let networkResponse = try JSONDecoder().decode(HttpResponseNoBody.self, from: result.data)
                        
                        if let errorResponse = networkResponse.toHttpErrorResponse() {
                            continuation.resume(throwing: errorResponse)
                        } else {
                            continuation.resume(returning: networkResponse)
                        }
                    } catch {
                        let errorResponse = (try? JSONDecoder().decode(HttpErrorResponse.self, from: result.data)) ?? .base
                        continuation.resume(throwing: errorResponse)
                    }

                case .failure(let error):
                    if let response = error.response?.data {
                        let errorResponse = try? JSONDecoder().decode(HttpErrorResponse.self, from: response)
                        continuation.resume(throwing: errorResponse ?? .base)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func responseErrorHandle(_ error: Error, _ repeatCount: Int, ignore: Bool) async -> Bool {
        if ignore {
            return false
        }
        
        var isNext = true
        
        switch error {
            // Moya Failed API
        case let moyaError as MoyaError:
            if let response = moyaError.response?.data {
                let errorResponse = try? JSONDecoder().decode(HttpErrorResponse.self, from: response)
                await UIApplication.makeToastAsync(errorResponse?.message ?? HttpErrorResponse.base.message)
                isNext = false
            } else {
                if repeatCount <= 0 {
                    await UIApplication.makeToastAsync(error.localizedDescription)
                }
            }
            
            // Server Failed API
        case let errorResponse as HttpErrorResponse:
            isNext = false
            
            let message = errorResponse.message
            let errorType = HttpResponseCodeType(rawValue: errorResponse.code)
            
            switch errorType {
            case .OK:
                break
                
                // MARK: - Common Error
            case .SYSTEM_ERROR:
                await UIApplication.makeToastAsync(message)
                
                // MARK: - add Error Type
                // ...
                
            case .none:
                await UIApplication.makeToastAsync(message)
            }
            
            assert(!isNext)
        default:
            if repeatCount <= 0 {
                await UIApplication.makeToastAsync(error.localizedDescription)
            }
        }
        
        if repeatCount <= 0 {
            isNext = false
        }
        
        return isNext
    }

}
