//
//  Extension + UIApplication.swift
//  MoyaStructureProject
//
//  Created by 김현구 on 10/29/24.
//

import Foundation
import UIKit
import Toast

extension UIApplication {

    var keyWindow: UIWindow? {
        return connectedScenes
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .map { $0 as? UIWindowScene }
            .map { $0?.windows.first } ?? UIApplication.shared.delegate?.window ?? UIApplication.shared.keyWindow
    }
    
    static func makeToast(_ message: String?) {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.makeToast(message, position: .center)
        }
    }
    
    static func makeToastAsync(_ message: String?) async {
        makeToast(message)
    }
}
