//  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
//
//  INSOEmailStatsViewController.swift
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

import MessageUI
import UIKit

class INSOEmailStatsViewController: UITableViewController, UITabBarDelegate, MFMailComposeViewControllerDelegate {
    var game: Game?
    
    private var maxPrepsAttachmentData: Data?
    private var playerStatsAttachmentData: Data?
    private var gameSummaryAttachmentData: Data?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.alwaysBounceVertical = false

        gameSummarySwitch.isOn = UserDefaults.standard.bool(forKey: INSOExportGameSummaryDefaultKey)
        playerStatsSwitch.isOn = UserDefaults.standard.bool(forKey: INSOExportPlayerStatsDefaultKey)
        maxPrepsSwitch.isOn = UserDefaults.standard.bool(forKey: INSOExportMaxPrepsDefaultKey)

        exportStatsButton.isEnabled = shouldEnableExportStatsButton()

        messageLabel.text = nil

        if !MFMailComposeViewController.canSendMail() {
            // Can't send email so disable UI and put up a message
            disableUI()
            activityIndicator.stopAnimating()
            messageLabel.text = "Unable to export stats via email. Check your mail settings and try again."
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - IBOutlets
    @IBOutlet private weak var gameSummarySwitch: UISwitch!
    @IBOutlet private weak var playerStatsSwitch: UISwitch!
    @IBOutlet private weak var maxPrepsSwitch: UISwitch!
    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var exportStatsButton: UIButton!
    
    // MARK: - IBActions

    @IBAction func done(_ sender: Any?) {
        // Just dismiss
        presentingViewController?.dismiss(animated: true)
    }

    @IBAction func toggledSwitch(_ sender: Any?) {
        exportStatsButton.isEnabled = shouldEnableExportStatsButton()

        UserDefaults.standard.set(gameSummarySwitch.isOn, forKey: INSOExportGameSummaryDefaultKey)
        UserDefaults.standard.set(playerStatsSwitch.isOn, forKey: INSOExportPlayerStatsDefaultKey)
        UserDefaults.standard.set(maxPrepsSwitch.isOn, forKey: INSOExportMaxPrepsDefaultKey)
    }

    @IBAction func exportStats(_ sender: Any?) {
        guard let game = game else {
            // Disable the UI and be done if we don't have a game object for some reason.
            disableUI()
            return
        }
        
        guard let fileGenerator = INSOEmailStatsFileGenerator(game: game) else {
            disableUI()
            return
        }
        
        // Freeze the UI
        disableUI()
        
        // Clear any old data files hanging around
        maxPrepsAttachmentData = nil
        gameSummaryAttachmentData = nil
        playerStatsAttachmentData = nil

        // Now generate the attachments. 
        if maxPrepsSwitch.isOn {
            fileGenerator.createMaxPrepsGameStatsData { self.maxPrepsAttachmentData = $0 }
        }

        if gameSummarySwitch.isOn {
            fileGenerator.createGameSummaryData { self.gameSummaryAttachmentData = $0 }
        }

        if playerStatsSwitch.isOn {
            fileGenerator.createPlayerStatsData { self.playerStatsAttachmentData = $0 }
        }

        // Send the email
        actuallySendEmail()
    }

    // MARK: - Private Methods
    func disableUI() {
        gameSummarySwitch.isEnabled = false
        playerStatsSwitch.isEnabled = false
        maxPrepsSwitch.isEnabled = false
        exportStatsButton.isEnabled = false
        activityIndicator.startAnimating()
    }

    func enableUI() {
        gameSummarySwitch.isEnabled = true
        playerStatsSwitch.isEnabled = true
        maxPrepsSwitch.isEnabled = true
        exportStatsButton.isEnabled = true
        activityIndicator.stopAnimating()
    }

    func shouldEnableExportStatsButton() -> Bool {
        return MFMailComposeViewController.canSendMail() && (gameSummarySwitch.isOn || playerStatsSwitch.isOn || maxPrepsSwitch.isOn)
    }

    func actuallySendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mailViewcontroller = MFMailComposeViewController()
            mailViewcontroller.mailComposeDelegate = self

            // Set subject and body
            mailViewcontroller.setSubject(mailMessageSubject())
            mailViewcontroller.setMessageBody(mailMessageBody(), isHTML: false)

            // Add attachment(s)
            if let maxPrepsAttachmentData = maxPrepsAttachmentData {
                let fileName = NSLocalizedString("MaxPreps Export.txt", comment: "")
                mailViewcontroller.addAttachmentData(maxPrepsAttachmentData, mimeType: "text/txt", fileName: fileName)
            }

            if let gameSummaryAttachmentData = gameSummaryAttachmentData {
                let fileName = NSLocalizedString("Game Summary.pdf", comment: "")
                mailViewcontroller.addAttachmentData(gameSummaryAttachmentData, mimeType: "application/pdf", fileName: fileName)
            }

            if let playerStatsAttachmentData = playerStatsAttachmentData {
                let fileName = NSLocalizedString("Player Stats.csv", comment: "")
                mailViewcontroller.addAttachmentData(playerStatsAttachmentData, mimeType: "text/csv", fileName: fileName)
            }

            if Target.isMens {
                mailViewcontroller.navigationBar.tintColor = UIColor.scorebookBlue()
            } else if Target.isWomens {
                mailViewcontroller.navigationBar.tintColor = UIColor.scorebookTeal()
            }

            // Display the view to mail the message.
            present(mailViewcontroller, animated: true) { [self] in
                // Re-enable the UI so that when the user dismisses the mail view,
                // the UI is ready to re-use.
                enableUI()
            }
        } else {
            // unable to send mail. Hmmm;
            print("Error - Unable to send email. Should never have gotten here.")
        }
    }

    func mailMessageSubject() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        var subject = ""
        guard let game = game else {
            return subject
        }

        subject = NSLocalizedString("Lacrosse Stats export for %@ vs. %@ on %@", comment: "")
        if let gameDateTime = game.gameDateTime, let visitingTeam = game.visitingTeam, let homeTeam = game.homeTeam {
            subject = String(format: subject, visitingTeam, homeTeam, dateFormatter.string(from: gameDateTime))
        }

        return subject
    }

    func mailMessageBody() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        var messageBody: String = ""
        guard let game = game else {
            return messageBody
        }
        messageBody = NSLocalizedString("Stats files for %@ vs. %@ on %@ at %@.\n\n", comment: "")
        
        if let gameDateTime = game.gameDateTime, let visitingTeam = game.visitingTeam, let homeTeam = game.homeTeam, let location = game.location {
            messageBody = String(format: messageBody, visitingTeam, homeTeam, dateFormatter.string(from: gameDateTime), location)
        }

        var fileCount = 0
        if gameSummarySwitch.isOn { fileCount += 1 }
        if playerStatsSwitch.isOn { fileCount += 1 }
        if maxPrepsSwitch.isOn { fileCount += 1 }

        if fileCount == 1 {
            messageBody += NSLocalizedString("The following file is attached:\n", comment: "")
        } else {
            messageBody += NSLocalizedString("The following files are attached:\n", comment: "")
        }

        if gameSummarySwitch.isOn {
            messageBody += NSLocalizedString("Game Summary", comment: "")
            messageBody += "\n"
        }

        if playerStatsSwitch.isOn {
            messageBody += NSLocalizedString("Individual player stats", comment: "")
            messageBody += "\n"
        }

        if maxPrepsSwitch.isOn {
            messageBody += NSLocalizedString("MaxPreps file", comment: "")
            messageBody += "\n"
        }

        return messageBody
    }

    // MARK: - MFMailComposeControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .sent:
            // It would be nice if I could play a sound here.
            messageLabel.text = NSLocalizedString("Email sent.", comment: "")
        case .saved:
            messageLabel.text = NSLocalizedString("Draft email saved.", comment: "")
        case .cancelled:
            messageLabel.text = NSLocalizedString("Email cancelled.", comment: "")
        case .failed:
            messageLabel.text = NSLocalizedString("An error occurred when trying to compose this email.", comment: "")
        default:
            messageLabel.text = nil
        }

        dismiss(animated: true)
    }
}
