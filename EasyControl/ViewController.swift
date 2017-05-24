//
//  ViewController.swift
//  EasyControl
//
//  Created by Krasimir Kazakov on 5/24/17.
//  Copyright © 2017 Krasimir Kazakov. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire


class ViewController: UIViewController {
    
    @IBOutlet var btnSetIP: UIButton!
    @IBOutlet var btnOnOff: UIButton!
    
    static let defaults = UserDefaults.standard
    
    static let CONTROLLER_IP_VAR = "controller_ip"
    
    var controllerIP: String?
    
    let unknownStateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.2)
    let loadingStateColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.9)
    let failedStateColor = UIColor(red: 1, green: 0.1, blue: 0.1, alpha: 1)
    let onStateColor = UIColor(red: 0, green: 0.7, blue: 0, alpha: 1)
    let offStateColor = UIColor.red

    let manager = Alamofire.SessionManager.default

    enum State {
        case unknown
        case loading
        case failed
        case on
        case off
        case changing
    }
    
    var state: State = .unknown
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager.session.configuration.timeoutIntervalForRequest = 10
        
        btnOnOff.layer.cornerRadius = 4
        btnOnOff.layer.borderColor = unknownStateColor.cgColor
        btnOnOff.layer.borderWidth = 1
        btnOnOff.setTitleColor(unknownStateColor, for: .normal)

        //btnSetIP.layer.cornerRadius = 4
        //btnSetIP.layer.borderColor = loadingStateColor.cgColor
        //btnSetIP.layer.borderWidth = 1
        btnSetIP.setTitleColor(loadingStateColor, for: .normal)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        controllerIP = ViewController.getIPAddress()
        
        updateInterface(.unknown)

        if controllerIP == nil {
            openSettings()
        } else {
            getControllerState()
        }
        
    }
    
    func updateInterface(_ newState: State?) {
        
        if (newState != nil) {
            state = newState!
        }
        
        switch state {
            
        case .unknown:
            btnOnOff.layer.borderColor = unknownStateColor.cgColor
            btnOnOff.setTitleColor(unknownStateColor, for: .normal)
            btnOnOff.setTitle("-", for: .normal)
            break
            
        case .loading:
            btnOnOff.layer.borderColor = loadingStateColor.cgColor
            btnOnOff.setTitleColor(loadingStateColor, for: .normal)
            btnOnOff.setTitle("Свързване...", for: .normal)
            break
            
        case .failed:
            btnOnOff.layer.borderColor = failedStateColor.cgColor
            btnOnOff.setTitleColor(failedStateColor, for: .normal)
            btnOnOff.setTitle("Грешка", for: .normal)
            break
            
        case .on:
            btnOnOff.layer.borderColor = onStateColor.cgColor
            btnOnOff.setTitleColor(onStateColor, for: .normal)
            btnOnOff.setTitle("Включен", for: .normal)
            break
            
        case .off:
            btnOnOff.layer.borderColor = offStateColor.cgColor
            btnOnOff.setTitleColor(offStateColor, for: .normal)
            btnOnOff.setTitle("Изключен", for: .normal)
            break
            
        case .changing:
            btnOnOff.layer.borderColor = loadingStateColor.cgColor
            btnOnOff.setTitleColor(loadingStateColor, for: .normal)
            break
        }
        
    }
    
    
    func getControllerState() {
        
        guard controllerIP != nil else {
            return
        }
        
        updateInterface(.loading)
        
        manager.request("http://" + controllerIP! + "/control?cmd=status,gpio,12").responseJSON { response in
            print(response.request ?? "")  // original URL request
            print(response.response ?? "") // HTTP URL response
            print(response.data ?? "")     // server data
            print(response.result)   // result of response serialization

            if let data = response.data {
                
                let json = JSON(data: data)
                
                //print("JSON: \(json)")
                
                //let str = String(data: json, encoding: .utf8)
                
                if json["state"] != JSON.null {
                    
                    if json["state"] == 1 {
                        self.updateInterface(.on)
                    } else {
                        self.updateInterface(.off)
                    }
                    
                } else {
                    self.updateInterface(.failed)
                }
            } else {
                self.updateInterface(.failed)
            }
        }
    }
    
    
    func turnOnOrOff(_ isOn: Bool) {
        
        updateInterface(.changing)

        let ev: String = isOn ? "TurnOn" : "TurnOff"

        Alamofire.request("http://" + controllerIP! + "/control?cmd=event," + ev).responseString { response in
            
            print("Success: \(response.result.isSuccess)")
            
            if !response.result.isSuccess {
                self.updateInterface(.failed)
                return
            }
            
            if let val = response.result.value {
                if val == "OK" {
                    self.updateInterface(isOn ? .on : .off)
                } else {
                    self.updateInterface(.failed)
                }
            } else {
                self.updateInterface(.failed)
            }
        }
    }
    
    
    @IBAction func openSettings() {
        performSegue(withIdentifier: "config", sender: nil)
    }

    @IBAction func toggleOnOff() {
        
        
        if state == .loading {
            updateInterface(.unknown)
            return
        } else if state == .unknown || state == .failed {
            getControllerState()
            return
        } else if state == .on {
            turnOnOrOff(false)
        } else if state == .off {
            turnOnOrOff(true)
        }
        
    }
    
    static func getIPAddress() -> String? {
        return defaults.string(forKey: CONTROLLER_IP_VAR)
    }
    
    static func setIPAddress(ip: String?) {
        defaults.set(ip, forKey: CONTROLLER_IP_VAR)
    }

}

