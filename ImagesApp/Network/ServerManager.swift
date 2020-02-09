//
//  ServerManager.swift
//  ImagesApp
//
//  Created by Ulan Nurmatov on 2/7/20.
//  Copyright © 2020 Ulan Nurmatov. All rights reserved.
//

import Foundation
import Alamofire

class ServerManager: HTTPRequestManager {
    
    static let shared = ServerManager()
    
    func getPhotos(page: Int, per_page: Int, header: HTTPHeaders, completion: @escaping (Photos) -> (), error: @escaping (ErrorResponse) -> (), networkError: @escaping (String)->()) {
        
        self.get(endpoint: "page=\(page)&per_page=\(per_page)", header: header, completion: { (data) in
            do {
                guard let  data = data else { return }
                let result = try JSONDecoder().decode(Photos.self, from: data)
                completion(result)
            }
            catch let errorMessage {
                networkError(errorMessage.localizedDescription)
            }
        }, error: { (data) in
            do {
                guard let data = data else { return }
                let result = try JSONDecoder().decode(ErrorResponse.self, from: data)
                error(result)
            }
            catch let errorMessage {
                networkError(errorMessage.localizedDescription)
            }
        }) { (errorMessage) in
            networkError(errorMessage)
        }
    }
    
}
