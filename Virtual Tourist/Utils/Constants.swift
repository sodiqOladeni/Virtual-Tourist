//
//  Constants.swift
//  Virtual Tourist
//
//  Created by sodiqOladeni on 10/04/2020.
//  Copyright © 2020 NotZero Technologies. All rights reserved.
//

import Foundation

class Constants {
    
    struct App {
        static let appName = "Virtual Tourist"
        static let appHasLaunchBefore = "AppHasLaunchBefore"
    }
    
    struct Identifier {
        static let mapPinId = "mappin"
        static let navigateToAlbumViewController = "to_tourDetailsViewController"
        static let albumCollectionCellId = "albumCollectionCell"
    }
    
    struct UserDefaultKey {
        static let latitudeKey = "LatitudeKey"
        static let longitudeKey = "LongitudeKey"
        static let latitudeDeltaKey = "LatitudeDeltaKey"
        static let longitudeDeltaKey = "LongitudeDeltaKey"
    }
}
