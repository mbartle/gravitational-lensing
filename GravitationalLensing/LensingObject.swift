//
//  File.swift
//  GravitationalLensing
//
//  Created by Mason Bartle on 6/2/16.
//  Copyright © 2016 Mason Bartle. All rights reserved.
//

import UIKit

class LensingObject: UIView {
    
    let objFrame = CGRect()
    let lensingObject = UIBezierPath(arcCenter: CGPointMake(100, 100), radius: 100, startAngle: 0, endAngle: 3.14, clockwise: true)
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        let blackHoleButton = UIButton(frame: CGRect(origin: self.center, size: CGSize(width: 100, height: 100)))
        blackHoleButton.backgroundColor = UIColor.redColor()
        addSubview(blackHoleButton)
    }
    
}
