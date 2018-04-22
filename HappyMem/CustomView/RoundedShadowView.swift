//
//  RoundedShadowView.swift
//  HappyMem
//
//  Created by Alisher Abdukarimov on 4/22/18.
//  Copyright © 2018 Alisher Abdukarimov. All rights reserved.
//

import UIKit


@IBDesignable
class RoundedShadowView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            // use didSet because it is a property observer meaning that it executes our view code when the cornerRadius property has been set by Interface Builder.
            setUpView()
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        didSet {
            setUpView()
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            setUpView()
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0.0, height: 0.0) {
        didSet {
            setUpView()
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            setUpView()
        }
    }
    
    // prepareForInterfaceBuilder() When Interface Builder instantiates a class with the IB_DESIGNABLE attribute, it calls this method to let the resulting object know that it was created at design time. You can implement this method in your designable classes and use it to configure their design-time appearance. For example, you might use the method to configure a custom text control with a default string. The system does not call this method; only Interface Builder calls it.
    
    // Interface Builder waits until all objects in a graph have been created and initialized before calling this method. So if your object’s runtime configuration relies on subviews or parent views, those objects should exist by the time this method is called.
    
    // Your implementation of this method must call super at some point so that parent classes can perform their own custom setup.
    override func prepareForInterfaceBuilder() {
        setUpView()
    }
    
    func setUpView() {
        //To make the view corners circular
        layer.cornerRadius = cornerRadius
        // Color
        layer.shadowColor = shadowColor?.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
    }
    
    
}
