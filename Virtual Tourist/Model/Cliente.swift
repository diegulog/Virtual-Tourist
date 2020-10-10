//
//  Client.swift
//  Virtual Tourist
//
//  Created by Diego on 06/10/2020.
//

import Foundation

class Cliente {

    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/?method="
        static let apiKey = "4b0e0571f8a70030de3288ccef403f71"

        case search(Int, Int, Double, Double)
        
        var stringValue: String {
            switch self {
            case .search(let page,let perPage, let latitude, let longitude): return Endpoints.base + "flickr.photos.search&media=photos&per_page=\(perPage)&format=json&nojsoncallback=1&api_key=\(Endpoints.apiKey)&page=\(page)&lat=\(latitude)&lon=\(longitude)&radius=1"
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getRandomPageNum(photosAvailable: Int, maxPhotosDisplayed: Int = 18) -> Int {
      let flickrLimit = 4000
      let pages = min(photosAvailable , flickrLimit) / maxPhotosDisplayed
      return Int.random(in: 0...pages)
    }
    
    class func search(page:Int = 1, perPage:Int = 18, lat: Double,lon: Double, completion: @escaping (PhotosResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: Endpoints.search(page,perPage, lat, lon).url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(searchResponse.photos, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }.resume()
    }
    
    class func downloadImage(path: URL, completion: @escaping (Data?, Error?) -> Void) {
        URLSession.shared.dataTask(with: path) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }.resume()
    }
}
