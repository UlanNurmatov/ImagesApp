//
//  HTTPRequestManager.swift
//  ImagesApp
//
//  Created by Ulan Nurmatov on 2/7/20.
//  Copyright © 2020 Ulan Nurmatov. All rights reserved.
//

import Foundation
import Alamofire
import SystemConfiguration

class HTTPRequestManager {
    
    typealias SuccessHandler = (Data?) -> ()
    typealias FailureHandler = (Data?)-> ()
    typealias NetworkFailureHandler = (String)-> ()
    typealias Parameter = [String: Any]?
    
    
    private func request(method: HTTPMethod, endpoint: String, parameters: Parameter, header: HTTPHeaders?, completion: @escaping SuccessHandler, statusErrorMessage: @escaping FailureHandler, networkError: @escaping NetworkFailureHandler) {
        
        if !isConnectedToNetwork() {
            networkError(Constants.Network.ErrorMessage.NO_INTERNET_CONNECTION)
            return
        }
        
        let apiUrl = "https://api.pexels.com/v1/curated?" + endpoint
        
        Alamofire.request(apiUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, method: method, parameters: parameters, encoding: URLEncoding.default , headers: header ?? [:]).responseJSON { (response:DataResponse<Any>) in
            
            guard response.response != nil else {
                networkError(Constants.Network.ErrorMessage.UNABLE_LOAD_DATA)
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                networkError(Constants.Network.ErrorMessage.NO_HTTP_STATUS_CODE)
                return
            }
            
            print("\(statusCode) - \(apiUrl)")
            
            switch(statusCode) {
            case HTTPStatusCode.badRequest.statusCode:
                statusErrorMessage(response.data)
            case HTTPStatusCode.unauthorized.statusCode:
                statusErrorMessage(response.data)
            case HTTPStatusCode.ok.statusCode,
                 HTTPStatusCode.accepted.statusCode,
                 HTTPStatusCode.created.statusCode:
                
                completion(response.data)
                break
            default:
                networkError(response.error?.localizedDescription ?? "Something went wrong")
            }
        }
    }
   
    internal func get(endpoint: String, header: HTTPHeaders, completion: @escaping SuccessHandler, error: @escaping FailureHandler, networkError: @escaping NetworkFailureHandler) {
        request(method: .get, endpoint: endpoint, parameters: nil, header: header, completion: completion, statusErrorMessage: error, networkError: networkError)
    }
    
}

// MARK: - Internet Connectivity

extension HTTPRequestManager {
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}
