//
//  HttpResponse.swift
//  DStop
//
//  Created by DEV IOS on 7/22/24.
//

import Foundation

protocol HttpProtocol: Decodable {
    func toHttpErrorResponse() -> HttpErrorResponse?
}

struct HttpResponse<T: Decodable>: HttpProtocol {
    let code: String
    let message: String
    let status: String
    let timestamp: String
    let body: T
    
    func toHttpErrorResponse() -> HttpErrorResponse? {
        if let code = HttpResponseCodeType(rawValue: code) {
            if code == .OK {
                return nil
            }
        }
        
        return HttpErrorResponse(status: status, code: code, message: message)
    }
}

struct HttpResponseNoBody: HttpProtocol {
    let code: String
    let message: String
    let status: String
    let timestamp: String
    let body: String?
    
    func toHttpErrorResponse() -> HttpErrorResponse? {
        if let code = HttpResponseCodeType(rawValue: code) {
            if code == .OK {
                return nil
            }
        }
        
        return HttpErrorResponse(status: status, code: code, message: message)
    }
}
