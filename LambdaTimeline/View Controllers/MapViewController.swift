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

    @IBOutlet weak var mapview: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapview.delegate = self
        showLocation()
    }
    
    func showLocation()  {
        
        guard let post = post else {return}
        
        let lat = CLLocationDegrees(floatLiteral: post.lat)
        let lon = CLLocationDegrees(floatLiteral: post.lon)
        print(lat,lon)
        let geoTag = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let coodinateSpan = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        let coordinateRegion = MKCoordinateRegion(center: geoTag, span: coodinateSpan)
        self.mapview.setRegion(coordinateRegion, animated: true)
    }
    
}
