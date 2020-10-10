//
//  MapViewController..swift
//  Virtual Tourist
//
//  Created by Diego on 05/10/2020.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        mapView.addGestureRecognizer(longPressGesture)
        if let region = getActualRegion() {
            mapView.setRegion(region, animated: true)
        }
    }
    
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
        if let coordinate = view.annotation?.coordinate {
            performSegue(withIdentifier: "photoAlbumView", sender: coordinate)
        }
        self.mapView.deselectAnnotation( view.annotation, animated: false)
    }
          
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbumView" {
            let PhotoAlbumVC = segue.destination as! PhotoAlbumViewController
            let coordinateRegion = sender as! CLLocationCoordinate2D
            PhotoAlbumVC.coordinateRegion = coordinateRegion
            navigationItem.backButtonTitle = "OK"
        }
    }
    
    
    @objc func handleLongPress(gestureReconizer: UITapGestureRecognizer) {
        if gestureReconizer.state == .began {
            let touchPoint = gestureReconizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.setCenter(coordinate, animated: true)
        }

    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveActualRegion(mapView.region)
        
    }
    fileprivate func saveActualRegion(_ region: MKCoordinateRegion) {
        let defaults =  UserDefaults.standard
        defaults.set(region.center.latitude, forKey: Constants.latitude)
        defaults.set(region.center.longitude, forKey: Constants.longitude)
        defaults.set(region.span.latitudeDelta, forKey: Constants.latitudeDelta)
        defaults.set(region.span.longitudeDelta, forKey: Constants.longitudeDelta)
        
    }
    
    fileprivate func getActualRegion() -> MKCoordinateRegion? {
        let defaults =  UserDefaults.standard
        guard let latitude = defaults.object(forKey: Constants.latitude) as? Double,
              let longitude = defaults.object(forKey: Constants.longitude) as? Double,
              let latitudeDelta = defaults.object(forKey: Constants.latitudeDelta)as? Double,
              let longitudeDelta = defaults.object(forKey: Constants.longitudeDelta)as? Double else {
            return nil
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
    }

    
}

