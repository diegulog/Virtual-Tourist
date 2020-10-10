//
//  ErrorResponse.swift
//  Virtual Tourist
//
//  Created by Diego on 07/10/2020.
//

import Foundation

struct ErrorResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension ErrorResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
