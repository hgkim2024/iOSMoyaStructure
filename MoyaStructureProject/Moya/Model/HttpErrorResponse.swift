//
//  HttpErrorResponse.swift
//  MoyaStructureProject
//
//  Created by 김현구 on 10/29/24.
//

import Foundation

struct HttpErrorResponse: Error, Decodable {
    let status: String
    let code: String
    let message: String

    static let base = HttpErrorResponse(status: "INTERNAL_SERVER_ERROR", code: "000", message: "데이터 통신에 실패했어요.\n잠시후 다시 시도해 주세요.")
}

