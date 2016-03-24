//
//  MagnetometerController.swift
//  nervousnet-iOS
//  
//  Created by __DEVNAME__ on 03 Mar 2016.
//  Copyright (c) 2016 ETHZ . All rights reserved.
//
//WARNING - THIS CODE IS AUTOGENERATED BY DEVSKETCH AND CAN BE OVERWRITTEN


import Foundation
import CoreMotion

class MagnetometerController : NSObject, SensorProtocol {
    
    private var auth: Int = 0
    
    private let manager: CMMotionManager
    
    var timestamp: UInt64 = 0
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
    
    override init() {
        self.manager = CMMotionManager()
    }
    
    func requestAuthorization() {
        print("requesting authorization for mag")
        
        if self.manager.magnetometerActive && self.manager.magnetometerAvailable {
            self.auth = 1
        }
    }
    
    func startSensorUpdates(freq: Double) {
        requestAuthorization()
        
        if self.auth == 0 {
            return
        }
        
        self.manager.magnetometerUpdateInterval = freq
        let currentTimeA :NSDate = NSDate()
        
        self.timestamp = UInt64(currentTimeA.timeIntervalSince1970*1000) // time to timestamp
        if let data = self.manager.magnetometerData {
            self.x = Float(data.magneticField.x)
            self.y = Float(data.magneticField.y)
            self.z = Float(data.magneticField.z)
        }
    }
    
    func stopSensorUpdates() {
        self.manager.stopMagnetometerUpdates()
        self.auth = 0
    }
}