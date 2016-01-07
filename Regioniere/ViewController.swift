//
//  ViewController.swift
//  Regioniere
//
//  Created by Luigi Villa on 07/01/16.
//  Copyright © 2016 Luigi Villa. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, MapCircleViewDelegate
{

	@IBOutlet weak var map: MKMapView!
	var currentOverlay:MKCircle?
	
	@IBOutlet weak var tratteggioView: MapCircleView!
	var theAnnot:MyAnnotation = MyAnnotation(location: CLLocationCoordinate2D(latitude: 45.4642700, longitude: 9.1895100))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		map.delegate = self
		tratteggioView.delegate = self
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		showOverlay()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		resizeMap()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func showOverlay()
	{
		currentOverlay = MKCircle(centerCoordinate: theAnnot.coordinate, radius: theAnnot.radius)
		map.addOverlay(currentOverlay!)
		resizeMap()
		tratteggioView.setupInitialData(map, circle: currentOverlay!)
	}

	// MARK: - MKMapViewDelegate gestisco selezione e spostamento annotazioni
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
	{
		var pinView:MKPinAnnotationView? = mapView.dequeueReusableAnnotationViewWithIdentifier("reusablePinAnnotation") as? MKPinAnnotationView
		if pinView == nil
		{
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "reusablePinAnnotation")
		}
		
		pinView!.pinTintColor = UIColor.redColor()
		pinView!.canShowCallout = true
		
		return pinView
	}
	
	func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool)
	{
		tratteggioView.hide()
	}
	
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
	{
		if currentOverlay != nil
		{
			tratteggioView.update(currentOverlay!)
		}
		
		tratteggioView.show()
	}
	
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
	{
		let renderer = MKCircleRenderer(circle: currentOverlay!)
		renderer.fillColor = UIColor.cyanColor().colorWithAlphaComponent(0.3)
		renderer.strokeColor = UIColor.redColor()
		renderer.lineWidth = 1.0 * UIScreen.mainScreen().scale
		return renderer
	}

	
	// MARK: - MapCircleViewDelegate
	func radiusUpdate(newRadius:CGFloat)
	{
		//print("newRadius = \(newRadius)")
		theAnnot.radius = CLLocationDistance(newRadius)
		if currentOverlay != nil
		{
			map.removeOverlay(currentOverlay!)
		}
		currentOverlay = MKCircle(centerCoordinate: theAnnot.coordinate, radius: theAnnot.radius)
		map.addOverlay(currentOverlay!)
		
		map?.zoomEnabled = true
		map?.scrollEnabled = true
		map?.userInteractionEnabled = true
		
		resizeMap()
	}
	
	func resizeMap()
	{
		let insetSize:CGFloat = 60
		let insets = UIEdgeInsets(top: insetSize, left: insetSize, bottom: insetSize, right: insetSize)
		let rect = map.mapRectThatFits(currentOverlay!.boundingMapRect, edgePadding: insets)
		print("currentOverlay!.boundingMapRect = \(currentOverlay!.boundingMapRect) map.visibleMapRect = \(map.visibleMapRect) rect = \(rect)")
		map.visibleMapRect = rect
	}
	
	// MARK: - touches
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		super.touchesBegan(touches, withEvent: event)
		
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.tratteggioView!.touchesBegan(touches, withEvent: event)
			if self.tratteggioView.radiuAdjust == true
			{
				if self.currentOverlay != nil
				{
					self.map.removeOverlay(self.currentOverlay!)
				}
			}
		})
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
	{
		super.touchesMoved(touches, withEvent: event)
		if(tratteggioView.radiuAdjust == true)
		{
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.tratteggioView!.touchesMoved(touches, withEvent: event)
			})
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		super.touchesEnded(touches, withEvent: event)
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			if self.currentOverlay != nil
			{
				self.map.addOverlay(self.currentOverlay!)
			}
			
			self.tratteggioView!.touchesEnded(touches, withEvent: event)
		})
	}
	
	override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
	{
		//print("touch cancellato")
		super.touchesCancelled(touches, withEvent: event)
		
		if self.currentOverlay != nil
		{
			self.map.addOverlay(self.currentOverlay!)
		}
		
		self.tratteggioView!.touchesCancelled(touches, withEvent: event)
	}

}

