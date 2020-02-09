//
//  PhotoInfo.swift
//  ImagesApp
//
//  Created by Ulan Nurmatov on 2/7/20.
//  Copyright © 2020 Ulan Nurmatov. All rights reserved.
//

import Foundation

struct Photos: Decodable {
    
    var photos: [PhotoInfo] = []
}

struct PhotoInfo: Decodable {
    
    var src: PhotoUrls?
    
}

struct PhotoUrls: Decodable {
    
    var medium: String?
    var portrait: String?
}
