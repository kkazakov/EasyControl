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


extension Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}

class ViewController: UIViewController {
    
    @IBOutlet var btnSetIP: UIButton!
    @IBOutlet var btnOnOff: UIButton!
    
    @IBOutlet weak var lblPower: UILabel!
    
    static let defaults = UserDefaults.standard
    
    static let CONTROLLER_IP_VAR = "controller_ip"
    static let CONTROLLER_KEY_VAR = "controller_key"

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

        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.getControllerState), userInfo: nil, repeats: true)
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
    
    func updatePower(_ power: String?) {
        if power == nil {
            lblPower.text = "0 kW"
        } else {
            
            if var powerConsumption = Double(power!) {
                powerConsumption = powerConsumption / 1000
                powerConsumption = Double(round(1000 * powerConsumption)/1000)

                lblPower.text = "\(powerConsumption) kW"
            } else {
                lblPower.text = "0 kW"
            }
            
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
    
    func getPowerConsumption() {
        
        guard controllerIP != nil else {
            return
        }
        
        
        manager.request("http://" + controllerIP! + "/api/apparent?apikey=" + ViewController.getKey()!)
            //.debugLog()
            .responseString { response in
                
                if let data = response.data {
                    
                    
                    let str = String(data: data, encoding: .utf8)
                    
                    if (str != nil) {
                        
                        
                        
                        self.updatePower(str)
                    }
                    
                }
        }
    }
    
    func getControllerState() {
        
        guard controllerIP != nil else {
            return
        }
        
        updateInterface(.loading)
        
        manager.request("http://" + controllerIP! + "/api/relay/0?apikey=" + ViewController.getKey()!)
            //.debugLog()
            .responseString { response in

            if let data = response.data {
                
                
                let str = String(data: data, encoding: .utf8)

                if (str != nil) {
                    
                    if str == "1" {
                        self.updateInterface(.on)
                    } else if str == "0" {
                        self.updateInterface(.off)
                    } else {
                        self.updateInterface(.failed)
                    }
                    
                } else {
                    self.updateInterface(.failed)
                }

            } else {
                self.updateInterface(.failed)
            }
        }
        
        getPowerConsumption()
    }
    
    
    func turnOnOrOff(_ isOn: Bool) {
        
        updateInterface(.changing)

        let ev: String = isOn ? "1" : "0"
        
        //url +  "/api/" + target + "?" + getKey() + "&value=" + (turnOn ? "1" : "0")

        manager.request("http://" + controllerIP! + "/api/relay/0?apikey=" + ViewController.getKey()! + "&value=" + ev).responseString { response in
            
            print("Success: \(response.result.isSuccess)")
            
            if !response.result.isSuccess {
                self.updateInterface(.failed)
                return
            }
            
            if let val = response.result.value {
                if val == "0" || val == "1" {
                    self.updateInterface(val == "1" ? .on : .off)
                    
                    self.getPowerConsumption()

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
    
    
    static func getKey() -> String? {
        return defaults.string(forKey: CONTROLLER_KEY_VAR)
    }
    
    static func setKey(key: String?) {
        defaults.set(key, forKey: CONTROLLER_KEY_VAR)
    }

}

