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
//    @objc func count(events eventCode: INSOEventCode) -> Int {
//        let predicate:NSPredicate = NSPredicate(format: "game == %@ AND event.eventCode == %@", game, eventCode as! CVarArg)
//        return GameEvent().aggregate(operation: "count", on: "timestamp", with: predicate, in: moc).intValue
//    }
    
    @objc func count(events eventCode: INSOEventCode, for rosterPlayer: RosterPlayer) -> Int {
        var eventCount = 0
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player == %@", argumentArray: [game, eventCode.rawValue, rosterPlayer])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        return eventCount
    }
    
    @objc func countHomeTeam(events eventCode: INSOEventCode) -> Int {
        var eventCount = 0
        let teamPlayerNumber = isWatchingHomeTeam ? INSOTeamWatchingPlayerNumber : INSOOtherTeamPlayerNumber
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player.number == %@", argumentArray: [game, eventCode.rawValue, teamPlayerNumber])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        // First count up the team player events
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up the players' events
        if isWatchingHomeTeam {
            // Now cycle through all the players as well.
            eventCount += countPlayer(events: eventCode);
        }
        
        return eventCount
    }
    
    @objc func countVisitingTeam(events eventCode: INSOEventCode) -> Int {
        var eventCount = 0
        let teamPlayerNumber = isWatchingHomeTeam ? INSOOtherTeamPlayerNumber : INSOTeamWatchingPlayerNumber
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player.number == %@", argumentArray: [game, eventCode.rawValue, teamPlayerNumber])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        // First count up the team player events
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up the players' events
        if !isWatchingHomeTeam {
            // Now cycle through all the players as well.
            eventCount += countPlayer(events: eventCode)
        }
        
        return eventCount
    }
    
    @objc func countHomeTeamFreePosition(events eventCode: INSOEventCode) -> Int {
        var eventCount = 0
        
        let playerNumber = isWatchingHomeTeam ? INSOTeamWatchingPlayerNumber : INSOOtherTeamPlayerNumber
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode = %@ AND player.number == %@ AND is8m == %@", argumentArray: [game, eventCode.rawValue, playerNumber, true])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        // count up team player events
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up player events
        if isWatchingHomeTeam {
            // Now cycle through all the players as well.
            eventCount += countFreePositionPlayer(events: eventCode)
        }
        
        return eventCount
    }
    
    @objc func countVisitingTeamFreePosition(events eventCode: INSOEventCode) -> Int {
        var eventCount = 0
        
        let playerNumber = isWatchingHomeTeam ? INSOOtherTeamPlayerNumber : INSOTeamWatchingPlayerNumber
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode = %@ AND player.number == %@ AND is8m == %@", argumentArray: [game, eventCode.rawValue, playerNumber, true])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        // count up team player events
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up player events
        if !isWatchingHomeTeam {
            // Now cycle through all the players as well.
            eventCount += countFreePositionPlayer(events: eventCode)
        }
        
        return eventCount
    }
    
    @objc func countFreePosition(events eventCode: INSOEventCode, for rosterPlayer: RosterPlayer) -> Int {
        var eventCount = 0
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player == %@ AND is8m == %@", argumentArray: [game, eventCode.rawValue, rosterPlayer, true])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        return eventCount
    }
    
    // Count extra-man stuff
    @objc func extraManGoalsForHomeTeam() -> Int {
        var eventCount = 0
        let eventCode = INSOEventCode.codeGoal
        let playerNumber = isWatchingHomeTeam ? INSOTeamWatchingPlayerNumber : INSOOtherTeamPlayerNumber
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player.number == %@ and isExtraManGoal == %@", argumentArray: [game, eventCode.rawValue, playerNumber, true])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up player events
        if isWatchingHomeTeam {
            // Now cycle through all the players as well.
            for rosterPlayer in game.players! {
                if (rosterPlayer.numberValue >= 0) {
                    for gameEvent in rosterPlayer.events! {
                        if gameEvent.isExtraManGoalValue {
                            eventCount += 1
                        }
                    }
                }
            }
        }
        
        return eventCount
    }
    
    @objc func extraManGoalsForVisitingTeam() -> Int {
        var eventCount = 0
        let eventCode = INSOEventCode.codeGoal
        let playerNumber = isWatchingHomeTeam ? INSOOtherTeamPlayerNumber : INSOTeamWatchingPlayerNumber
        
        let predicate = NSPredicate(format: "game == %@ AND event.eventCode == %@ AND player.number == %@ and isExtraManGoal == %@", argumentArray: [game, eventCode.rawValue, playerNumber, true])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        // Now count up player events
        if !isWatchingHomeTeam {
            // Now cycle through all the players as well.
            for rosterPlayer in game.players! {
                if (rosterPlayer.numberValue >= 0) {
                    for gameEvent in rosterPlayer.events! {
                        if gameEvent.isExtraManGoalValue {
                            eventCount += 1
                        }
                    }
                }
            }
        }
        
        return eventCount
    }
    
    // Count penalty stuff
    @objc func totalPenaltiesForHomeTeam() -> Int {
        var eventCount = 0
        let personalFouls = INSOCategoryCode.personalFouls.rawValue
        let technicalFouls = INSOCategoryCode.technicalFouls.rawValue
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        
        // Now count up player events
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue == INSOOtherTeamPlayerNumber {
                // skip counting the other team
                continue
            }
            let predicate = NSPredicate(format: "game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", argumentArray: [game, personalFouls, technicalFouls, rosterPlayer.numberValue])
            fetchRequest.predicate = predicate
            
            do {
                eventCount += try moc.count(for: fetchRequest)
            } catch {
                eventCount += 0
            }

        }

        return eventCount
    }
    
    @objc func totalPenaltiesForVisitingTeam() -> Int {
        var eventCount = 0
        let personalFouls = INSOCategoryCode.personalFouls.rawValue
        let technicalFouls = INSOCategoryCode.technicalFouls.rawValue
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        
        // Now count up player events
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue != INSOOtherTeamPlayerNumber {
                // skip all but the other team
                continue
            }
            let predicate = NSPredicate(format: "game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", argumentArray: [game, personalFouls, technicalFouls, rosterPlayer.numberValue])
            fetchRequest.predicate = predicate
            
            do {
                eventCount += try moc.count(for: fetchRequest)
            } catch {
                eventCount += 0
            }

        }

        return eventCount
    }
    
    @objc func totalBoysPenalties(for rosterPlayer: RosterPlayer) -> Int {
        var eventCount = 0
        let personalFouls = INSOCategoryCode.personalFouls.rawValue
        let technicalFouls = INSOCategoryCode.technicalFouls.rawValue

        let predicate = NSPredicate(format: "game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player == %@", argumentArray: [game, personalFouls, technicalFouls, rosterPlayer])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        return eventCount
    }
    
    @objc func totalGirlsPenalties(for rosterPlayer: RosterPlayer) -> Int {
        var eventCount = 0
        let minorFouls = INSOEventCode.codeMinorFoul.rawValue
        let majorFouls = INSOEventCode.codeMajorFoul.rawValue

        let predicate = NSPredicate(format: "game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player == %@", argumentArray: [game, minorFouls, majorFouls, rosterPlayer])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        
        do {
            eventCount = try moc.count(for: fetchRequest)
        } catch {
            return -1
        }
        
        return eventCount
    }
    
    @objc func totalPenaltyTimeForHomeTeam() -> Int {
        var penaltyTime = 0
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue == INSOOtherTeamPlayerNumber {
                // skip all but the other team
                continue
            }
            
            penaltyTime += totalPenaltyTime(for: rosterPlayer)

        }
        return penaltyTime
    }
    
    @objc func totalPenaltyTimeForVisitingTeam() -> Int {
        var penaltyTime = 0
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue != INSOOtherTeamPlayerNumber {
                // skip all but the other team
                continue
            }
            
            penaltyTime += totalPenaltyTime(for: rosterPlayer)

        }
        return penaltyTime
    }
    
    @objc func totalPenaltyTime(for rosterPlayer: RosterPlayer) -> Int {
        var penaltyTime = 0
        
        let predicate = NSPredicate(format: "game == %@ and player.number == %@", argumentArray: [game, rosterPlayer.numberValue])
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        fetchRequest.predicate = predicate
        let sortByNumber = NSSortDescriptor(key: "player.number", ascending: true)
        fetchRequest.sortDescriptors = [sortByNumber]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            if let events = fetchedResultsController.fetchedObjects {
                for gameEvent in events {
                    penaltyTime += gameEvent.penaltyTime?.intValue ?? 0
                }
            }
        } catch {
            return penaltyTime
        }
        
        return penaltyTime
    }
    
    // Count fouls (yes, they're different)
    @objc func totalFoulsForHomeTeam() -> Int {
        var eventCount = 0
        let minorFouls = INSOEventCode.codeMinorFoul.rawValue
        let majorFouls = INSOEventCode.codeMajorFoul.rawValue
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        
        // Now count up player events
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue == INSOOtherTeamPlayerNumber {
                // skip counting the other team
                continue
            }
            let predicate = NSPredicate(format: "game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player.number == %@", argumentArray: [game, minorFouls, majorFouls, rosterPlayer.numberValue])
            fetchRequest.predicate = predicate
            
            do {
                eventCount += try moc.count(for: fetchRequest)
            } catch {
                eventCount += 0
            }

        }

        return eventCount
    }
    
    @objc func totalFoulsForVisitingTeam() -> Int {
        var eventCount = 0
        let minorFouls = INSOEventCode.codeMinorFoul.rawValue
        let majorFouls = INSOEventCode.codeMajorFoul.rawValue
        let fetchRequest = NSFetchRequest<GameEvent>(entityName: "GameEvent")
        
        // Now count up player events
        for rosterPlayer in game.players! {
            if rosterPlayer.numberValue != INSOOtherTeamPlayerNumber {
                // skip counting the other team
                continue
            }
            let predicate = NSPredicate(format: "game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player.number == %@", argumentArray: [game, minorFouls, majorFouls, rosterPlayer.numberValue])
            fetchRequest.predicate = predicate
            
            do {
                eventCount += try moc.count(for: fetchRequest)
            } catch {
                eventCount += 0
            }

        }

        return eventCount
    }
    
    private func countPlayer(events eventCode: INSOEventCode) -> Int {
        var playerCount = 0
        for rosterPlayer in game.players! {
            if (rosterPlayer.numberValue >= 0) {
                playerCount += count(events: eventCode, for: rosterPlayer)
            }
        }
        return playerCount
    }

    private func countFreePositionPlayer(events eventCode: INSOEventCode) -> Int {
        var playerCount = 0
        for rosterPlayer in game.players! {
            if (rosterPlayer.numberValue >= 0) {
                playerCount += countFreePosition(events: eventCode, for: rosterPlayer)
            }
        }
        return playerCount
    }
}
