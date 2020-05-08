//
//  MapViewController.swift
//  LambdaTimeline
//
//  Created by FGT MAC on 5/8/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import MapKit
import FirebaseStorage

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: - Properties
    var post: Post?

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        showLocation()
    }
    
    func showLocation()  {
        
        guard let post = post else {return}
        
        let lat = CLLocationDegrees(floatLiteral: post.lat)
        let lon = CLLocationDegrees(floatLiteral: post.lon)
        print(lat,lon)
        let geoTag = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        createAnotation(for: geoTag)
        let coodinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let coordinateRegion = MKCoordinateRegion(center: geoTag, span: coodinateSpan)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func createAnotation(for location: CLLocationCoordinate2D)  {
        let anotation = MKPointAnnotation()
         anotation.coordinate = location
        self.mapView.addAnnotation(anotation)
    }
    
    
    
}
