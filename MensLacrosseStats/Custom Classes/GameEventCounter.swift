//
//  GameEventCounter.swift
//  MensLacrosseStats
//
//  Created by Jim Dabrowski on 2/11/22.
//  Copyright © 2022 Intangible Software. All rights reserved.
//

import Foundation
import CoreData

@objc class GameEventCounter: NSObject {
    private var game: Game
    private var moc: NSManagedObjectContext
    private var isWatchingHomeTeam: Bool
    
    // MARK: - Lifecycle (do we still do this in swift?)
    @objc init?(with game: Game) {
        self.game = game
        isWatchingHomeTeam = game.homeTeam == game.teamWatching
        guard let gameMoc = game.managedObjectContext else {
            // If the game doesn't have a moc, we're screwed anyway so just bail.
            return nil
        }
        moc = gameMoc
    }
    
    // Count various events
    @objc func count(events eventCode: INSOEventCode) -> Int {
        let predicate:NSPredicate = NSPredicate(format: "game == %@ AND event.eventCode == %@", game, eventCode as! CVarArg)
        return GameEvent().aggregate(operation: "count", on: "timestamp", with: predicate, in: moc).intValue
    }
    
    @objc func count(events eventCode: INSOEventCode, for rosterPlayer: RosterPlayer) -> Int {
        return -1
    }
    
    @objc func countHomeTeam(events eventCode: INSOEventCode) -> Int {
        return -1
    }
    
    @objc func countVisitingTeam(events eventCode: INSOEventCode) -> Int {
        return -1
    }
    
    @objc func countHomeTeamFreePosition(events eventCode: INSOEventCode) -> Int {
        return -1
    }
    
    @objc func countVisitingTeamFreePosition(events eventCode: INSOEventCode) -> Int {
        return -1
    }
    
    @objc func countFreePosition(events eventCode: INSOEventCode, for rosterPlayer: RosterPlayer) -> Int {
        return -1
    }
    
    // Count extra-man stuff
    @objc func extraManGoalsForHomeTeam() -> Int {
        return -1
    }
    
    @objc func extraManGoalsForVisitingTeam() -> Int {
        return -1
    }
    
    // Count penalty stuff
    @objc func totalPenaltiesForHomeTeam() -> Int {
        return -1
    }
    
    @objc func totalPenaltiesForVisitingTeam() -> Int {
        return -1
    }
    
    @objc func totalBoysPenalties(for: RosterPlayer) -> Int {
        return -1
    }
    
    @objc func totalGirlsPenalties(for: RosterPlayer) -> Int {
        return -1
    }
    
    @objc func totalPenaltyTimeForHomeTeam() -> Int {
        return -1
    }
    
    @objc func totalPenaltyTimeForVisitingTeam() -> Int {
        return -1
    }
    
    @objc func totalPenaltyTime(for: RosterPlayer) -> Int {
        return -1
    }
    
    // Count fouls (yes, they're different)
    @objc func totalFoulsForHomeTeam() -> Int {
        return -1
    }
    
    @objc func totalFoulsForVisitingTeam() -> Int {
        return -1
    }    
}

extension NSManagedObject {
    func aggregate(operation: String, on attribute: String, with predicate: NSPredicate, in managedObjectContext: NSManagedObjectContext) -> NSNumber {
        
        let expression = NSExpression(forFunction: operation, arguments: [attribute])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "result"
        expressionDescription.expression = expression

        let properties = [expressionDescription]
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.propertiesToFetch = properties
        request.resultType = .dictionaryResultType
        request.includesPendingChanges = true
        request.predicate = predicate
        request.entity = NSEntityDescription.entity(forEntityName: String(describing: self), in: managedObjectContext)
        request.predicate = predicate
        
        do {
            let results = try managedObjectContext.execute(request)
            let value = results.value(forKey: "result")
            return value as! NSNumber
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return 0
        }
    }
}
