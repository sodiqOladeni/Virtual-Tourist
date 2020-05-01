//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by sodiqOladeni on 09/04/2020.
//  Copyright © 2020 NotZero Technologies. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController:DataController!
    var fetchedResultContoller:NSFetchedResultsController<Pin>!
    private var allPins:[Pin] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Set app name
        self.navigationItem.title = Constants.App.appName
        //Check initial state
        setupMap()
        //Load Pins
        fetchPinsToTheMap()
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultContoller = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Identifier.navigateToAlbumViewController{
            let albumViewController = segue.destination as! PhotoAlbumViewController
            
            let pinCoordinate = sender as! CLLocationCoordinate2D
            for pin in allPins {
                if pin.latitude == pinCoordinate.latitude && pin.longitude == pinCoordinate.longitude {
                    albumViewController.pin = pin
                    break
                }
            }
            
            albumViewController.dataController = dataController
        }
    }
    
    @IBAction func createPinOnLongPressMap(_ sender: UILongPressGestureRecognizer) {
        
        let mapPoint = sender.location(in: mapView)
        let mapCoordinate = mapView.convert(mapPoint, toCoordinateFrom: mapView)
        //Create Annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapCoordinate
        //Check current annotations
        let annotations = mapView.annotations
        for eachAnnotation in annotations{
            if (eachAnnotation.coordinate.latitude == mapCoordinate.latitude && eachAnnotation.coordinate.longitude == mapCoordinate.longitude) {
                return
            }
        }
        // Update the map with pin
        mapView.addAnnotation(annotation)
        // Save the pin info to the Db
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        allPins.append(pin)
        try? dataController.viewContext.save()
    }
    
    fileprivate func setupMap(){
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Constants.App.appHasLaunchBefore) {
            let centerLatitude  = defaults.double(forKey: Constants.UserDefaultKey.latitudeKey)
            let centerLongitude = defaults.double(forKey: Constants.UserDefaultKey.longitudeKey)
            let latitudeDelta   = defaults.double(forKey: Constants.UserDefaultKey.latitudeDeltaKey)
            let longitudeDelta  = defaults.double(forKey: Constants.UserDefaultKey.longitudeDeltaKey)
            
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            let spanCoordinate = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
            self.mapView.setRegion(region, animated: true)
        } else {
            defaults.set(true, forKey: Constants.App.appHasLaunchBefore)
        }
    }
    
    fileprivate func fetchPinsToTheMap(){
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let availablePins = try? dataController.viewContext.fetch(fetchRequest){
            var currentAnnotations = [MKPointAnnotation]()
            
            allPins = availablePins
            for eachPin in availablePins{
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = eachPin.latitude
                annotation.coordinate.longitude = eachPin.longitude
                currentAnnotations.append(annotation)
            }
            
            DispatchQueue.main.async {
                self.mapView.showAnnotations(currentAnnotations, animated: true)
            }
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchedResultContoller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultContoller.performFetch()
        } catch {
            fatalError("The fetch could not be performed")
        }
    }
}

extension TravelLocationMapViewController:MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var mapPinView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.Identifier.mapPinId) as? MKPinAnnotationView
        
        if mapPinView == nil {
            mapPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.Identifier.mapPinId)
            mapPinView!.canShowCallout = false
            mapPinView!.pinTintColor = .red
        }else {
            mapPinView!.annotation = annotation
        }
        return mapPinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(mapView.region.center.latitude, forKey: Constants.UserDefaultKey.latitudeKey)
        userDefaults.set(mapView.region.center.longitude, forKey: Constants.UserDefaultKey.longitudeKey)
        userDefaults.set(mapView.region.span.latitudeDelta, forKey: Constants.UserDefaultKey.latitudeDeltaKey)
        userDefaults.set(mapView.region.span.longitudeDelta, forKey: Constants.UserDefaultKey.longitudeDeltaKey)
        
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: Constants.Identifier.navigateToAlbumViewController, sender:  view.annotation?.coordinate)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}


