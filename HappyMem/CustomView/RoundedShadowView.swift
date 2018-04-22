//
//  RoundedShadowView.swift
//  HappyMem
//
//  Created by Alisher Abdukarimov on 4/22/18.
//  Copyright © 2018 Alisher Abdukarimov. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            // use didSet because it is a property observer meaning that it executes our view code when the cornerRadius property has been set by Interface Builder.
            layer.cornerRadius = cornerRadius
            
        }
    }
}
