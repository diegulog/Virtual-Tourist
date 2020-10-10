//
//  MapViewController..swift
//  Virtual Tourist
//
//  Created by Diego on 05/10/2020.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    var dataController: DataController!
    var annotations = [MKAnnotation]()
    var pins:[Pin] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        getLastLocation()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
            updateData()
        }
    }
    
    func updateData() {
        print("updateData")
        let clear = self.mapView.annotations
        self.mapView.removeAnnotations(clear)
        var annotations = [MKAnnotation]()
        for pin in self.pins {
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let annotation = MyPointAnnotation(coordinate: coordinate, pin: pin)
            annotations.append(annotation)
        }
        self.mapView?.addAnnotations(annotations)
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        self.dataController.save()
        let annotation = MyPointAnnotation(coordinate: coordinate, pin: pin)
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(coordinate, animated: true)

    }
    
    @objc func handleLongPress(gestureReconizer: UITapGestureRecognizer) {
        if gestureReconizer.state == .began {
            let touchPoint = gestureReconizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            addPin(coordinate: coordinate)

        }

    }
    
    fileprivate func saveActualRegion(_ region: MKCoordinateRegion) {
        let defaults =  UserDefaults.standard
        defaults.set(region.center.latitude, forKey: Constants.latitude)
        defaults.set(region.center.longitude, forKey: Constants.longitude)
        defaults.set(region.span.latitudeDelta, forKey: Constants.latitudeDelta)
        defaults.set(region.span.longitudeDelta, forKey: Constants.longitudeDelta)
        
    }
    
    fileprivate func getLastLocation() {
        let defaults =  UserDefaults.standard
        guard let latitude = defaults.object(forKey: Constants.latitude) as? Double,
              let longitude = defaults.object(forKey: Constants.longitude) as? Double,
              let latitudeDelta = defaults.object(forKey: Constants.latitudeDelta)as? Double,
              let longitudeDelta = defaults.object(forKey: Constants.longitudeDelta)as? Double else {
            return
        }
        let region =  MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapView.setRegion(region, animated: true)
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
    
    func mapView(_ map: MKMapView, didSelect view: MKAnnotationView) {
        self.mapView.deselectAnnotation( view.annotation, animated: false)
        if let annotation = view.annotation {
            performSegue(withIdentifier: "photoAlbumView", sender: annotation)
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveActualRegion(mapView.region)
        
    }
          
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbumView" {
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            let annotation = sender as! MyPointAnnotation
            photoAlbumVC.pin = annotation.pin
            photoAlbumVC.dataController = dataController
            navigationItem.backButtonTitle = "OK"
        }
    }
    
}

class MyPointAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var pin: Pin?

    init(coordinate: CLLocationCoordinate2D, pin: Pin) {
        self.coordinate = coordinate
        self.pin = pin
    }
}
