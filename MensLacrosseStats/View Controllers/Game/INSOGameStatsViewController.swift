//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  INSOGameStatsViewController.swift
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import UIKit

enum INSOStatSourceIndex : Int {
    case game
    case player
}

struct EventStats {
    let statName: String
    let homeStat: String
    let visitorStat: String
}

struct Section {
    let title: String
    let stats: [EventStats]?
}

struct GameStats {
    let sections: [Section]
}

private let INSOGameStatsCellIdentifier = "GameStatsCell"
private let INSOPlayerStatsCellIdentifier = "PlayerStatCell"

class INSOGameStatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var game: Game?
    
    // MARK: - Private Properties
    private lazy var eventCounter: INSOGameEventCounter = INSOGameEventCounter(game: game)

    private var gameStats: GameStats {

        // Add fielding sub-array
        let fieldingStats = fieldingEvents()

//            // Add scoring sub-array
//        if let scoringDictionary = scoringEvents() {
//            // FIXME: Fix scoringEvents function
//        }
//
//            // Add extra-man events
//        if let extraManDictionary = extraManEvents() {
//            // FIXME: Fix extraManEvents function
//        }
//
//            // Add penalty sub-array
//        if let penaltyDictionary = penaltyEvents() {
//            // FIXME: Fix penaltyEvents function
//        }
//
        return GameStats(sections: [fieldingStats])
    }

//    private lazy var playerStatsArray: [AnyHashable] = {
//        var temp: [AnyHashable] = []
//
//        guard var gamePlayers = game.players?.sorted(by: { player1, player2 in
//            player1.numberValue > player2.numberValue
//        }) else {
//            return temp
//        }
//
//        gamePlayers.removeAll(where: { $0.numberValue < 0 })
//
//        for rosterPlayer in gamePlayers {
//            if let playerStatsDictionary = statsDictionary(for: rosterPlayer) {
//                // FIXME: Fix statsDictionary method
//            }
//        }
//
//        return temp
//    }()

    private var managedObjectContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }()

    private lazy var percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        return percentFormatter
    }()
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statsTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - IBOutlets
    @IBOutlet private weak var statsTable: UITableView!
    @IBOutlet private weak var statSourceSegmentedControl: UISegmentedControl!
    
    // MARK: - IBActions
    @IBAction func changeStats(_ sender: Any?) {
        statsTable.reloadData()

        // Scroll to top of player stats array (if we have somewhere to scroll to)
//        if (playerStatsArray.count > 0) {
//            statsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
//        }
    }

    // MARK: - Private Methods
    func configureGameStatCell(_ cell: INSOGameStatTableViewCell, at indexPath: IndexPath?) {
        var statName = ""
        var homeStat = ""
        var visitorStat = ""
        
        guard let section = indexPath?.section else {
            return
        }
        guard let row = indexPath?.row else {
            return
        }
        
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            guard let eventStats = gameStats.sections[section].stats?[row] else {
                return
            }
            statName = eventStats.statName
            homeStat = eventStats.homeStat
            visitorStat = eventStats.visitorStat
        } else {
            // Do player stuff later
            return
        }

        cell.homeStatLabel.text = homeStat
        cell.visitorStatLabel.text = visitorStat
        cell.statNameLabel.text = statName
    }

    func fieldingEvents() -> Section {
        // Section title
        let title = NSLocalizedString("Fielding", comment: "")
        var stats: [EventStats] = []
        
        // Make sure game is not nil, bail if it is.
        guard let game = game else {
            return Section(title: title, stats: stats)
        }

        // Groundballs
        if game.didRecordEvent(INSOEventCode.codeGroundball) {
            let homeGroundBalls = eventCounter.eventCount(forHomeTeam: .codeGroundball)
            let visitorGroundBalls = eventCounter.eventCount(forVisitingTeam: INSOEventCode.codeGroundball)
            let groundBallStats = EventStats(statName: "Groundballs", homeStat: "\(homeGroundBalls ?? 0)", visitorStat: "\(visitorGroundBalls ?? 0)")
            stats.append(groundBallStats)
        }
        
        // Faceoffs
        if game.didRecordEvent(.codeFaceoffWon) && game.didRecordEvent(.codeFaceoffLost) {
            let homeFaceoffsWon: Int = eventCounter.eventCount(forHomeTeam: .codeFaceoffWon).intValue
            let homeFaceoffsLost: Int = eventCounter.eventCount(forHomeTeam: .codeFaceoffLost).intValue
            let homeFaceoffs: Int = homeFaceoffsWon + homeFaceoffsLost
            let homeFaceoffPct: Float = (homeFaceoffsWon > 0) ? Float(homeFaceoffsWon) / Float(homeFaceoffs) : 0.0
            let homeFaceoffPctString: String = percentFormatter.string(from: NSNumber(value: homeFaceoffPct)) ?? "0%"
            
            let visitorFaceoffsWon: Int = eventCounter.eventCount(forVisitingTeam: .codeFaceoffWon).intValue
            let visitorFaceoffsLost: Int = eventCounter.eventCount(forVisitingTeam: .codeFaceoffLost).intValue
            let visitorFaceoffs: Int = visitorFaceoffsWon + visitorFaceoffsLost
            let visitorFaceoffPct: Float = (visitorFaceoffsWon > 0) ? Float(visitorFaceoffsWon) / Float(visitorFaceoffs) : 0.0
            let visitorFaceoffPctString: String = percentFormatter.string(from: NSNumber(value: visitorFaceoffPct)) ?? "0%"

            let homeStatString = "\(homeFaceoffsWon)/\(homeFaceoffs) \(homeFaceoffPctString)"
            let visitorStatString = "\(visitorFaceoffsWon)/\(visitorFaceoffs) \(visitorFaceoffPctString)"
            
            let faceoffStats = EventStats(statName: "Faceoffs", homeStat: homeStatString, visitorStat: visitorStatString)
            stats.append(faceoffStats)
        }

        // Clears
        if game.didRecordEvent(.codeClearSuccessful) && game.didRecordEvent(.codeClearFailed) {
            let homeClearSuccessful: Int = eventCounter.eventCount(forHomeTeam: .codeClearSuccessful).intValue
            let homeClearFailed: Int = eventCounter.eventCount(forHomeTeam: .codeClearFailed).intValue
            let homeClears: Int = homeClearSuccessful + homeClearFailed
            let homeClearPct: Float = (homeClears > 0) ? Float(homeClearSuccessful) / Float(homeClears) : 0.0
            let homeClearPctString: String = percentFormatter.string(from: NSNumber(value: homeClearPct)) ?? "0%"
            
            let visitorClearSuccessful: Int = eventCounter.eventCount(forVisitingTeam: .codeClearSuccessful).intValue
            let visitorClearFailed: Int = eventCounter.eventCount(forVisitingTeam: .codeClearFailed).intValue
            let visitorClears: Int = visitorClearSuccessful + visitorClearFailed
            let visitorClearPct: Float = (visitorClears > 0) ? Float(visitorClearSuccessful) / Float(visitorClears) : 0.0
            let visitorClearPctString: String = percentFormatter.string(from: NSNumber(value: visitorClearPct)) ?? "0%"

            let homeStatString = "\(homeClearSuccessful)/\(homeClears) \(homeClearPctString)"
            let visitorStatString = "\(visitorClearSuccessful)/\(visitorClears) \(visitorClearPctString)"
            
            let clearStats = EventStats(statName: "Clears", homeStat: homeStatString, visitorStat: visitorStatString)
            stats.append(clearStats)
        }
        
        // Interceptions
        if game.didRecordEvent(.codeInterception) {
            let homeInterceptions = eventCounter.eventCount(forHomeTeam: .codeInterception).intValue
            let visitorInterceptions = eventCounter.eventCount(forVisitingTeam: .codeInterception).intValue

            let interceptionStats = EventStats(statName: "Interceptions", homeStat: "\(homeInterceptions)", visitorStat: "\(visitorInterceptions)")
            stats.append(interceptionStats)
        }

        // Takeaways
//        if game?.didRecordEvent(INSOEventCodeTakeaway) {
//            let homeTakeaways = eventCounter?.eventCount(forHomeTeam: INSOEventCodeTakeaway)
//            let visitorTakeaways = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeTakeaway)
//
//            if let homeTakeaways = homeTakeaways, let visitorTakeaways = visitorTakeaways {
//                sectionData.append([
//                    INSOHomeStatKey: homeTakeaways,
//                    INSOStatNameKey: "Takeaways",
//                    INSOVisitorStatKey: visitorTakeaways
//                ])
//            }
//        }

        // Turnovers
//        if game?.didRecordEvent(INSOEventCodeTurnover) {
//            let homeTurnovers = eventCounter?.eventCount(forHomeTeam: INSOEventCodeTurnover)
//            let visitorTurnovers = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeTurnover)
//
//            if let homeTurnovers = homeTurnovers, let visitorTurnovers = visitorTurnovers {
//                sectionData.append([
//                    INSOHomeStatKey: homeTurnovers,
//                    INSOStatNameKey: "Turnovers",
//                    INSOVisitorStatKey: visitorTurnovers
//                ])
//            }
//        }

        // Caused Turnovers
//        if game?.didRecordEvent(INSOEventCodeCausedTurnover) {
//            let homeCausedTurnovers = eventCounter?.eventCount(forHomeTeam: INSOEventCodeCausedTurnover)
//            let visitorCausedTurnovers = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeCausedTurnover)
//
//            if let homeCausedTurnovers = homeCausedTurnovers, let visitorCausedTurnovers = visitorCausedTurnovers {
//                sectionData.append([
//                    INSOHomeStatKey: homeCausedTurnovers,
//                    INSOStatNameKey: "Caused Turnover",
//                    INSOVisitorStatKey: visitorCausedTurnovers
//                ])
//            }
//        }

        // Unforced Errors
//        if game?.didRecordEvent(INSOEventCodeUnforcedError) {
//            let homeUnforcedError = eventCounter?.eventCount(forHomeTeam: INSOEventCodeUnforcedError)
//            let visitorUnforcedError = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeUnforcedError)
//
//            if let homeUnforcedError = homeUnforcedError, let visitorUnforcedError = visitorUnforcedError {
//                sectionData.append([
//                    INSOHomeStatKey: homeUnforcedError,
//                    INSOStatNameKey: "Unforced Error",
//                    INSOVisitorStatKey: visitorUnforcedError
//                ])
//            }
//        }

        return Section(title: title, stats: stats)
    }
         

    /* Commenting out entire game stats creation fuctions.
        Will put back one at a time as I get this implemented.
     
    func scoringEvents() -> [AnyHashable : Any]? {
        var scoringSection: [AnyHashable : Any] = [:]

        // Section title
        scoringSection[INSOSectionTitleKey] = NSLocalizedString("Scoring", comment: "")
        var sectionData: [AnyHashable] = []
        scoringSection[INSOSectionDataKey] = sectionData

        // Shots
        if game?.didRecordEvent(INSOEventCodeShot) {
            let homeShots = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShot)
            let visitorShots = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShot)

            if let homeShots = homeShots, let visitorShots = visitorShots {
                sectionData.append([
                    INSOHomeStatKey: homeShots,
                    INSOStatNameKey: "Shots",
                    INSOVisitorStatKey: visitorShots
                ])
            }
        }

        // Goals
        if game?.didRecordEvent(INSOEventCodeGoal) {
            let homeGoals = eventCounter?.eventCount(forHomeTeam: INSOEventCodeGoal)
            let visitorGoals = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeGoal)

            if let homeGoals = homeGoals, let visitorGoals = visitorGoals {
                sectionData.append([
                    INSOHomeStatKey: homeGoals,
                    INSOStatNameKey: "Goals",
                    INSOVisitorStatKey: visitorGoals
                ])
            }
        }

        // Shooting pct. (Percent of shots that result in a goal)
        if game?.didRecordEvent(INSOEventCodeShot) && game?.didRecordEvent(INSOEventCodeGoal) {
            let homeShots = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShot).intValue ?? 0
            let homeGoals = eventCounter?.eventCount(forHomeTeam: INSOEventCodeGoal).intValue ?? 0
            let homeShootingPct = (homeShots > 0) ? CGFloat(homeGoals) / CGFloat(homeShots) : 0.0
            let homeShootingPctString = percentFormatter?.string(from: NSNumber(value: Float(homeShootingPct)))

            let visitorShots = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShot).intValue ?? 0
            let visitorGoals = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeGoal).intValue ?? 0
            let visitorShootingPct = (visitorShots > 0) ? CGFloat(visitorGoals) / CGFloat(visitorShots) : 0.0
            let visitorShootingPctString = percentFormatter?.string(from: NSNumber(value: Float(visitorShootingPct)))

            sectionData.append([
                INSOHomeStatKey: homeShootingPctString ?? "",
                INSOStatNameKey: "Shooting Percent\n(Goals / Shots)",
                INSOVisitorStatKey: visitorShootingPctString ?? ""
            ])
        }

        // Shots on goal
        if game?.didRecordEvent(INSOEventCodeShotOnGoal) {
            let homeSOG = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShotOnGoal)
            let visitorSOG = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShotOnGoal)

            if let homeSOG = homeSOG, let visitorSOG = visitorSOG {
                sectionData.append([
                    INSOHomeStatKey: homeSOG,
                    INSOStatNameKey: "Shots on Goal",
                    INSOVisitorStatKey: visitorSOG
                ])
            }
        }

        // Misses = shots - shots on goal;
        if game?.didRecordEvent(INSOEventCodeShot) && game?.didRecordEvent(INSOEventCodeShotOnGoal) {
            let homeShots = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShot).intValue ?? 0
            let homeSOG = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShotOnGoal).intValue ?? 0
            var homeMisses = homeShots - homeSOG
            homeMisses = homeMisses < 0 ? 0 : homeMisses

            let visitorShots = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShot).intValue ?? 0
            let visitorSOG = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShotOnGoal).intValue ?? 0
            var visitorMisses = visitorShots - visitorSOG
            visitorMisses = visitorMisses < 0 ? 0 : visitorMisses

            sectionData.append([
                INSOHomeStatKey: NSNumber(value: homeMisses),
                INSOStatNameKey: "Misses",
                INSOVisitorStatKey: NSNumber(value: visitorMisses)
            ])
        }

        // Shooting accuracy = shots on goal / shots (what percent of your shots were on goal)
        if game?.didRecordEvent(INSOEventCodeShot) && game?.didRecordEvent(INSOEventCodeShotOnGoal) {
            let homeShots = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShot).intValue ?? 0
            let homeSOG = eventCounter?.eventCount(forHomeTeam: INSOEventCodeShotOnGoal).intValue ?? 0
            let homeAccuracy = (homeShots > 0) ? CGFloat(homeSOG) / CGFloat(homeShots) : 0.0
            let homeAccuracyString = percentFormatter?.string(from: NSNumber(value: Float(homeAccuracy)))

            let visitorShots = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShot).intValue ?? 0
            let visitorSOG = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeShotOnGoal).intValue ?? 0
            let visitorAccuracy = (visitorShots > 0) ? CGFloat(visitorSOG) / CGFloat(visitorShots) : 0.0
            let visitorAccuracyString = percentFormatter?.string(from: NSNumber(value: Float(visitorAccuracy)))

            sectionData.append([
                INSOHomeStatKey: homeAccuracyString ?? "",
                INSOStatNameKey: "Shooting Accuracy\n(Shots on Goal / Shots)",
                INSOVisitorStatKey: visitorAccuracyString ?? ""
            ])
        }

        // Assists
        if game?.didRecordEvent(INSOEventCodeAssist) {
            let homeAssists = eventCounter?.eventCount(forHomeTeam: INSOEventCodeAssist)
            let visitorAssists = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeAssist)

            if let homeAssists = homeAssists, let visitorAssists = visitorAssists {
                sectionData.append([
                    INSOHomeStatKey: homeAssists,
                    INSOStatNameKey: "Assists",
                    INSOVisitorStatKey: visitorAssists
                ])
            }
        }

        // Saves
        if game?.didRecordEvent(INSOEventCodeSave) {
            let homeSaves = eventCounter?.eventCount(forHomeTeam: INSOEventCodeSave)
            let visitorSaves = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeSave)

            if let homeSaves = homeSaves, let visitorSaves = visitorSaves {
                sectionData.append([
                    INSOHomeStatKey: homeSaves,
                    INSOStatNameKey: "Saves",
                    INSOVisitorStatKey: visitorSaves
                ])
            }
        }

        // Goals allowed
        if game?.didRecordEvent(INSOEventCodeGoalAllowed) {
            let homeGoalsAllowed = eventCounter?.eventCount(forHomeTeam: INSOEventCodeGoalAllowed)
            let visitorGoalsAllowed = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeGoalAllowed)

            if let homeGoalsAllowed = homeGoalsAllowed, let visitorGoalsAllowed = visitorGoalsAllowed {
                sectionData.append([
                    INSOHomeStatKey: homeGoalsAllowed,
                    INSOStatNameKey: "Goals Allowed",
                    INSOVisitorStatKey: visitorGoalsAllowed
                ])
            }
        }

        // Save pct. = saves / (saves + goals allowed)
        if game?.didRecordEvent(INSOEventCodeSave) && game?.didRecordEvent(INSOEventCodeGoalAllowed) {
            let homeSaves = eventCounter?.eventCount(forHomeTeam: INSOEventCodeSave).intValue ?? 0
            let homeGoalsAllowed = eventCounter?.eventCount(forHomeTeam: INSOEventCodeGoalAllowed).intValue ?? 0
            let homeSavePct = (homeSaves + homeGoalsAllowed) > 0 ? CGFloat(homeSaves) / CGFloat((homeSaves + homeGoalsAllowed)) : 0.0
            let homeSavePctString = percentFormatter?.string(from: NSNumber(value: Float(homeSavePct)))

            let visitorSaves = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeSave).intValue ?? 0
            let visitorGoalsAllowed = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeGoalAllowed).intValue ?? 0
            let visitorSavePct = (visitorSaves + visitorGoalsAllowed) > 0 ? CGFloat(visitorSaves) / CGFloat((visitorSaves + visitorGoalsAllowed)) : 0.0
            let visitorSavePctString = percentFormatter?.string(from: NSNumber(value: Float(visitorSavePct)))

            sectionData.append([
                INSOHomeStatKey: homeSavePctString ?? "",
                INSOStatNameKey: "Save Percent",
                INSOVisitorStatKey: visitorSavePctString ?? ""
            ])
        }

        return scoringSection
    }

    func extraManEvents() -> [AnyHashable : Any]? {
        var extraManSection: [AnyHashable : Any] = [:]

        // Section title
        extraManSection[INSOSectionTitleKey] = NSLocalizedString("Extra-Man", comment: "")
        var sectionData: [AnyHashable] = []
        extraManSection[INSOSectionDataKey] = sectionData

        // EMO
        if game?.didRecordEvent(INSOEventCodeEMO) {
            let homeEMO = eventCounter?.eventCount(forHomeTeam: INSOEventCodeEMO)
            let visitorEMO = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeEMO)

            if let homeEMO = homeEMO, let visitorEMO = visitorEMO {
                sectionData.append([
                    INSOHomeStatKey: homeEMO,
                    INSOStatNameKey: "Extra-man Opportunities",
                    INSOVisitorStatKey: visitorEMO
                ])
            }
        }

        // EMO goals
        if game?.didRecordEvent(INSOEventCodeEMO) && game?.didRecordEvent(INSOEventCodeGoal) {
            let homeEMOGoals = eventCounter?.extraManGoalsForHomeTeam().intValue ?? 0
            let visitorEMOGoals = eventCounter?.extraManGoalsForVisitingTeam().intValue ?? 0

            sectionData.append([
                INSOHomeStatKey: NSNumber(value: homeEMOGoals),
                INSOStatNameKey: "Extra-man Goals",
                INSOVisitorStatKey: NSNumber(value: visitorEMOGoals)
            ])

            // Just do the emo scoring here while we're at it.
            // EMO scoring = emo goals / emo
            let homeEMO = eventCounter?.eventCount(forHomeTeam: INSOEventCodeEMO).intValue ?? 0
            let visitorEMO = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeEMO).intValue ?? 0

            let homeEMOScoring = (homeEMO > 0) ? CGFloat(homeEMOGoals) / CGFloat(homeEMO) : 0.0
            let homeEMOScoringString = percentFormatter?.string(from: NSNumber(value: Float(homeEMOScoring)))
            let visitorEMOScoring = (visitorEMO > 0) ? CGFloat(visitorEMOGoals) / CGFloat(visitorEMO) : 0.0
            let visitorEMOScoringString = percentFormatter?.string(from: NSNumber(value: Float(visitorEMOScoring)))

            sectionData.append([
                INSOHomeStatKey: homeEMOScoringString ?? "",
                INSOStatNameKey: "Extra-man Scoring",
                INSOVisitorStatKey: visitorEMOScoringString ?? ""
            ])
        }

        // Man-down
        if game?.didRecordEvent(INSOEventCodeManDown) {
            let homeManDown = eventCounter?.eventCount(forHomeTeam: INSOEventCodeManDown)
            let visitorManDown = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeManDown)

            if let homeManDown = homeManDown, let visitorManDown = visitorManDown {
                sectionData.append([
                    INSOHomeStatKey: homeManDown,
                    INSOStatNameKey: "Man-down",
                    INSOVisitorStatKey: visitorManDown
                ])
            }
        }

        // Man-down goals allowed
        // A man-down goal allowed is an extra-man goal scored by the other team.
        // Proceed accordingly.
        if game?.didRecordEvent(INSOEventCodeManDown) && game?.didRecordEvent(INSOEventCodeGoal) {
            let homeManDown = eventCounter?.eventCount(forHomeTeam: INSOEventCodeManDown).intValue ?? 0
            let visitorManDown = eventCounter?.eventCount(forVisitingTeam: INSOEventCodeManDown).intValue ?? 0

            let homeMDGoalsAllowed = eventCounter?.extraManGoalsForVisitingTeam().intValue ?? 0
            let visitorMDGoalsAllowed = eventCounter?.extraManGoalsForHomeTeam().intValue ?? 0


            let homeManDownScoring = (homeManDown > 0) ? CGFloat(homeMDGoalsAllowed) / CGFloat(homeManDown) : 0.0
            let visitorManDownScoring = (visitorManDown > 0) ? CGFloat(visitorMDGoalsAllowed) / CGFloat(visitorManDown) : 0.0

            // Man-down scoring = man-down goals allowed / man-down
            let homeManDownScoringString = percentFormatter?.string(from: NSNumber(value: Float(homeManDownScoring)))
            let visitorManDownScoringString = percentFormatter?.string(from: NSNumber(value: Float(visitorManDownScoring)))

            sectionData.append([
                INSOHomeStatKey: NSNumber(value: homeMDGoalsAllowed),
                INSOStatNameKey: "Man-down Goals Allowed",
                INSOVisitorStatKey: NSNumber(value: visitorMDGoalsAllowed)
            ])

            sectionData.append([
                INSOHomeStatKey: homeManDownScoringString ?? "",
                INSOStatNameKey: "Man-down Scoring",
                INSOVisitorStatKey: visitorManDownScoringString ?? ""
            ])
        }

        return extraManSection
    }

    func penaltyEvents() -> [AnyHashable : Any]? {
        var penaltySection: [AnyHashable : Any] = [:]

        // Section title depends on boys or girls
        let sectionTitle = NSLocalizedString("Penalties", comment: "")
        penaltySection[INSOSectionTitleKey] = NSLocalizedString(sectionTitle, comment: "")
        var sectionData: [AnyHashable] = []
        penaltySection[INSOSectionDataKey] = sectionData

        // Penalties
        let homePenalties = eventCounter?.totalPenaltiesForHomeTeam()
        let visitorPenalties = eventCounter?.totalPenaltiesForVisitingTeam()

        if let homePenalties = homePenalties, let visitorPenalties = visitorPenalties {
            sectionData.append([
                INSOHomeStatKey: homePenalties,
                INSOStatNameKey: "Penalties",
                INSOVisitorStatKey: visitorPenalties
            ])
        }

        // Penalty Time
        let homePenaltySeconds = eventCounter?.totalPenaltyTimeForHomeTeam().intValue ?? 0
        let visitorPenaltySeconds = eventCounter?.totalPenaltyTimeForVisitingTeam().intValue ?? 0

        let penaltyTimeFormatter = DateComponentsFormatter()
        penaltyTimeFormatter.zeroFormattingBehavior = .dropLeading
        penaltyTimeFormatter.allowedUnits = [.hour, .minute, .second]
        let homePenaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(homePenaltySeconds))
        let visitorPentaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(visitorPenaltySeconds))

        sectionData.append([
            INSOHomeStatKey: homePenaltyTimeString ?? "",
            INSOStatNameKey: "Penalty Time",
            INSOVisitorStatKey: visitorPentaltyTimeString ?? ""
        ])

        return penaltySection
    }
*/
    
    /* Commenting out entier player stats creation functions
    func statsDictionary(for rosterPlayer: RosterPlayer?) -> [AnyHashable : Any]? {
        var statsDictionary: [AnyHashable : Any] = [:]

        var sectionTitle: String? = nil
        if let number = rosterPlayer?.number {
            sectionTitle = "#\(number)"
        }
        statsDictionary[INSOSectionTitleKey] = sectionTitle

        // Now build the  stats array
        var statsArray: [AnyHashable] = []
        statsDictionary[INSOSectionDataKey] = statsArray

        var event: Event?
        var eventCount: NSNumber?
        var statTitle: String?
        var statValueString: String?

        // Groundballs
        event = Event(for: INSOEventCodeGroundball, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Shots
        event = Event(for: INSOEventCodeShot, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Goals
        event = Event(for: INSOEventCodeGoal, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Assists
        event = Event(for: INSOEventCodeAssist, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Shots on goal
        event = Event(for: INSOEventCodeShotOnGoal, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Saves
        event = Event(for: INSOEventCodeSave, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Goal allowed
        event = Event(for: INSOEventCodeGoalAllowed, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Won faceoff
        event = Event(for: INSOEventCodeFaceoffWon, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Lost faceoff
        event = Event(for: INSOEventCodeFaceoffLost, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Interceptions
        event = Event(for: INSOEventCodeInterception, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Takeaways
        event = Event(for: INSOEventCodeTakeaway, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Caused turnover
        event = Event(for: INSOEventCodeCausedTurnover, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // Unforced errors
        event = Event(for: INSOEventCodeUnforcedError, in: managedObjectContext)
        if let event = event {
            if game?.eventsToRecord.contains(event) ?? false {
                statTitle = event?.title
                eventCount = eventCounter?.eventCount(event?.eventCodeValue, for: rosterPlayer)
                statValueString = "\(eventCount ?? 0)"
                statsArray.append([
                    INSOStatNameKey: statTitle ?? "",
                    INSOHomeStatKey: statValueString ?? ""
                ])
            }
        }

        // And now penalties
        let predicate = NSPredicate(format: "statCategory == %@ OR statCategory == %@", NSNumber(value: INSOStatCategoryPenalty), NSNumber(value: INSOStatCategoryExpulsion))
        let penaltyEventSet = game?.eventsToRecord.filter { predicate.evaluate(with: $0) }

        // Just be done
        if (penaltyEventSet?.count ?? 0) > 0 {
            let totalPenalties = eventCounter?.totalPenalties(forBoysRosterPlayer: rosterPlayer)
            let totalPenaltyTime = eventCounter?.totalPenaltyTimeforRosterPlayer(rosterPlayer).doubleValue ?? 0.0

            let penaltyTimeFormatter = DateComponentsFormatter()
            penaltyTimeFormatter.zeroFormattingBehavior = .dropLeading
            penaltyTimeFormatter.allowedUnits = [.hour, .minute, .second]

            var penaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(totalPenaltyTime))
            if totalPenalties?.intValue ?? 0 == 0 {
                statTitle = NSLocalizedString("No penalties", comment: "")
                penaltyTimeString = ""
            } else if totalPenalties?.intValue ?? 0 == 1 {
                let localizedTitle = NSLocalizedString("%@ penalty", comment: "")
                statTitle = String(format: localizedTitle, totalPenalties ?? 0)
            } else {
                let localizedTitle = NSLocalizedString("%@ penalties", comment: "")
                statTitle = String(format: localizedTitle, totalPenalties ?? 0)
            }
            statsArray.append([
                INSOStatNameKey: statTitle ?? "",
                INSOHomeStatKey: penaltyTimeString ?? ""
            ])
        }

        return statsDictionary
    }
     */

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            return gameStats.sections.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            let currentSection = gameStats.sections[section]
            rowCount = currentSection.stats?.count ?? 0
        } else {
            rowCount = 0
        }

        return rowCount
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle: String = "Section Title"
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            let currentSection = gameStats.sections[section]
            sectionTitle = currentSection.title
        } else {
            sectionTitle = "Player Section Title"
        }

        return sectionTitle
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as? INSOGameStatTableViewCell
        cell?.statNameLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: INSOGameStatTableViewCell
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: INSOGameStatsCellIdentifier, for: indexPath) as! INSOGameStatTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: INSOPlayerStatsCellIdentifier, for: indexPath) as! INSOGameStatTableViewCell
        }

        configureGameStatCell(cell, at: indexPath)

        return cell
    }
}
