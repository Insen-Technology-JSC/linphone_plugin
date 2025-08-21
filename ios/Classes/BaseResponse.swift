//
//  BaseResponse.swift
//  Runner
//
//  Created by tuanhuynh on 04/09/2024.
//

import Foundation

struct BaseResponse : Codable {
    let funcName: String?
    let isRegister: Bool?
    let remoteAddress: String?
    
    func toString()->String?{
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self)
            return String(data: jsonData, encoding: String.Encoding.utf8)
        } catch {
            return ""
        }
    }
    
}
