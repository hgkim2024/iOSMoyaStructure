//
//  MoyaLoggerPlugin.swift
//  DStop
//
//  Created by 김현구 on 7/21/24.
//

import Foundation
import Moya

struct MoyaLoggerPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        let tag: [Tag] = [.API, .REQUEST]
        guard let httpRequest = request.request else {
            Log.tag(tag).d("[HTTP Request] invalid request")
            return
        }

        let url = httpRequest.description
        
        let method = httpRequest.httpMethod ?? "unknown method"
        Log.tag(tag).d("———————————— 🚀 Network Request Log 🚀 ————————————")
        Log.tag(tag).d("[URL] : \(url)")
        Log.tag(tag).d("[TARGET] : \(target)")
        Log.tag(tag).d("[Method] : \(method)")

        if let headers = httpRequest.allHTTPHeaderFields {
            Log.tag(tag).d("[Headers] : \(headers)")
        }

        if let body = httpRequest.httpBody {
            Log.tag(tag).d("[Body] : \(prettyPrintJSON(body))")
        }
        Log.tag(tag).d(endSepartorString)
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case let .success(response):
            onSuceed(response, target: target, isFromError: false)
        case let .failure(error):
            onFail(error, target: target)
        }
    }

    func onSuceed(_ response: Response, target: TargetType, isFromError: Bool) {
        
        var failed = false
        var responseCode = "nil"
        
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
               let code = jsonObject["code"] as? String {
                responseCode = code
                if HttpResponseCodeType(rawValue: code) != .OK {
                    failed = true
                }
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
        
        let tag: [Tag] = failed ? [.API, .RESPONSE, .FAIL] : [.API, .RESPONSE]

        let url = response.request?.url?.absoluteString ?? "nil"
        
        if failed {
            Log.tag(tag).d("———————————— ❌ Network Error Log ❌ ————————————")
        } else {
            Log.tag(tag).d("———————————— ✅ Network Response Log ✅ ————————————")
        }
        Log.tag(tag).d("[URL] : \(url)")
        Log.tag(tag).d("[TARGET] : \(target)")
        Log.tag(tag).d("[Status Code] : \(response.statusCode)")
        Log.tag(tag).d("[Response Code]: \(responseCode)")
        if let headers = response.response?.allHeaderFields {
            Log.tag(tag).d("[Headers] : \(headers)")
        }

        Log.tag(tag).d("[Response] : \(prettyPrintJSON(response.data))")
        Log.tag(tag).d(endSepartorString)
    }

    func onFail(_ error: MoyaError, target: TargetType) {
        let tag: [Tag] = [.API, .RESPONSE, .FAIL]
        Log.tag(tag).d("———————————— ❌ Network Error Log ❌ ————————————")

        Log.tag(tag).d("[TARGET] : \(target)")
        Log.tag(tag).d("[ErrorCode] : \(error.errorCode)")

        if let errorMessage = error.failureReason ?? error.errorDescription {
            Log.tag(tag).d("[Message] : \(errorMessage)")
        }

        if let response = error.response {
            Log.tag(tag).d("[Response] : \(prettyPrintJSON(response.data))")
        }
        
        Log.tag(tag).d(endSepartorString)
    }
}

private extension MoyaLoggerPlugin {
    var endSepartorString: String {
        return "————————————————————————————————————————————————————"
    }

    func prettyPrintJSON(_ data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let prettyPrintedString = String(data: prettyData, encoding: .utf8) {
            return prettyPrintedString
        } else {
            return String(decoding: data, as: UTF8.self)
        }
    }
}
