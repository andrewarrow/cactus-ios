//
//  SettingsTableViewController.swift
//  Cactus
//
//  Created by Neil Poulin on 10/4/19.
//  Copyright © 2019 Cactus. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var emailAddressLabel: UILabel!
    
    var member: CactusMember?
    var footerView = UIView()
    var logoutButton = RoundedButton()
    let versionTitleLabel = UILabel()
    let versionTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureView()
    }

    func configureView() {
        //this clears the extra table view "cells" after the cells that are displayed.
        tableView.tableFooterView = UIView()
        
        //set up the table footer view with the logout button
        self.configureFooter()
    }
    
    func configureFooter() {
        let footerView = UIView(frame: CGRect(0, 0, 50, self.view.bounds.width));
        
        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.borderRadius = 18
        logoutButton.backgroundColor = .white
        logoutButton.titleLabel?.font = CactusFont.normalBold
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = CactusColor.darkGreen.cgColor
        logoutButton.setTitleColor(CactusColor.darkGreen, for: .normal)
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        footerView.addSubview(logoutButton)
        footerView.addSubview(versionTextView)
        footerView.addSubview(versionTitleLabel)
        
        logoutButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20).isActive = true
        logoutButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -20).isActive = true
        
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        versionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        versionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        versionTitleLabel.text = "Version"
        versionTextView.text = "Cactus \(appVersion ?? "") (\(buildVersion ?? "1"))"
        
        versionTextView.isScrollEnabled = false
        versionTextView.font = CactusFont.normal
        versionTextView.textColor = CactusColor.lightText
        versionTextView.textAlignment = .right
        versionTitleLabel.font = CactusFont.normal
        versionTitleLabel.textColor = CactusColor.lightText
        
        versionTitleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: versionTextView.leadingAnchor, constant: 20).isActive = true
        versionTitleLabel.centerYAnchor.constraint(equalTo: versionTextView.centerYAnchor).isActive = true
        
        versionTitleLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20).isActive = true
        versionTitleLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20).isActive = true
        versionTextView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -20).isActive = true
        logoutButton.topAnchor.constraint(equalTo: versionTitleLabel.bottomAnchor, constant: 40).isActive = true
        
        self.footerView = footerView
        
        logoutButton.addTarget(self, action: #selector(self.logOutTapped(_:)), for: .primaryActionTriggered)
        self.emailAddressLabel.text = member?.email
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        AuthService.sharedInstance.logOut(self)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        self.footerView.frame = CGRect(tableView.frame.minX, tableView.frame.maxY + 20, tableView.bounds.width , 100 )
//        self.footerView.backgroundColor = .red
        return self.footerView
    }
    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}