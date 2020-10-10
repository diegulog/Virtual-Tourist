//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Diego on 05/10/2020.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var blockOperations: [BlockOperation] = []
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var loadingIndicatior: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    deinit {
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingUI(loading: true)
        errorLabel.isHidden = true
        prepareMap()
        configFlowLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    
    func configFlowLayout() {
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func loadingUI(loading: Bool){
        if loading {
            loadingIndicatior.startAnimating()
        }else{
            loadingIndicatior.stopAnimating()
        }
        newCollectionButton.isEnabled = !loading
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.id)")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        guard let photos = fetchedResultsController.fetchedObjects else {
            return
        }
        
        if (photos.count == 0) {
            searchPhotos(page: 1, latitude: pin.latitude, longitude: pin.longitude)
        }else{
            loadingUI(loading: false)
        }
        
    }
    
    func searchPhotos(page: Int, latitude: Double, longitude: Double)  {
        Cliente.search(page: page, lat: latitude , lon: longitude) { response, error in
            self.loadingUI(loading: false)
            if let error = error {
                self.setError(error: error.localizedDescription)
                return
            }
            
            if let response = response {
                self.pin.totalPhotos = Int64(response.total) ?? 0
                if response.photo.isEmpty  {
                    self.setError(error: "Photos not available for this location")
                }
                response.photo.forEach { photoResponse in
                    self.addPhoto(photoResponse: photoResponse)
                }
                self.dataController.save()
            }
        }
    }
    
    
    func deleteAndClose(){
        dataController.viewContext.delete(self.pin)
        dataController.save()
        self.navigationController?.popViewController(animated: true)
    }
    
    func setError(error: String) {
        self.errorLabel.text = error
        self.errorLabel.isHidden = false
        self.newCollectionButton.isEnabled = false
    }
    
    func addPhoto(photoResponse: PhotoResponse) {
        let photo = Photo(context: dataController.viewContext)
        let url = "https://live.staticflickr.com/\(photoResponse.server)/\(photoResponse.id)_\(photoResponse.secret).jpg"
        photo.url = url
        photo.pin = pin
    }
    

    fileprivate func prepareMap() {
        let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(exactly: 2000 )!, longitudinalMeters:  CLLocationDistance(exactly: 2000)!)
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        self.mapView.addAnnotation(annotation)
    }
    

    func savePhotoBackground(data: Data, photo: Photo){
        let backgroundContext:NSManagedObjectContext! = self.dataController.backgroudContext
        let photoId = photo.objectID
        self.dataController.backgroudContext.perform {
            let backgroundPhoto = backgroundContext.object(with: photoId) as! Photo
            backgroundPhoto.img = data
            try? backgroundContext.save()
        }
    }

    func setImage(imageView: UIImageView?, image: UIImage, mode: UIView.ContentMode){
        imageView?.contentMode = mode
        imageView?.image = image
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Actions

    
    @IBAction func deleteAction(_ sender: Any) {
        
        let alert = UIAlertController(title: "Delete Pin", message: "Do you want to delete the pin and all photos?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(alert: UIAlertAction!) in self.deleteAndClose()}))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func newCollectionAction(_ sender: Any) {
        loadingUI(loading: true)
        let randomPage = Cliente.getRandomPageNum(photosAvailable: Int(pin.totalPhotos))
        fetchedResultsController.fetchedObjects?.forEach({ photo in
            dataController.viewContext.delete(photo)
        })
        print("randomPage: \(randomPage)")
        self.dataController.save()
        
        searchPhotos(page: randomPage, latitude: pin.latitude, longitude: pin.longitude)
    }

    
    // -------------------------------------------------------------------------
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        self.dataController.save()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = photoCollectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if let imgData = photo.img{
            setImage(imageView: cell.imageView, image: UIImage(data: imgData)!, mode: .scaleToFill)
        }else{
            setImage(imageView: cell.imageView, image: UIImage(systemName: "photo")!, mode: .center)
            Cliente.downloadImage(path: URL(string: photo.url!)!) { data, error in
                if let imgData = data {
                    self.setImage(imageView: cell.imageView, image: UIImage(data: imgData)!, mode: .scaleToFill)
                    self.savePhotoBackground(data: imgData, photo: photo)
                }
            }
        }
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
    }
    
}

extension PhotoAlbumViewController :NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    self?.photoCollectionView.insertItems(at: [newIndexPath!])
                })
            )
            break
        case .delete:
            blockOperations.append(
                BlockOperation(block: {  [weak self] in
                    self?.photoCollectionView.deleteItems(at: [indexPath!])
                })
            )
            break
        case .update:
            blockOperations.append(
                BlockOperation(block: {  [weak self] in
                    self?.photoCollectionView.reloadItems(at: [indexPath!])
                })
            )
            break
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: {  [weak self] in
                    self?.photoCollectionView.insertSections(indexSet)
                    
                })
            )
            break
        case .delete:
            blockOperations.append(
                BlockOperation(block: {  [weak self] in
                    self?.photoCollectionView.deleteSections(indexSet)
                })
            )
            break
        case .update:
            blockOperations.append(
                BlockOperation(block: {  [weak self] in
                    self?.photoCollectionView.reloadSections(indexSet)
                })
            )
        default: break
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoCollectionView.performBatchUpdates {
            for operation in self.blockOperations {
                operation.start()
            }
        } completion: { (finished) in
            self.blockOperations.removeAll(keepingCapacity: false)
        }
        
    }
    
    
    
}
