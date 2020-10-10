//
//  SearchResponse.swift
//  Virtual Tourist
//
//  Created by Diego on 06/10/2020.
//

import Foundation

struct SearchResponse: Codable {
    let photos: PhotosResponse
    let stat: String
}

struct PhotosResponse: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoResponse]
}

struct PhotoResponse: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let title: String
}
