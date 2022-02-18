//
//  StatsFileGenerator.swift
//  LacrosseStats
//
//  Created by Jim Dabrowski on 2/16/22.
//  Copyright © 2022 Intangible Software. All rights reserved.
//

class StatsFileGenerator {

    // I think I don't need these,
    // I think I just need optional properties that return the stats files
    // we'll see about that. 
    var hasMaxPrepsStats = false
    var hasPlayerStats = false
    var hasGameSummaryStats = false
        
    // MARK: - Private properties
    private var game: Game?
    private var eventCounter: GameEventCounter?
    
    // MARK: - Lifecycle
    init() {
        // We want to be able to create a file generator without a game
        // anything that uses it, will only know that the game stats files aren't there
    }
    
    init(with game: Game?) {
        self.game = game
        if let game = game {
            self.eventCounter = GameEventCounter(with: game)
        }
    }
    
}
