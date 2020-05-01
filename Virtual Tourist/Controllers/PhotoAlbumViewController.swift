//
//  TourDetailsViewController.swift
//  Virtual Tourist
//
//  Created by sodiqOladeni on 10/04/2020.
//  Copyright © 2020 NotZero Technologies. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var buttonNewCollection: UIButton!
    @IBOutlet weak var labelNoImagesAvailable: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    private let spacingBetweenItems:CGFloat = 5
    
    var dataController:DataController!
    var fetchedResultContoller:NSFetchedResultsController<Album>!
    
    var pin:Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = spacingBetweenItems
        flowLayout.minimumLineSpacing = spacingBetweenItems
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        photoAlbumCollectionView.delegate = self
        photoAlbumCollectionView.dataSource = self
        // Setup pin on the map
        setupMap()
        setupFetchedResultsController()
        downloadPhotosFromFlicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        photoAlbumCollectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultContoller = nil
    }
    
    @IBAction func clickedButtonAddNewCollection(_ sender: UIButton) {
        
    }
    
    fileprivate func setupMap(){
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.latitude
        annotation.coordinate.longitude = pin.longitude
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let spanCoordinate = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
        self.mapView.setRegion(region, animated: true)
        self.mapView.addAnnotation(annotation)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photoId", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultContoller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultContoller.performFetch()
        } catch {
            fatalError("The fetch could not be performed")
        }
    }
}

extension PhotoAlbumViewController:MKMapViewDelegate{
    
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
}

extension PhotoAlbumViewController:UICollectionViewDelegate, UICollectionViewDataSource{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchedResultContoller.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let currentCell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Identifier.albumCollectionCellId, for: indexPath) as! PhotoAlbumCollectionViewCell
        let currentCellData = fetchedResultContoller.object(at: indexPath)
        
        DispatchQueue.main.async {
            if let imageData = currentCellData.photo {
                currentCell.albumImageView.image = UIImage(data: imageData)
                currentCell.setNeedsLayout()
            }
            currentCell.progressIndicator.isHidden = true
            print("PinSelected ==> \(currentCellData)")
        }
        
        return currentCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSelected = fetchedResultContoller.object(at: indexPath)
        dataController.viewContext.delete(itemSelected)
        try? dataController.viewContext.save()
        
        collectionView.deleteItems(at: [indexPath])
    }
    
    fileprivate func downloadPhotosFromFlicker(){
        if pin.pinAlbums?.count == 0 {
            buttonNewCollection.isEnabled = false
            FlickrClient.getPhotosForLocation(latitude: pin.latitude, longitude: pin.longitude) { (photos, error) in
                guard error == nil else {
                    self.buttonNewCollection.isEnabled = true
                    self.labelNoImagesAvailable.isHidden = false
                    return
                }
                
                if let photos = photos {
                    for eachPhoto in photos.photos.photo {
                        let album = Album(context: self.dataController.viewContext)
                        FlickrClient.downloadPhotoWithId(imageId: eachPhoto.id) { (imageData, error) in
                            album.albumsToPin = self.pin
                            album.photo = imageData
                            album.photoId = eachPhoto.id
                            try? self.dataController.viewContext.save()
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.buttonNewCollection.isEnabled = true
                    self.labelNoImagesAvailable.isHidden = true
                    self.photoAlbumCollectionView.reloadData()
                }
            }
        }
    }
}
extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate{
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoAlbumCollectionView.insertItems(at: [indexPath!])
        case .delete:
            photoAlbumCollectionView.deleteItems(at: [indexPath!])
        case .update:
            photoAlbumCollectionView.reloadItems(at: [indexPath!])
        case .move:
            photoAlbumCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError("")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: photoAlbumCollectionView.insertSections(indexSet)
        case .delete: photoAlbumCollectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        @unknown default:
            fatalError("")
        }
    }
}
