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

        let fieldingStats = fieldingEvents()
        let scoringStats = scoringEvents()
        let extraManStats = extraManEvents()

        return GameStats(sections: [fieldingStats, scoringStats, extraManStats, Target.isMens ? penaltyEvents() : foulEvents()])
    }

    private var playerStats: GameStats {
        guard let game = game else {
            return GameStats(sections: [Section(title: "No Player Stats", stats: nil)])
        }

        guard var gamePlayers = game.players?.sorted(by: { player1, player2 in
            player1.numberValue < player2.numberValue
        }) else {
            return GameStats(sections: [Section(title: "No Player Stats", stats: nil)])
        }

        gamePlayers.removeAll(where: { $0.numberValue < 0 })

        var tempPlayerStats: [Section] = []
        
        for rosterPlayer in gamePlayers {
            let playerStats = playerStats(for: rosterPlayer)
            tempPlayerStats.append(playerStats)
        }

        return GameStats(sections: tempPlayerStats)
    }

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
        if (playerStats.sections.count > 0) {
            statsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    // MARK: - Private Methods
    func configureGameStatCell(_ cell: INSOGameStatTableViewCell, at indexPath: IndexPath?) {
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
            cell.statNameLabel.text = eventStats.statName
            cell.homeStatLabel.text = eventStats.homeStat
            cell.visitorStatLabel.text = eventStats.visitorStat
        } else {
            guard let eventStats = playerStats.sections[section].stats?[row] else {
                return
            }
            cell.statNameLabel.text = eventStats.statName
            cell.homeStatLabel.text = eventStats.homeStat
        }

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
            let homeFaceoffsWon = eventCounter.eventCount(forHomeTeam: .codeFaceoffWon).intValue
            let homeFaceoffsLost = eventCounter.eventCount(forHomeTeam: .codeFaceoffLost).intValue
            let homeFaceoffs = homeFaceoffsWon + homeFaceoffsLost
            let homeFaceoffPct = (homeFaceoffsWon > 0) ? Float(homeFaceoffsWon) / Float(homeFaceoffs) : 0.0
            let homeFaceoffPctString = percentFormatter.string(from: NSNumber(value: homeFaceoffPct)) ?? "0%"
            
            let visitorFaceoffsWon = eventCounter.eventCount(forVisitingTeam: .codeFaceoffWon).intValue
            let visitorFaceoffsLost = eventCounter.eventCount(forVisitingTeam: .codeFaceoffLost).intValue
            let visitorFaceoffs = visitorFaceoffsWon + visitorFaceoffsLost
            let visitorFaceoffPct = (visitorFaceoffsWon > 0) ? Float(visitorFaceoffsWon) / Float(visitorFaceoffs) : 0.0
            let visitorFaceoffPctString = percentFormatter.string(from: NSNumber(value: visitorFaceoffPct)) ?? "0%"

            let homeStatString = "\(homeFaceoffsWon)/\(homeFaceoffs) \(homeFaceoffPctString)"
            let visitorStatString = "\(visitorFaceoffsWon)/\(visitorFaceoffs) \(visitorFaceoffPctString)"
            
            let faceoffStats = EventStats(statName: "Faceoffs", homeStat: homeStatString, visitorStat: visitorStatString)
            stats.append(faceoffStats)
        }

        // Draws - for Women's stats
        if game.didRecordEvent(.codeDrawTaken) && game.didRecordEvent(.codeDrawControl) {
            let homeDrawsTaken  = eventCounter.eventCount(forHomeTeam: .codeDrawTaken).intValue
            let homeDrawControl = eventCounter.eventCount(forHomeTeam: .codeDrawControl).intValue
            let homeDrawControlPct = (homeDrawsTaken > 0) ? Float(homeDrawControl) / Float(homeDrawsTaken) : 0.0
            let homeDrawControlPctString = percentFormatter.string(from: NSNumber(value: homeDrawControlPct)) ?? "0%"
            
            let visitorDrawsTaken = eventCounter.eventCount(forVisitingTeam: .codeDrawTaken).intValue
            let visitorDrawControl = eventCounter.eventCount(forVisitingTeam: .codeDrawControl).intValue
            let visitorDrawControlPct = (visitorDrawsTaken > 0) ? Float(visitorDrawControl) / Float(visitorDrawsTaken) : 0.0
            let visitorDrawControlPctString = percentFormatter.string(from: NSNumber(value: visitorDrawControlPct)) ?? "0%"

            let homeStatString = "\(homeDrawControl)/\(homeDrawsTaken) \(homeDrawControlPctString)"
            let visitorStatString = "\(visitorDrawControl)/\(visitorDrawsTaken) \(visitorDrawControlPctString)"
            
            let drawStats = EventStats(statName: "Draws", homeStat: homeStatString, visitorStat: visitorStatString)
            stats.append(drawStats)
        }

        // Clears
        if game.didRecordEvent(.codeClearSuccessful) && game.didRecordEvent(.codeClearFailed) {
            let homeClearSuccessful = eventCounter.eventCount(forHomeTeam: .codeClearSuccessful).intValue
            let homeClearFailed = eventCounter.eventCount(forHomeTeam: .codeClearFailed).intValue
            let homeClears = homeClearSuccessful + homeClearFailed
            let homeClearPct = (homeClears > 0) ? Float(homeClearSuccessful) / Float(homeClears) : 0.0
            let homeClearPctString = percentFormatter.string(from: NSNumber(value: homeClearPct)) ?? "0%"
            
            let visitorClearSuccessful = eventCounter.eventCount(forVisitingTeam: .codeClearSuccessful).intValue
            let visitorClearFailed = eventCounter.eventCount(forVisitingTeam: .codeClearFailed).intValue
            let visitorClears = visitorClearSuccessful + visitorClearFailed
            let visitorClearPct = (visitorClears > 0) ? Float(visitorClearSuccessful) / Float(visitorClears) : 0.0
            let visitorClearPctString = percentFormatter.string(from: NSNumber(value: visitorClearPct)) ?? "0%"

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
        if game.didRecordEvent(.codeTakeaway) {
            let homeTakeaways = eventCounter.eventCount(forHomeTeam: .codeTakeaway).intValue
            let visitorTakeaways = eventCounter.eventCount(forVisitingTeam: .codeTakeaway).intValue
            
            let takeawayStats = EventStats(statName: "Takeaways", homeStat: "\(homeTakeaways)", visitorStat: "\(visitorTakeaways)")
            stats.append(takeawayStats)
        }

        // Turnovers
        if game.didRecordEvent(.codeTurnover) {
            let homeTurnovers = eventCounter.eventCount(forHomeTeam: .codeTurnover).intValue
            let visitorTurnovers = eventCounter.eventCount(forVisitingTeam: .codeTurnover).intValue
            
            let turnoverStats = EventStats(statName: "Turnovers", homeStat: "\(homeTurnovers)", visitorStat: "\(visitorTurnovers)")
            stats.append(turnoverStats)
        }

        // Caused Turnovers
        if game.didRecordEvent(.codeCausedTurnover) {
            let homeCausedTurnovers = eventCounter.eventCount(forHomeTeam: .codeCausedTurnover).intValue
            let visitorCausedTurnovers = eventCounter.eventCount(forVisitingTeam: .codeCausedTurnover).intValue
            
            let causedTurnoverStats = EventStats(statName: "Caused Turnover", homeStat: "\(homeCausedTurnovers)", visitorStat: "\(visitorCausedTurnovers)")
            stats.append(causedTurnoverStats)
        }

        // Unforced Errors
        if game.didRecordEvent(.codeUnforcedError) {
            let homeUnforcedError = eventCounter.eventCount(forHomeTeam: .codeUnforcedError).intValue
            let visitorUnforcedError = eventCounter.eventCount(forVisitingTeam: .codeUnforcedError).intValue

            let unforcedErrorStats = EventStats(statName: "Unforced Errors", homeStat: "\(homeUnforcedError)", visitorStat: "\(visitorUnforcedError)")
            stats.append(unforcedErrorStats)
        }

        return Section(title: title, stats: stats)
    }
              
    func scoringEvents() -> Section {
        // Section title
        let title = NSLocalizedString("Scoring", comment: "")
        var stats: [EventStats] = []

        guard let game = game else {
            return Section(title: title, stats: stats)
        }
        
        // Shots
        if game.didRecordEvent(.codeShot) {
            let homeShots = eventCounter.eventCount(forHomeTeam: .codeShot).intValue
            let visitorShots = eventCounter.eventCount(forVisitingTeam: .codeShot).intValue
            
            let shotStats = EventStats(statName: "Shots", homeStat: "\(homeShots)", visitorStat: "\(visitorShots)")
            stats.append(shotStats)
        }

        // Goals
        if game.didRecordEvent(.codeGoal) {
            let homeGoals = eventCounter.eventCount(forHomeTeam: .codeGoal).intValue
            let visitorGoals = eventCounter.eventCount(forVisitingTeam: .codeGoal).intValue
            
            let goalStats = EventStats(statName: "Goals", homeStat: "\(homeGoals)", visitorStat: "\(visitorGoals)")
            stats.append(goalStats)
        }

        // Shooting pct. (Percent of shots that result in a goal)
        if game.didRecordEvent(.codeShot) && game.didRecordEvent(.codeGoal) {
            let homeShots = eventCounter.eventCount(forHomeTeam: .codeShot).intValue
            let homeGoals = eventCounter.eventCount(forHomeTeam: .codeGoal).intValue
            let homeShootingPct = (homeShots > 0) ? Float(homeGoals) / Float(homeShots) : 0.0
            let homeShootingPctString = percentFormatter.string(from: NSNumber(value: Float(homeShootingPct))) ?? "0%"

            let visitorShots = eventCounter.eventCount(forVisitingTeam: .codeShot).intValue
            let visitorGoals = eventCounter.eventCount(forVisitingTeam: .codeGoal).intValue
            let visitorShootingPct = (visitorShots > 0) ? Float(visitorGoals) / Float(visitorShots) : 0.0
            let visitorShootingPctString = percentFormatter.string(from: NSNumber(value: Float(visitorShootingPct))) ?? "0%"

            let shootingPctStats = EventStats(statName: "Shooting Percent\n(Goals / Shots)", homeStat: homeShootingPctString, visitorStat: visitorShootingPctString)
            stats.append(shootingPctStats)
        }

        // Shots on goal
        if game.didRecordEvent(.codeShotOnGoal) {
            let homeSOG = eventCounter.eventCount(forHomeTeam: .codeShotOnGoal).intValue
            let visitorSOG = eventCounter.eventCount(forVisitingTeam: .codeShotOnGoal).intValue
            
            let shotOnGoalStats = EventStats(statName: "Shots on Goal", homeStat: "\(homeSOG)", visitorStat: "\(visitorSOG)")
            stats.append(shotOnGoalStats)
        }

        // Misses = shots - shots on goal;
        if game.didRecordEvent(.codeShot) && game.didRecordEvent(.codeShotOnGoal) {
            let homeShots = eventCounter.eventCount(forHomeTeam: .codeShot).intValue
            let homeSOG = eventCounter.eventCount(forHomeTeam: .codeShotOnGoal).intValue
            var homeMisses = homeShots - homeSOG
            homeMisses = homeMisses < 0 ? 0 : homeMisses

            let visitorShots = eventCounter.eventCount(forVisitingTeam: .codeShot).intValue
            let visitorSOG = eventCounter.eventCount(forVisitingTeam: .codeShotOnGoal).intValue
            var visitorMisses = visitorShots - visitorSOG
            visitorMisses = visitorMisses < 0 ? 0 : visitorMisses
            
            let missesStats = EventStats(statName: "Misses", homeStat: "\(homeMisses)", visitorStat: "\(visitorMisses)")
            stats.append(missesStats)
        }

        // Shooting accuracy = shots on goal / shots (what percent of your shots were on goal)
        if game.didRecordEvent(.codeShot) && game.didRecordEvent(.codeShotOnGoal) {
            let homeShots = eventCounter.eventCount(forHomeTeam: .codeShot).intValue
            let homeSOG = eventCounter.eventCount(forHomeTeam: .codeShotOnGoal).intValue
            let homeAccuracy = (homeShots > 0) ? Float(homeSOG) / Float(homeShots) : 0.0
            let homeAccuracyString = percentFormatter.string(from: NSNumber(value: homeAccuracy)) ?? "0%"

            let visitorShots = eventCounter.eventCount(forVisitingTeam: .codeShot).intValue
            let visitorSOG = eventCounter.eventCount(forVisitingTeam: .codeShotOnGoal).intValue
            let visitorAccuracy = (visitorShots > 0) ? Float(visitorSOG) / Float(visitorShots) : 0.0
            let visitorAccuracyString = percentFormatter.string(from: NSNumber(value: visitorAccuracy)) ?? "0%"
            
            let accuracyStats = EventStats(statName: "Shooting Accuracy\n(Shots on Goal / Shots)", homeStat: homeAccuracyString, visitorStat: visitorAccuracyString)
            stats.append(accuracyStats)
        }

        // Assists
        if game.didRecordEvent(.codeAssist) {
            let homeAssists = eventCounter.eventCount(forHomeTeam: .codeAssist).intValue
            let visitorAssists = eventCounter.eventCount(forVisitingTeam: .codeAssist).intValue
            
            let assistStats = EventStats(statName: "Assists", homeStat: "\(homeAssists)", visitorStat: "\(visitorAssists)")
            stats.append(assistStats)
        }

        // Saves
        if game.didRecordEvent(.codeSave) {
            let homeSaves = eventCounter.eventCount(forHomeTeam: .codeSave).intValue
            let visitorSaves = eventCounter.eventCount(forVisitingTeam: .codeSave).intValue
            
            let saveStats = EventStats(statName: "Saves", homeStat: "\(homeSaves)", visitorStat: "\(visitorSaves)")
            stats.append(saveStats)
        }

        // Goals allowed
        if game.didRecordEvent(.codeGoalAllowed) {
            let homeGoalsAllowed = eventCounter.eventCount(forHomeTeam: .codeGoalAllowed).intValue
            let visitorGoalsAllowed = eventCounter.eventCount(forVisitingTeam: .codeGoalAllowed).intValue
            
            let goalsAllowedStats = EventStats(statName: "Goals Allowed", homeStat: "\(homeGoalsAllowed)", visitorStat: "\(visitorGoalsAllowed)")
            stats.append(goalsAllowedStats)
        }

        // Save pct. = saves / (saves + goals allowed)
        if game.didRecordEvent(.codeSave) && game.didRecordEvent(.codeGoalAllowed) {
            let homeSaves = eventCounter.eventCount(forHomeTeam: .codeSave).intValue
            let homeGoalsAllowed = eventCounter.eventCount(forHomeTeam: .codeGoalAllowed).intValue
            let homeSavePct = (homeSaves + homeGoalsAllowed) > 0 ? Float(homeSaves) / Float((homeSaves + homeGoalsAllowed)) : 0.0
            let homeSavePctString = percentFormatter.string(from: NSNumber(value: homeSavePct)) ?? "0%"

            let visitorSaves = eventCounter.eventCount(forVisitingTeam: .codeSave).intValue
            let visitorGoalsAllowed = eventCounter.eventCount(forVisitingTeam: .codeGoalAllowed).intValue
            let visitorSavePct = (visitorSaves + visitorGoalsAllowed) > 0 ? Float(visitorSaves) / Float((visitorSaves + visitorGoalsAllowed)) : 0.0
            let visitorSavePctString = percentFormatter.string(from: NSNumber(value: visitorSavePct)) ?? "0%"

            let savePctStats = EventStats(statName: "Save Percent", homeStat: homeSavePctString, visitorStat: visitorSavePctString)
            stats.append(savePctStats)
        }

        return Section(title: title, stats: stats)
    }
    
    func extraManEvents() -> Section {
        // Section title
        var title = ""
        
        // Need different titles based on build target Mens vs Womens
        if Target.isMens {
            title = NSLocalizedString("Extra-Man", comment: "")
        } else if Target.isWomens {
            title = NSLocalizedString("Man-Up", comment: "")
        }
        var stats: [EventStats] = []

        guard let game = game else {
            return Section(title: title, stats: stats)
        }
        
        // EMO
        if game.didRecordEvent(.codeEMO) {
            let homeEMO = eventCounter.eventCount(forHomeTeam: .codeEMO).intValue
            let visitorEMO = eventCounter.eventCount(forVisitingTeam: .codeEMO).intValue
            
            let emoStats = EventStats(statName: "Extra-man Opportunities", homeStat: "\(homeEMO)", visitorStat: "\(visitorEMO)")
            stats.append(emoStats)
        }
        
        // Man-up
        if game.didRecordEvent(.codeManUp) {
            let homeManUp = eventCounter.eventCount(forHomeTeam: .codeManUp).intValue
            let visitorManUp = eventCounter.eventCount(forVisitingTeam: .codeManUp).intValue
            
            let manUpStats = EventStats(statName: "Man-Up", homeStat: "\(homeManUp)", visitorStat: "\(visitorManUp)")
            stats.append(manUpStats)
        }

        // EMO goals
        if game.didRecordEvent(.codeEMO) && game.didRecordEvent(.codeGoal) {
            let homeEMOGoals = eventCounter.extraManGoalsForHomeTeam().intValue
            let visitorEMOGoals = eventCounter.extraManGoalsForVisitingTeam().intValue
            
            let emoGoalStats = EventStats(statName: "Extra-man Goals", homeStat: "\(homeEMOGoals)", visitorStat: "\(visitorEMOGoals)")
            stats.append(emoGoalStats)

            // Just do the emo scoring here while we're at it.
            // EMO scoring = emo goals / emo
            let homeEMO = eventCounter.eventCount(forHomeTeam: .codeEMO).intValue
            let visitorEMO = eventCounter.eventCount(forVisitingTeam: .codeEMO).intValue

            let homeEMOScoring = (homeEMO > 0) ? Float(homeEMOGoals) / Float(homeEMO) : 0.0
            let homeEMOScoringString = percentFormatter.string(from: NSNumber(value: homeEMOScoring)) ?? "0%"
            let visitorEMOScoring = (visitorEMO > 0) ? Float(visitorEMOGoals) / Float(visitorEMO) : 0.0
            let visitorEMOScoringString = percentFormatter.string(from: NSNumber(value: visitorEMOScoring)) ?? "0%"
            
            let emoScoringStats = EventStats(statName: "Extra-man Scoring", homeStat: homeEMOScoringString, visitorStat: visitorEMOScoringString)
            stats.append(emoScoringStats)
        }
        
        // Man-up Scoring
        if game.didRecordEvent(.codeManUp) && game.didRecordEvent(.codeGoal) {
            let homeManUpGoals = eventCounter.extraManGoalsForHomeTeam().intValue
            let visitorManUpGoals = eventCounter.extraManGoalsForVisitingTeam().intValue
            
            let manUpGoalStats = EventStats(statName: "Man-up Goals", homeStat: "\(homeManUpGoals)", visitorStat: "\(visitorManUpGoals)")
            stats.append(manUpGoalStats)

            // Just do the emo scoring here while we're at it.
            // EMO scoring = emo goals / emo
            let homeManUp = eventCounter.eventCount(forHomeTeam: .codeManUp).intValue
            let visitorManUp = eventCounter.eventCount(forVisitingTeam: .codeManUp).intValue

            let homeManUpScoring = (homeManUp > 0) ? Float(homeManUpGoals) / Float(homeManUp) : 0.0
            let homeManUpScoringString = percentFormatter.string(from: NSNumber(value: homeManUpScoring)) ?? "0%"
            let visitorManUpScoring = (visitorManUp > 0) ? Float(visitorManUpGoals) / Float(visitorManUp) : 0.0
            let visitorManUpScoringString = percentFormatter.string(from: NSNumber(value: visitorManUpScoring)) ?? "0%"
            
            let manUpScoringStats = EventStats(statName: "Man-up Scoring", homeStat: homeManUpScoringString, visitorStat: visitorManUpScoringString)
            stats.append(manUpScoringStats)
        }

        // Man-down
        if game.didRecordEvent(.codeManDown) {
            let homeManDown = eventCounter.eventCount(forHomeTeam: .codeManDown).intValue
            let visitorManDown = eventCounter.eventCount(forVisitingTeam: .codeManDown).intValue
            
            let manDownStats = EventStats(statName: "Man-down", homeStat: "\(homeManDown)", visitorStat: "\(visitorManDown)")
            stats.append(manDownStats)
        }

        // Man-down goals allowed
        // A man-down goal allowed is an extra-man goal scored by the other team.
        // Proceed accordingly.
        if game.didRecordEvent(.codeManDown) && game.didRecordEvent(.codeGoal) {
            let homeManDown = eventCounter.eventCount(forHomeTeam: .codeManDown).intValue
            let visitorManDown = eventCounter.eventCount(forVisitingTeam: .codeManDown).intValue

            let homeMDGoalsAllowed = eventCounter.extraManGoalsForVisitingTeam().intValue
            let visitorMDGoalsAllowed = eventCounter.extraManGoalsForHomeTeam().intValue

            let homeManDownScoring = (homeManDown > 0) ? Float(homeMDGoalsAllowed) / Float(homeManDown) : 0.0
            let visitorManDownScoring = (visitorManDown > 0) ? Float(visitorMDGoalsAllowed) / Float(visitorManDown) : 0.0

            // Man-down scoring = man-down goals allowed / man-down
            let homeManDownScoringString = percentFormatter.string(from: NSNumber(value: homeManDownScoring)) ?? "0%"
            let visitorManDownScoringString = percentFormatter.string(from: NSNumber(value: visitorManDownScoring)) ?? "0%"
            
            let mdGoalsAllowedStats = EventStats(statName: "Man-down Goals Allowed", homeStat: "\(homeMDGoalsAllowed)", visitorStat: "\(visitorMDGoalsAllowed)")
            stats.append(mdGoalsAllowedStats)

            let mdScoringStats = EventStats(statName: "Man-down Scoring", homeStat: homeManDownScoringString, visitorStat: visitorManDownScoringString)
            stats.append(mdScoringStats)
        }

        return Section(title: title, stats: stats)
    }

    // Penalties only for men's
    func penaltyEvents() -> Section {
        let title = "Penalties"
        var stats: [EventStats] = []
        
        // Penalties
        let homePenalties = eventCounter.totalPenaltiesForHomeTeam().intValue
        let visitorPenalties = eventCounter.totalPenaltiesForVisitingTeam().intValue
        
        let penaltyStats = EventStats(statName: "Penalties", homeStat: "\(homePenalties)", visitorStat:"\(visitorPenalties)")
        stats.append(penaltyStats)

        // Penalty Time
        let homePenaltySeconds = eventCounter.totalPenaltyTimeForHomeTeam().intValue
        let visitorPenaltySeconds = eventCounter.totalPenaltyTimeForVisitingTeam().intValue

        let penaltyTimeFormatter = DateComponentsFormatter()
        penaltyTimeFormatter.zeroFormattingBehavior = .dropLeading
        penaltyTimeFormatter.allowedUnits = [.hour, .minute, .second]
        let homePenaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(homePenaltySeconds)) ?? ""
        let visitorPentaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(visitorPenaltySeconds)) ?? ""
        
        let penaltyTimeStats = EventStats(statName: "Penalty Time", homeStat: homePenaltyTimeString, visitorStat: visitorPentaltyTimeString)
        stats.append(penaltyTimeStats)

        return Section(title: title, stats: stats)
    }
    
    // Fouls for women's
    func foulEvents() -> Section {
        let title = "Fouls"
        var stats: [EventStats] = []
        
        guard let game = game else {
            return Section(title: title, stats: stats)
        }
        
        // Fouls
        if game.didRecordEvent(.codeMinorFoul) || game.didRecordEvent(.codeMajorFoul) {
            let homeFouls = eventCounter.totalFoulsForHomeTeam().intValue
            let visitorFouls = eventCounter.totalFoulsForVisitingTeam().intValue
            
            let foulStats = EventStats(statName: "Fouls", homeStat: "\(homeFouls)", visitorStat: "\(visitorFouls)")
            stats.append(foulStats)
        }
        
        // 8-meter awarded
        if game.didRecordEvent(.code8mFreePosition) {
            let home8m = eventCounter.eventCount(forHomeTeam: .code8mFreePosition).intValue
            let visitor8m = eventCounter.eventCount(forVisitingTeam: .code8mFreePosition).intValue
            
            let freePositionStats = EventStats(statName: "8m (Free Position)", homeStat: "\(home8m)", visitorStat: "\(visitor8m)")
            stats.append(freePositionStats)
        }
        
        // 8-meter shots & goals
        if game.didRecordEvent(.codeShot) && game.didRecordEvent(.codeShotOnGoal) && game.didRecordEvent(.codeGoal) {
            let homeFPS = eventCounter.freePositionEventCount(forHomeTeam: .codeShot).intValue
            let visitorFPS = eventCounter.freePositionEventCount(forVisitingTeam: .codeShot).intValue
            
            let homeFPSOG = eventCounter.freePositionEventCount(forHomeTeam: .codeShotOnGoal).intValue
            let visitorFPSOG = eventCounter.freePositionEventCount(forVisitingTeam: .codeShotOnGoal).intValue
            
            let homeFPGoal = eventCounter.freePositionEventCount(forHomeTeam: .codeGoal).intValue
            let visitorFPGoal = eventCounter.freePositionEventCount(forVisitingTeam: .codeGoal).intValue
            
            let homeStatString = "\(homeFPS)/\(homeFPSOG)/\(homeFPGoal)"
            let visitorStatString = "\(visitorFPS)/\(visitorFPSOG)/\(visitorFPGoal)"
            
            let freePositionStats = EventStats(statName: "8m (Free Position)\nShots/SOG/Goals", homeStat: homeStatString, visitorStat: visitorStatString)
            stats.append(freePositionStats)
        }
        
        // Green cards
        if game.didRecordEvent(.codeGreenCard) {
            let homeGreenCards = eventCounter.eventCount(forHomeTeam: .codeGreenCard).intValue
            let visitorGreenCards = eventCounter.eventCount(forVisitingTeam: .codeGreenCard).intValue
            
            let greenCardStats = EventStats(statName: "Green Cards", homeStat: "\(homeGreenCards)", visitorStat: "\(visitorGreenCards)")
            stats.append(greenCardStats)
        }
        
        // Yellow cards
        if game.didRecordEvent(.codeYellowCard) {
            let homeYellowCards = eventCounter.eventCount(forHomeTeam: .codeYellowCard).intValue
            let visitorYellowCards = eventCounter.eventCount(forVisitingTeam: .codeYellowCard).intValue
            
            let yellowCardStats = EventStats(statName: "Yellow Cards", homeStat: "\(homeYellowCards)", visitorStat: "\(visitorYellowCards)")
            stats.append(yellowCardStats)
        }

        // Red cards
        if game.didRecordEvent(.codeRedCard) {
            let homeRedCards = eventCounter.eventCount(forHomeTeam: .codeRedCard).intValue
            let visitorRedCards = eventCounter.eventCount(forVisitingTeam: .codeRedCard).intValue
            
            let redCardStats = EventStats(statName: "Red Cards", homeStat: "\(homeRedCards)", visitorStat: "\(visitorRedCards)")
            stats.append(redCardStats)
        }

        return Section(title: title, stats: stats)
    }
    
    func playerStats(for rosterPlayer: RosterPlayer) -> Section {

        let playerTitle = "#\(rosterPlayer.numberValue)"

        // Now build the  stats array
        var stats: [EventStats] = []

        var statTitle: String = ""
        var statCount: Int = 0

        guard let game = game else {
            return Section(title: playerTitle, stats: stats)
        }

        // Groundballs
        if game.didRecordEvent(.codeGroundball) {
            statTitle = "Groundballs"
            statCount = eventCounter.eventCount(.codeGroundball, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }
        
        // Shots
        if game.didRecordEvent(.codeShot) {
            statTitle = "Shots"
            statCount = eventCounter.eventCount(.codeShot, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Goals
        if game.didRecordEvent(.codeGoal) {
            statTitle = "Goals"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Assists
        if game.didRecordEvent(.codeAssist) {
            statTitle = "Assists"
            statCount = eventCounter.eventCount(.codeAssist, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Shots on goal
        if game.didRecordEvent(.codeShotOnGoal) {
            statTitle = "Shots on Goal"
            statCount = eventCounter.eventCount(.codeShotOnGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Saves
        if game.didRecordEvent(.codeSave) {
            statTitle = "Saves"
            statCount = eventCounter.eventCount(.codeSave, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Goal allowed
        if game.didRecordEvent(.codeGoalAllowed) {
            statTitle = "Goals Allowed"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Won faceoff
        if game.didRecordEvent(.codeFaceoffWon) {
            statTitle = "Faceoffs Won"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Lost faceoff
        if game.didRecordEvent(.codeFaceoffLost) {
            statTitle = "Faceoffs Lost"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Draws taken
        if game.didRecordEvent(.codeDrawTaken) {
            statTitle = "Draws Taken"
            statCount = eventCounter.eventCount(.codeDrawTaken, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat:"\(statCount)", visitorStat: ""))
        }
        
        // Draw control
        if game.didRecordEvent(.codeDrawControl) {
            statTitle = "Draw Control"
            statCount = eventCounter.eventCount(.codeDrawControl, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat:"\(statCount)", visitorStat: ""))
        }
        
        // Draw possessions
        if game.didRecordEvent(.codeDrawPossession) {
            statTitle = "Draw Possession"
            statCount = eventCounter.eventCount(.codeDrawPossession, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Interceptions
        if game.didRecordEvent(.codeInterception) {
            statTitle = "Interceptions"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Takeaways
        if game.didRecordEvent(.codeTakeaway) {
            statTitle = "Takeaways"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Caused turnover
        if game.didRecordEvent(.codeCausedTurnover) {
            statTitle = "Caused Turnovers"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // Unforced errors
        if game.didRecordEvent(.codeUnforcedError) {
            statTitle = "Unforced Errors"
            statCount = eventCounter.eventCount(.codeGoal, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }
        
        // 8M fp
        if game.didRecordEvent(.code8mFreePosition) {
            statTitle = "8m Free Position"
            statCount = eventCounter.eventCount(.code8mFreePosition, for: rosterPlayer).intValue
            stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
        }

        // And now penalties if we're doing mens
        if Target.isMens {
            let totalPenalties = eventCounter.totalPenalties(forBoysRosterPlayer: rosterPlayer).intValue
            let totalPenaltyTime = eventCounter.totalPenaltyTimeforRosterPlayer(rosterPlayer).doubleValue

            let penaltyTimeFormatter = DateComponentsFormatter()
            penaltyTimeFormatter.zeroFormattingBehavior = .dropLeading
            penaltyTimeFormatter.allowedUnits = [.hour, .minute, .second]

            var penaltyTimeString = penaltyTimeFormatter.string(from: TimeInterval(totalPenaltyTime)) ?? ""
            
            if totalPenalties == 0 {
                statTitle = NSLocalizedString("No penalties", comment: "")
                penaltyTimeString = ""
            } else if totalPenalties == 1 {
                statTitle = NSLocalizedString("\(totalPenalties) penalty", comment: "")
            } else {
                statTitle = NSLocalizedString("\(totalPenalties) penalties", comment: "")
            }
            
            stats.append(EventStats(statName: statTitle, homeStat: penaltyTimeString, visitorStat: ""))
        }
        
        // Instead do fouls if we're doing women's
        if Target.isWomens {
            // Fouls
            if game.didRecordEvent(.codeMajorFoul) {
                statTitle = "Major Foul"
                statCount = eventCounter.eventCount(.codeMajorFoul, for: rosterPlayer).intValue
                stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
            }

            if game.didRecordEvent(.codeMinorFoul) {
                statTitle = "Minor Foul"
                statCount = eventCounter.eventCount(.codeMinorFoul, for: rosterPlayer).intValue
                stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
            }
            
            // Green cards
            if game.didRecordEvent(.codeGreenCard) {
                statTitle = "Green Card"
                statCount = eventCounter.eventCount(.codeGreenCard, for: rosterPlayer).intValue
                stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
            }
            
            // Yellow cards
            if game.didRecordEvent(.codeYellowCard) {
                statTitle = "Yellow Card"
                statCount = eventCounter.eventCount(.codeYellowCard, for: rosterPlayer).intValue
                stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
            }
            
            // Red cards
            if game.didRecordEvent(.codeRedCard) {
                statTitle = "Red Card"
                statCount = eventCounter.eventCount(.codeRedCard, for: rosterPlayer).intValue
                stats.append(EventStats(statName: statTitle, homeStat: "\(statCount)", visitorStat: ""))
            }
        }
        
        return Section(title: playerTitle, stats: stats)
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            return gameStats.sections.count
        } else {
            return playerStats.sections.count
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            let currentSection = gameStats.sections[section]
            rowCount = currentSection.stats?.count ?? 0
        } else {
            let currentSection = playerStats.sections[section]
            rowCount = currentSection.stats?.count ?? 0
        }

        return rowCount
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle: String = "Section Title"
        if statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndex.game.rawValue {
            let currentSection = gameStats.sections[section]
            sectionTitle = currentSection.title
        } else {
            let currentSection = playerStats.sections[section]
            sectionTitle = currentSection.title
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
