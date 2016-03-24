//
//  GyroscopeController.swift
//  nervousnet-iOS
//  
//  Created by __DEVNAME__ on 03 Mar 2016.
//  Copyright (c) 2016 ETHZ . All rights reserved.
//
//WARNING - THIS CODE IS AUTOGENERATED BY DEVSKETCH AND CAN BE OVERWRITTEN


import Foundation

class GyroscopeController : NSObject {

    var auth: Int = 0
    
    var timestamp: UInt64
    var x: Float
    var y: Float
    var z: Float
    
    override init() {
        //self.manager = CMMotionManager()
    }
    
    func requestAuthorization() {
        print("requesting authorization for acc")
        self.auth = 0
    }
    
    func startSensorUpdates(manager: CMMotionManager, Double : freq) {
        requestAuthorization()
        
        if self.auth == 0 {
            return
        }
        
        self.manager.accelerometerUpdateInterval = freq
        manager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
            [weak self](data: CMAccelerometerData!, error: NSError!) in
            var currentTimeA :NSDate = NSDate()
            self.timestamp = UInt64(currentTimeA.timeIntervalSince1970*1000) // time to timestamp
            self.x = Float(data.rotationRate.x)
            self.y = Float(data.rotationRate.y)
            self.z = Float(data.rotationRate.z)
        }
    }
    
    func stopSensorUpdates(manager: CMMotionManager) {
        self.manager.stopGyroUpdates()
    }

}

