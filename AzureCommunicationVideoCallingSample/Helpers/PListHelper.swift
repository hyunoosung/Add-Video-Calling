//
//  PListHelper.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/06.
//

import Foundation

func getPlistInfo(resourceName: String, key: String) -> String {
    guard let path = Bundle.main.path(forResource: resourceName, ofType: "plist"),
          let configValues = NSDictionary(contentsOfFile: path),
          let value = configValues[key] as? String else {
            return ""
        }

    return value
}
