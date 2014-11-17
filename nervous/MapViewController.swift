//
//  MapViewController.swift
//  nervous
//
//  Created by Sam Sulaimanov on 20/09/14.
//  Copyright (c) 2014 ethz. All rights reserved.
//
import Foundation
import UIKit
import SpriteKit
import CoreBluetooth
import CoreLocation

class MapViewController: UIViewController, RMMapViewDelegate, FilterButtonDelegate, CBPeripheralManagerDelegate, CLLocationManagerDelegate {
    
    let defaults :NSUserDefaults = NSUserDefaults.standardUserDefaults()

    var ownBeaconRegion :CLBeaconRegion!
    var ownBeaconPManager :CBPeripheralManager!
    var ownBeaconData :NSDictionary!
    
    var mapView :RMMapView!  //make this accessible so everyone can edit the map
    
    var levelSelected:Int! = 0
    
    @IBOutlet var mapUIView :UIView!
    @IBOutlet weak var refreshMapButton: UIButton!
    
    @IBAction func btnSettingsAction(sender: AnyObject) {
    
        
        var svc = self.storyboard?.instantiateViewControllerWithIdentifier("SensorViewController") as SensorViewController
        
        svc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        svc.modalPresentationStyle = UIModalPresentationStyle.Custom
        svc.view.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        
        self.presentViewController(svc, animated: true, completion: nil)
        
    }
    
    func filterButtonPressed(buttonTag: Int) {
        
        NSLog(buttonTag.description)
        
        var mapLayer :NSString = "blank"
        
        if(buttonTag == 2){
            mapLayer = "cch0"
            levelSelected = 1
            mapView.zoom = 17.5

        }else if(buttonTag == 3){
            mapLayer = "cch1"
            levelSelected = 2
            mapView.zoom = 17.5

        }else if(buttonTag == 4){
            mapLayer = "cch2"
            levelSelected = 3
            mapView.zoom = 17.5

        }else if(buttonTag == 5){
            mapLayer = "blank"
            levelSelected = 0
            mapView.zoom = 16


        }
        
        if(buttonTag != 1){
            mapView.tileSource = RMMBTilesSource(tileSetResource: mapLayer)
            mapView.removeAllAnnotations()
        }
    }
    
    @IBAction func mapReset(sender: AnyObject) {
        
        
        
        
        //redownload the map (if stale) and center on me
        var nvm = NervousVM()

        NSLog(NSString(format:"%2X", nvm.getHUUID().toUIntMax()))
        NSLog(NSString(format:"%2X", nvm.getLUUID().toUIntMax()))
        
        var mapData = MapDataController()
        
        
        //clear database
        mapData.deleteMapNodes(levelSelected)
        mapData.deleteMapEdges(levelSelected)

        mapData.downloadMapData(levelSelected)
        
        /*
        var circle :RMCircleAnnotation = RMCircleAnnotation(mapView: mapView, centerCoordinate: mapView.centerCoordinate, radiusInMeters: 10)
        circle.lineColor = UIColor.redColor()
        circle.fillColor = UIColor.orangeColor().colorWithAlphaComponent(0.3)
        circle.clusteringEnabled = true
        
        mapView.addAnnotation(circle)
        */
        
        
        var mapNodes = mapData.getMapNodes(levelSelected)
        var markers : [RMAnnotation] = []
                    
        for mapNode in mapNodes{
                
            var marker = RMAnnotation(mapView: mapView, coordinate: CLLocationCoordinate2DMake(mapNode.objectForKey("lat") as CLLocationDegrees, mapNode.objectForKey("lon") as CLLocationDegrees), andTitle: mapNode.objectForKey("label") as String)
            
            
            if(mapNode.allValues.count == 8){
                NSLog("adding edges to map marker %@", mapNode.valueForKey("uuid") as NSString)
                marker.userInfo = mapData.getNodeEdges(mapNode.valueForKey("uuid") as NSString, level: levelSelected) //place connected edges here
                NSLog("got nodes edges")
                
                
            }else{
                marker.userInfo = NSArray()
            }
            
            markers.append(marker)
            
        }
        
        if(mapView.annotations.count > 0){
            mapView.removeAllAnnotations()
        }
        
        mapView.addAnnotations(markers)
        
        
       self.mapEdgeLayer()
    }
    
    
    func mapEdgeLayer() -> Void {
        NSLog("attempting to draw edges")
        
        for marker in mapView.annotations {
            
            var m : RMAnnotation = marker as RMAnnotation
            
            if(m.title == "Phone"){
                NSLog("connecting %f,%f with %i beacon(s)", m.coordinate.latitude, m.coordinate.longitude, m.userInfo.count)
                
                var anls : [RMAnnotation] = []
                
                for connectedNode in m.userInfo as NSArray {
                    
                    NSLog("iterate through connected beacons")
                    
                    var connectedNodeProp: NSArray = connectedNode[1] as NSArray
                    var weight : Float = connectedNode[0] as Float
                    
                    
                    
                    if(connectedNodeProp.count > 0){
                        
                        var connectedNodeLat = connectedNodeProp.objectAtIndex(0).objectForKey("lat") as Double
                        var connectedNodeLon = connectedNodeProp.objectAtIndex(0).objectForKey("lon") as Double

                        
                        var edge :RMShape = RMShape(view: self.mapView)
                        edge.lineWidth = weight*2
                        edge.lineColor = UIColor(red:0.761, green:0.761, blue:0.761, alpha: 1)
                        
                        edge.moveToCoordinate(m.coordinate)
                        edge.drawsAsynchronously = true

                        edge.addLineToCoordinate(CLLocationCoordinate2DMake(connectedNodeLat, connectedNodeLon))
                        NSLog("drawing edge at %f,%f -- %f,%f with weight %f", m.coordinate.latitude, m.coordinate.longitude, connectedNodeLat, connectedNodeLon, weight)


                        var anl : RMAnnotation = RMAnnotation(mapView: self.mapView, coordinate: CLLocationCoordinate2DMake(connectedNodeLat, connectedNodeLon), andTitle: "edge")
                        
                        
                        anl.layer = edge
                        
                        
                        var phoneRadius:RMCircleAnnotation = RMCircleAnnotation(mapView: mapView, centerCoordinate: m.coordinate, radiusInMeters: 10.0)
                        phoneRadius.lineWidth = 2
                        phoneRadius.lineColor = UIColor.orangeColor()
                        phoneRadius.fillColor = UIColor.orangeColor().colorWithAlphaComponent(0.4)
                        
                       // anls.append(phoneRadius)
                        anls.append(anl)
                        
                    }
                    
                    
                }
                
                self.mapView.addAnnotations(anls)

                

            }
            
        }
    }
    
    /*
    func mapSensorLayer() -> Void {
        var mapData = MapDataController()
        var mapSensors = mapData.downloadSensorData()
        
        for marker in mapView.annotations {
            
            if(marker.title == "Beacon"){
                
                if(m.userInfo == 4){
                    //sensor beacon!
                    
                    //change label!
                    m.title = "Sensor:flowerpower:1:2:4:5"
                }
            
            }
        }
    
        
        //redraw map
        
        self.mapView.removeAllAnnotations()
        self.mapView.addAnnotations(mapView.annotations)
        
    }*/
    
    
    func mapAddStaticAnnotations() -> Void {
        
        var staticAnnotations:[RMAnnotation] = []
        
        var staticNodes = [[
                ["Raddison Blu", 53.56163, 9.98742],
                ["Kunst", 53.56135, 9.98561],
                ["Saal 4", 53.56236, 9.98572],
                ["Saal 3",  53.56257, 9.98592],
                ["Eingangshalle", 53.56170, 9.98625],
                ["Saal 6", 53.56178, 9.8554]
            ],
            [
                ["Raddison Blu", 53.56163, 9.98742],
                ["Kunst", 53.56135, 9.98561],
                ["Saal 4", 53.56236, 9.98572],
                ["Saal 3",  53.56257, 9.98592],
                ["Eingangshalle", 53.56170, 9.98625],
                ["Saal 6", 53.56178, 9.8554]
            ],
            [
                ["Raddison Blu", 53.56163, 9.98742],
                ["Kunst", 53.56135, 9.98561],
                ["Saal 4", 53.56236, 9.98572],
                ["Saal 3",  53.56257, 9.98592],
                ["Eingangshalle", 53.56170, 9.98625],
                ["Saal 6", 53.56178, 9.8554]
            ]
        ]
        
        for staticNode in staticNodes[levelSelected]{
            
            
            var marker = RMAnnotation(mapView: self.mapView, coordinate: CLLocationCoordinate2DMake(staticNode[1] as CLLocationDegrees, staticNode[2] as CLLocationDegrees), andTitle: staticNode[0] as String)

            staticAnnotations.append(marker)
        }
        
        self.mapView.addAnnotations(staticAnnotations)
    
    }

    
    func mapView(mapView: RMMapView!, layerForAnnotation annotation: RMAnnotation!) -> RMMapLayer! {
        
        
        var phoneMarker: RMMarker = RMMarker(UIImage: UIImage(named: "marker-1"))
        phoneMarker.canShowCallout = true
        
       /* var beaconRadius = RMCircle(view: mapView, radiusInMeters: 10.0)
        beaconRadius.lineColor = UIColor.redColor()
        beaconRadius.lineWidthInPixels = 5.0
        beaconRadius.fillColor = UIColor.redColor().colorWithAlphaComponent(0.2)
        phoneMarker.position = annotation.position
        beaconRadius.addSublayer(phoneMarker)
        */
        
        var beaconMarker: RMMarker = RMMarker(UIImage: UIImage(named: "marker-0"))
        beaconMarker.canShowCallout = true
        
        
        
        NSLog("modding map")

        if(annotation.title == "Phone"){
             return phoneMarker
        }else if(annotation.title == "edge"){
             NSLog("edgy")
             return annotation.layer
        }else{
             return beaconMarker
        }
        
        
    }
    
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {

        if (peripheral.state == CBPeripheralManagerState.PoweredOn)
        {
            // Bluetooth is on
            NSLog("started beacon bcast")
            
            self.ownBeaconPManager.startAdvertising(self.ownBeaconData)
            
        }
        else if (peripheral.state == CBPeripheralManagerState.PoweredOff)
        {
            NSLog("BLUETOOTH OFF: stopped beacon bcast")

            self.ownBeaconPManager.stopAdvertising()
        }
        else if (peripheral.state == CBPeripheralManagerState.Unsupported)
        {
            NSLog("unsupported")
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapAddStaticAnnotations()

        
        //setup beacon region
        let beaconUUIDString = "3C77C2A5-5D39-420F-97FD-E7735CC7F317"
        let beaconIdentifier = "ch.ethz.nervous"
        let beaconUUID:NSUUID? = NSUUID(UUIDString: beaconUUIDString)
        
        let nvm = NervousVM()
        let beaconMinor:CLBeaconMinorValue = nvm.getBeaconMinor()
        let beaconMajor:CLBeaconMajorValue = 33091
        
        //put phones beacon on map / broadcast a beacon
        if(defaults.integerForKey("sensorview_setting_1") == 1){
            self.ownBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, major: beaconMajor, minor:beaconMinor, identifier: beaconIdentifier)
            self.ownBeaconData = self.ownBeaconRegion.peripheralDataWithMeasuredPower(nil)
            self.ownBeaconPManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }
    
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshMapButton.layer.cornerRadius = 25
        
        let cchTileSource :RMMBTilesSource = RMMBTilesSource(tileSetResource: "blank") //default tile source
        
        
        let cchMapView :RMMapView = RMMapView(frame: self.view.bounds, andTilesource: cchTileSource)
        

        cchMapView.centerCoordinate = CLLocationCoordinate2DMake(9.986 as CLLocationDegrees, 53.5624 as CLLocationDegrees)
        
        cchMapView.userInteractionEnabled = true
        // default zoom
        cchMapView.zoom = 16
        // hard code minimal zoom. Try to run in without it to see what happens.
        cchMapView.minZoom = 16
        // hide MapBox logo
        cchMapView.showLogoBug = false
        cchMapView.hideAttribution = true
        cchMapView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        cchMapView.adjustTilesForRetinaDisplay = false
        
        var cchMapBGView :UIView! = UIView()
        cchMapBGView.backgroundColor = UIColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)
        
        cchMapView.backgroundView = cchMapBGView
        
        cchMapView.bouncingEnabled = true
        
        mapView = cchMapView
        mapView.delegate = self

        self.mapUIView.addSubview(mapView)
        
        
        
        
        let filterButton = FilterButtonView(frame: CGRectZero)
        filterButton.delegate = self
        
        self.mapUIView.addSubview(filterButton)
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}