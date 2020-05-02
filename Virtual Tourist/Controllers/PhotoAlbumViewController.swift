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
import JGProgressHUD

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var buttonNewCollection: UIButton!
    @IBOutlet weak var labelNoImagesAvailable: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    private let spacingBetweenItems:CGFloat = 5
    private var progressHud:JGProgressHUD!
    
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
        labelNoImagesAvailable.isHidden = true
        
        photoAlbumCollectionView.delegate = self
        photoAlbumCollectionView.dataSource = self
        // Setup pin on the map
        setupMap()
        setupFetchedResultsController()
        downloadPhotosFromFlicker()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultContoller = nil
    }
    
    @IBAction func clickedButtonAddNewCollection(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to download new Albums?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (alertAction) in
            self.removeAllPhotosWithLoopAndownloadNewPhotos()
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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
        let predicate = NSPredicate(format: "albumsToPin == %@", pin)
        let sortDescriptor = NSSortDescriptor(key: "photoId", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultContoller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultContoller.delegate = self
        
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
                currentCell.progressIndicator.isHidden = true
            }
        }
        return currentCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSelected = fetchedResultContoller.object(at: indexPath)
        dataController.viewContext.delete(itemSelected)
    }
    
    
    fileprivate func downloadPhotosFromFlicker(){
        if pin.pinAlbums?.count == 0 {
            buttonNewCollection.isEnabled = false
            progressHud = startProgressDialog(progressMessage: "Please wait...")
            
            FlickrClient.getPhotosForLocation(latitude: pin.latitude, longitude: pin.longitude) { (photos, error) in
                guard error == nil else {
                   self.displayNoImagesAvailable()
                    return
                }
                
                if let photos = photos {
                    if photos.photos.photo.count < 1 {
                        self.displayNoImagesAvailable()
                        
                    }else{
                        self.downloadAndDisplayImages(photos)
                    }
                }
                
                DispatchQueue.main.async {
                    self.stopProgressDialog(hud: self.progressHud)
                    self.buttonNewCollection.isEnabled = true
                }
            }
        }
    }
    
    fileprivate func downloadAndDisplayImages(_ photos: PhotosResponse) {
        self.labelNoImagesAvailable.isHidden = true
        for eachPhoto in photos.photos.photo {
            let album = Album(context: self.dataController.viewContext)
            FlickrClient.downloadPhotoWithId(photoUrl: eachPhoto.url_n) { (imageData, error) in
                album.albumsToPin = self.pin
                album.photo = imageData
                album.photoId = eachPhoto.id
                album.albumsToPin?.totalAlbumPhoto = Int32(photos.photos.photo.count)
                try? self.dataController.viewContext.save()
            }
        }
    }
    
    
       fileprivate func displayNoImagesAvailable() {
           self.buttonNewCollection.isEnabled = true
           self.labelNoImagesAvailable.isHidden = false
       }
    
    
    fileprivate func startProgressDialog(progressMessage:String) ->JGProgressHUD {
        var hud:JGProgressHUD?
        if hud == nil {
            hud = JGProgressHUD(style: .dark)
            hud!.textLabel.text = progressMessage
        }
        hud!.show(in: self.view)
        return hud!
    }
    
    fileprivate func stopProgressDialog(hud:JGProgressHUD?){
        if let hud = hud{
            hud.dismiss()
        }
    }
    
    func removeAllPhotosWithLoopAndownloadNewPhotos() {
        if let albums = fetchedResultContoller.fetchedObjects {
            
            for album in albums {
                self.dataController.viewContext.performAndWait {
                    self.removePhoto(album: album)
                }
            }
        }
        
        self.photoAlbumCollectionView.reloadData()
        photoAlbumCollectionView.numberOfItems(inSection: 0)
        // Load new collections
        downloadPhotosFromFlicker()
    }
    
    func removePhoto(album: Album) {
        dataController.viewContext.delete(album)
        do {
            try dataController.viewContext.save()
        } catch {
            print(error)
        }
    }
}
extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate{
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoAlbumCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photoAlbumCollectionView.deleteItems(at: [indexPath!])
        case .update:
            photoAlbumCollectionView.reloadItems(at: [newIndexPath!])
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
