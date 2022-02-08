//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  INSOGameTableViewController.swift
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import CoreData
import UIKit

private let INSOGameCellIdentifier = "GameCell"
private let INSOShowGameDetailSegueIdentifier = "ShowGameDetailSegue"
private let INSOShowPurchaseModalSegueIdentifier = "ShowPurchaseModalSegue"

class INSOGameTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    // Private Properties

    private lazy var gamesFRC: NSFetchedResultsController<Game> = {
        let request = NSFetchRequest<Game>(entityName: Game.entityName())
        request.fetchBatchSize = 50

        let sortByDate = NSSortDescriptor(key: "gameDateTime", ascending: false)
        request.sortDescriptors = [sortByDate]

        let gamesFRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        gamesFRC.delegate = self

        var error: Error? = nil
        do {
            try gamesFRC.performFetch()
        } catch {
            // Error fetching games
            print("Error fetching games: \(error.localizedDescription)")
        }

        return gamesFRC
    }()

    private var managedObjectContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - IBActions

    @IBAction func addGame(_ sender: Any?) {
        createNewGame()
    }

    // MARK: - Private Methods

    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.alwaysBounceVertical = false
        tableView.estimatedRowHeight = 189.0
    }

    private func configureGameCell(_ cell: INSOGameTableViewCell?, at indexPath: IndexPath?) {
        var game: Game? = nil
        if let indexPath = indexPath {
            game = gamesFRC.object(at: indexPath) as Game
        }

        let dateFormat = DateFormatter.dateFormat(fromTemplate: "Mdyy", options: 0, locale: NSLocale.current)
        let timeFormat = DateFormatter.dateFormat(fromTemplate: "hmma", options: 0, locale: NSLocale.current)
        let dateTimeFormat = "\(dateFormat ?? "")' at '\(timeFormat ?? "")"

        let formatter = DateFormatter()
        formatter.dateFormat = dateTimeFormat
        if let gameDateTime = game?.gameDateTime {
            cell?.gameDateTimeLabel.text = formatter.string(from: gameDateTime)
        }

        cell?.homeTeamLabel.text = game?.homeTeam
        if let homeScore = game?.homeScore {
            cell?.homeScoreLabel.text = "\(homeScore)"
        }

        cell?.visitingTeamLabel.text = game?.visitingTeam
        if let visitorScore = game?.visitorScore {
            cell?.visitingScoreLabel.text = "\(visitorScore)"
        }

        cell?.locationLabel.text = game?.location
    }

    func newGameStartDateTime() -> Date? {
        let currentDate = Date()
        var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: currentDate)
        var minutes = components.minute
        let minuteUnit = ceil(Float(minutes ?? 0) / 30.0)
        minutes = Int(minuteUnit * 30)
        components.minute = minutes
        return Calendar.current.date(from: components)
    }

    func createNewGame() {
        // Create a game with now as the game date time
        let newGame = Game.insert(in: managedObjectContext)
        newGame.gameDateTime = newGameStartDateTime()

        // Team to record
        newGame.teamWatching = newGame.homeTeam

        // Set up events to record
        let defaultEvents: [Event] = Event.fetchDefaultEvents(managedObjectContext) as! [Event]
        let eventSet: Set<Event> = Set(defaultEvents.map({ $0 }))
        newGame.addEvents(toRecord: eventSet)

        // Give the game 2 team players
        let teamPlayer = RosterPlayer.insert(in: managedObjectContext)
        teamPlayer.numberValue = Int16(INSOTeamWatchingPlayerNumber)
        teamPlayer.isTeamValue = true
        newGame.addPlayersObject(teamPlayer)

        let otherTeamPlayer = RosterPlayer.insert(in: managedObjectContext)
        otherTeamPlayer.numberValue = Int16(INSOOtherTeamPlayerNumber)
        otherTeamPlayer.isTeamValue = true
        newGame.addPlayersObject(otherTeamPlayer)

        var _: Error? = nil
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving MOC after creating new game: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If for some reason the sender is not our game table view cell, just don't do anything.
        guard let sender = sender as? INSOGameTableViewCell else {
            return
        }
        
        // Check the identifier, be safe.
        if segue.identifier == INSOShowGameDetailSegueIdentifier {
            prepare(forShowGameDetailSegue: segue, sender: sender)
        }
    }

    private func prepare(forShowGameDetailSegue segue: UIStoryboardSegue?, sender cell: INSOGameTableViewCell) {
        // If for some reason we don't have an index path, time to just bail.
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let selectedGame: Game? = gamesFRC.object(at: indexPath) as Game
        let dest = segue?.destination as? INSOGameDetailViewController
        dest?.game = selectedGame
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gamesFRC.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: INSOGameCellIdentifier, for: indexPath) as! INSOGameTableViewCell

        // Configure the cell...
        configureGameCell(cell, at: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let game = gamesFRC.object(at: indexPath) as Game? {
                managedObjectContext.delete(game)
            }
        }

        var _: Error? = nil
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving MOC after deleting game: \(error.localizedDescription)")
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 189.0
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath].compactMap { $0 }, with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath].compactMap { $0 }, with: .automatic)
        case .update:
            tableView.reloadRows(at: [indexPath].compactMap { $0 }, with: .none)
        case .move:
            tableView.reloadData()
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
