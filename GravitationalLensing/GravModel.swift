//
//  GravModel.swift
//  GravitationalLensing
//
//  Created by Mason Bartle on 6/8/16.
//  Copyright © 2016 Mason Bartle. All rights reserved.
//

import Foundation

class GravModel: NSObject {
    
    // MARK: Initialization
    var screenWidth: Int?
    var screenHeight: Int?
    var textureWidth: Int?
    var textureHeight: Int?
    var meshFactor: Int?
    
    init(width: Int, height: Int, factor: Int, texWidth: Int, texHeight: Int){
        super.init()
        
        // Set instance varaibles
        screenWidth = width; screenHeight = height; textureWidth = texWidth; textureHeight = texHeight
        meshFactor = factor
    }
}