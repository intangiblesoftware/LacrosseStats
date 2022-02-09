//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  INSOPlayerCollectionViewCell.swift
//  MensStatsTracker
//
//  Created by James Dabrowski on 9/28/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import UIKit

class INSOPlayerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var playerNumberLabel: UILabel!
    @IBInspectable var highlightColor: UIColor?

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.white
        layer.borderColor = highlightColor?.cgColor
        layer.borderWidth = 1.0
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = self.highlightColor
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = UIColor.white
                }
            }
        }
    }
}
