//
//  INSOGameTableViewCell.swift
//  LacrosseStats
//
//  Created by Jim Dabrowski on 1/27/22.
//  Copyright © 2022 Intangible Software. All rights reserved.
//

import Foundation
import UIKit

class INSOGameTableViewCell: UITableViewCell {
    // IBOutlets
    @IBOutlet weak var gameDateTimeLabel: UILabel!
    @IBOutlet weak var homeTeamLabel: UILabel!
    @IBOutlet weak var visitingTeamLabel: UILabel!
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var visitingScoreLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
}
