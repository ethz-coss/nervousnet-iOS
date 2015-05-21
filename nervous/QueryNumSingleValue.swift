//
//  QueryNumSingleValue.swift
//  nervousnet
//
//  Created by Ramapriya Sridharan on 21/05/2015.
//  Copyright (c) 2015 ethz. All rights reserved.
//

import UIKit
import Foundation
//query,querynum and querynumsinglevalue together

 class QueryNumSingleValue<G : SensorDescSingleValue> {
    
    
    var List : Array<SensorUploadSensorData>
    
    func getSensorId() -> UInt64{
        fatalError("Must Override")
    }
    init(from timestamp_from :UInt64,to timestamp_to : UInt64){
        let vm = NervousVM()
        
        self.List = vm.retrieve(0, fromTimeStamp: 0, toTimeStamp: 0)
        self.List = vm.retrieve(getSensorId(), fromTimeStamp: timestamp_from, toTimeStamp: timestamp_to)
        if(containsReading()){
            println("retreived list of size /(getCount())")
        }
    }
    
    
    func getCount() -> Int
    {
    return List.count
    }
    
    func containsReading() -> Bool{
        
        if(List.count == 0)  //check for null equivalent
        {return false}
        else
        {return true}
    }
    
    func createSensorDescSingleValue(sensorData : SensorUploadSensorData) -> G{
        fatalError("Must Override")
    }
    
    func getSensorDescriptorList() -> Array<G>{
        var descList = Array<G>()
        for sensorData in List {
            descList.append(createSensorDescSingleValue(sensorData))
            
        }
        return descList
    }
    
    func createDummyObject()-> G{
        fatalError("Must Override")
    }
    
    func getTimeRange(desc_list : Array<G>, s : Array<Float>, e : Array<Float>)-> Array<G>{
        var start = s[0]
        var end = e[0]
        
        var answer = Array<G>()
        
        for var i=0; i<desc_list.count ; ++i{
            
            let sensDesc = desc_list[i]
            if(sensDesc.getValue() <= end && sensDesc.getValue() >= start)
            {
                answer.append(sensDesc)
            }
        }
        
        return answer
        
    }
    
    
    
    

    
}