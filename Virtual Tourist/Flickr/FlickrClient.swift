//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by sodiqOladeni on 10/04/2020.
//  Copyright © 2020 NotZero Technologies. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let apiKey = "2c353399228505d1c141699787e6313c"
    
    enum FlickrEndpoint {
        static let baseUrl = "https://api.flickr.com/services/rest/"
        static let photoForLocation = "?method=flickr.photos.search&api_key=\(FlickrClient.apiKey)"
        static let photosCount = 30
        
        case createGetPhotoForLocation(Double, Double)
        case getAPhoto(String)
        
        var stringValue:String{
            switch self {
            case .createGetPhotoForLocation(let lon, let lat):
                return FlickrEndpoint.baseUrl+FlickrEndpoint.photoForLocation+"&lat=\(lat)&lon=\(lon)"+"&per_page=\(FlickrEndpoint.photosCount)"+"&format=json&nojsoncallback=1&extras=url_n"
            case .getAPhoto(let photoId):
                return "https://www.flickr.com/photo.gne?rb=1&id=\(photoId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotosForLocation(latitude:Double, longitude:Double, completionHandler: @escaping (PhotosResponse?, Error?) ->Void) {
        var request = URLRequest(url: FlickrEndpoint.createGetPhotoForLocation(longitude, latitude).url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PhotosResponse.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject, nil)
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    class func downloadPhotoWithId(photoUrl:String, completion: @escaping (Data, Error?)-> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: photoUrl)!) { data, response, error in
            if let data = data{
                DispatchQueue.main.async {
                    completion(data, error)
                }
            }else{
                print(error!.localizedDescription)
            }
        }
        task.resume()
    }
}
