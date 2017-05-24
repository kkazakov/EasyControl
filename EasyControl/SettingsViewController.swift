//
//  SettingsViewController.swift
//  EasyControl
//
//  Created by Krasimir Kazakov on 5/24/17.
//  Copyright © 2017 Krasimir Kazakov. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet var btnSave: UIButton!
    @IBOutlet var btnCancel: UIButton!
    @IBOutlet var txtIP: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Settings"

        txtIP.text = ViewController.getIPAddress()
    }

    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func save() {
        ViewController.setIPAddress(ip: txtIP.text)
        navigationController?.popViewController(animated: true)
    }

}
