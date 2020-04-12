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
        static let baseUrl = "https://www.flickr.com/services/rest/"
        static let photoForLocation = "?method=flickr.photos.search&api_key=\(FlickrClient.apiKey)"
        static let photosCount = 30
        
        case createGetPhotoForLocation(Double, Double)
        case getAPhoto(String)
        
        var stringValue:String{
            switch self {
            case .createGetPhotoForLocation(let lon, let lat):
                return FlickrEndpoint.baseUrl+FlickrEndpoint.photoForLocation+"&lat=\(lat)&lon=\(lon)"+"&per_page=\(FlickrEndpoint.photosCount)"+"&format=json"
            case .getAPhoto(let photoId):
                return "https://www.flickr.com/photo.gne?rb=1&id=\(photoId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotosForLocation(latitude:Double, longitude:Double, completionHandler: @escaping (PhotosResponse?, Error?) ->Void) {
        let task = URLSession.shared.dataTask(with: FlickrEndpoint.createGetPhotoForLocation(3.879290, 7.348720).url, completionHandler: { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                print("Before ==> ")
                let responseObject = try decoder.decode(PhotosResponse.self, from: data)
                print("After ==> \(responseObject)")
                DispatchQueue.main.async {
                    completionHandler(responseObject, nil)
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    class func downloadPhotoWithId(imageId:String, completion: @escaping (Data, Error?)-> Void) {
        var request = URLRequest(url: URL(string: FlickrEndpoint.getAPhoto(imageId).stringValue)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: FlickrEndpoint.getAPhoto(imageId).url) { data, response, error in
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
