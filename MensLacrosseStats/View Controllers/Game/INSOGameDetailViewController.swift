//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  INSOGameDetailViewController.swift
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import UIKit

private var INSOEditGameSegueIdentifier = "EditGameSegue"
private var INSORecordStatsSegueIdentifier = "RecordStatsSegue"
private var INSOGameStatsSegueIdentifier = "GameStatsSegue"
private var INSOExportStatsSegueIdentifier = "ExportStatsSegue"

class INSOGameDetailViewController: UIViewController {
    // Public Properties
    var game: Game?

    // IBOutlets
    @IBOutlet private weak var gameDateTimeLabel: UILabel!
    @IBOutlet private weak var homeTeamLabel: UILabel!
    @IBOutlet private weak var homeScoreLabel: UILabel!
    @IBOutlet private weak var visitingTeamLabel: UILabel!
    @IBOutlet private weak var visitingScoreLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!

    // Private Properties
    private var managedObjectContext: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }
    private var teamWatchingGoals = 0
    private var otherTeamGoals = 0
   
    // IBActions
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving context after a game: \(error.localizedDescription)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - IBActions

    @IBAction func recordStats(_ sender: Any?) {
        performSegue(withIdentifier: INSORecordStatsSegueIdentifier, sender: self)
    }

    @IBAction func editGame(_ sender: Any?) {
        performSegue(withIdentifier: INSOEditGameSegueIdentifier, sender: self)
    }

    @IBAction func exportStats(_ sender: Any?) {
        performSegue(withIdentifier: INSOExportStatsSegueIdentifier, sender: self)
    }

    // MARK: - Private Methods

    func configureView() {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "Mdyy", options: 0, locale: NSLocale.current)
        let timeFormat = DateFormatter.dateFormat(fromTemplate: "hmma", options: 0, locale: NSLocale.current)
        let dateTimeFormat = "\(dateFormat ?? "")' at '\(timeFormat ?? "")"

        let formatter = DateFormatter()
        formatter.dateFormat = dateTimeFormat
        if let gameDateTime = game?.gameDateTime {
            gameDateTimeLabel.text = formatter.string(from: gameDateTime)
        }

        homeTeamLabel.text = game?.homeTeam
        visitingTeamLabel.text = game?.visitingTeam

        // Make sure the game object updates its own scores
        game?.updateScores()

        if let homeScore = game?.homeScore {
            homeScoreLabel.text = "\(homeScore)"
        }
        if let visitorScore = game?.visitorScore {
            visitingScoreLabel.text = "\(visitorScore)"
        }

        locationLabel.text = game?.location
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == INSOEditGameSegueIdentifier {
            prepare(forGameEdit: segue, sender: sender)
        }

        if segue.identifier == INSORecordStatsSegueIdentifier {
            prepare(forRecordStatsSegue: segue, sender: sender)
        }

        if segue.identifier == INSOGameStatsSegueIdentifier {
            prepare(forGameStatsSegue: segue, sender: sender)
        }

        if segue.identifier == INSOExportStatsSegueIdentifier {
            prepare(forExportStatsSegue: segue, sender: sender)
        }
    }

    func prepare(forGameEdit segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as? INSOGameEditViewController
        dest?.game = game
    }

    func prepare(forRecordStatsSegue segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as? INSORosterPlayerSelectorViewController
        dest?.game = game
    }

    func prepare(forGameStatsSegue segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? INSOGameStatsViewController {
            dest.game = game
        } else if let dest = segue.destination as? INSOWomensGameStatsViewController {
            dest.game = game
        }
    }

    func prepare(forExportStatsSegue segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as? UINavigationController
        let emailViewController = navigationController?.viewControllers.first as? INSOEmailStatsViewController
        emailViewController?.game = game
    }
}
