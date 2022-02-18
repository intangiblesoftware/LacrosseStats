//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  UIColor+INSOScorebookColor.swift
//  ScorebookLite
//
//  Created by James Dabrowski on 9/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import UIKit

@objc extension UIColor {
    class func mainColor() -> UIColor? {
        if Target.isMens {
            return UIColor.scorebookBlue()
        } else {
            return UIColor.scorebookTeal()
        }
    }
    
    class func scorebookBlue() -> UIColor? {
        // rgb(0, 59, 111);
        return UIColor(red: 0.000, green: 0.231, blue: 0.435, alpha: 1.000)
    }

    class func scorebookBackgroundWhite() -> UIColor? {
        return UIColor(red: 0.961, green: 0.973, blue: 0.980, alpha: 1.000)
    }

    class func scorebookText() -> UIColor? {
        // rgb(19, 45 ,26) ?
        return UIColor(red: 0.075, green: 0.176, blue: 0.102, alpha: 1.000)
    }

    class func scorebookGreen() -> UIColor? {
        // rgb(47, 118, 20)
        return UIColor(red: 0.184, green: 0.463, blue: 0.078, alpha: 1.000)
    }

    class func scorebookYellow() -> UIColor? {
        // rgb(237, 186, 38);
        return UIColor(red: 0.925, green: 0.733, blue: 0.149, alpha: 1.000)
    }

    class func scorebookRed() -> UIColor? {
        // rgb(129, 0, 15);
        return UIColor(red: 0.506, green: 0.000, blue: 0.059, alpha: 1.000)
    }

    class func scorebookTeal() -> UIColor? {
        // rgb(42, 126, 133);
        return UIColor(red: 0.165, green: 0.494, blue: 0.522, alpha: 1.000)
    }

    class func scorebookBackgroundTeal() -> UIColor? {
        // rgb (245, 250, 250)
        return UIColor(red: 0.961, green: 0.980, blue: 0.980, alpha: 1.000)
    }
}
