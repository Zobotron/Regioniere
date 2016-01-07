//
//  MapCircleView.swift
//  Passando

//	Qui disegno solo il segmento tratteggiato e il pallino, in più ascolto i movimenti del ditone
//
//  Created by Luigi Villa on 26/08/15.
//  Copyright (c) 2015 Luigi Villa. All rights reserved.
//

import UIKit
import MapKit

protocol MapCircleViewDelegate
{
	func radiusUpdate(newRadius:CGFloat)
	func resizeMap()
}

class MapCircleView: UIView
{
	weak var map:MKMapView?
	weak var mapcircle:MKCircle?
	
	var centro:CGPoint?
	var radius:CGFloat?
	
	var pallino:CAShapeLayer?
	let pallinoRadius:CGFloat = 10
	
	var coda:CAShapeLayer?
	let codaRadius:CGFloat = 30
	
	var radiuAdjust:Bool = false;
	
	var delegate:MapCircleViewDelegate?
	
	let MIN_DISTANCE:CLLocationDistance = 100
	let MAX_DISTANCE:CLLocationDistance = 10000
	
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
	}
	
	// Inizializzazione dei dati, il controller mi passa la mappa e la zona di interesse
	func setupInitialData(mappa: MKMapView, circle: MKCircle)
	{
		map = mappa
		mapcircle = circle
		
		// Coordinate del cerchio
		centro = map!.convertCoordinate(mapcircle!.coordinate, toPointToView: self)
		
		let mapRect = mapcircle?.boundingMapRect
		let region = MKCoordinateRegionForMapRect(mapRect!)
		let rect = map!.convertRegion(region, toRectToView: self)
		
		radius = rect.width / 2
		
		// Il pallino centrale
		pallino = CAShapeLayer()
		pallino?.fillColor = UIColor.blackColor().CGColor
		let path = UIBezierPath(ovalInRect: CGRectMake(0, 0, pallinoRadius, pallinoRadius))
		pallino?.frame = CGRectMake(centro!.x - pallinoRadius / 2, centro!.y - pallinoRadius / 2, pallinoRadius, pallinoRadius)
		pallino?.path = path.CGPath
		
		// Quello al limite del cerchio dell'area
		coda = CAShapeLayer()
		coda?.fillColor = UIColor.blackColor().CGColor
		coda?.frame = CGRectMake(centro!.x + radius! - codaRadius / 2, centro!.y - codaRadius / 2, codaRadius, codaRadius)
		coda?.path = UIBezierPath(ovalInRect: CGRectMake(0, 0, codaRadius, codaRadius)).CGPath
		
		self.layer.addSublayer(pallino!)
		self.layer.addSublayer(coda!)
		
		setNeedsDisplay()
	}
	
	
	func update(circle: MKCircle)
	{
		mapcircle = circle
		centro = map?.convertCoordinate(mapcircle!.coordinate, toPointToView: self)
		
		let mapRect = mapcircle?.boundingMapRect
		let region = MKCoordinateRegionForMapRect(mapRect!)
		let rect = map?.convertRegion(region, toRectToView: self)
		
		if rect != nil
		{
			radius = rect!.width / 2
		}
		
		setNeedsDisplay()
	}
	
	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool
	{
		if let thePallino = pallino
		{
			let balinPoint = thePallino.convertPoint(point, fromLayer: self.layer)
			if thePallino.containsPoint(balinPoint)
			{
				return true
			}
		}
		return false
	}
	
	
	// Only override drawRect: if you perform custom drawing.
	// An empty implementation adversely affects performance during animation.
	override func drawRect(rect: CGRect)
	{
		super.drawRect(rect)
		
		if map == nil || mapcircle == nil
		{
			return
		}
		
		centro = map!.convertCoordinate(mapcircle!.coordinate, toPointToView: self)
		
		// buco
		let context = UIGraphicsGetCurrentContext()
		
		if(radiuAdjust == true) // solo se sto ridimensionando il raggio, altrimenti c'è l'overlay
		{
			CGContextSaveGState(context)
			
			// Buco
			let holeRect = CGRectMake(centro!.x - radius!, centro!.y - radius!, radius! * 2, radius! * 2)
			
			CGContextSetFillColorWithColor(context, UIColor.cyanColor().colorWithAlphaComponent(0.3).CGColor)
			CGContextFillEllipseInRect(context, holeRect)
			
			// Bordo
			CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
			CGContextSetLineWidth(context, 1.0 * UIScreen.mainScreen().scale)
			CGContextStrokeEllipseInRect(context, holeRect)
			
			CGContextRestoreGState(context)
		}
		
		// Il pallino va al limite del cerchio
		pallino?.frame = CGRectMake(centro!.x - pallinoRadius / 2, centro!.y - pallinoRadius / 2, pallinoRadius, pallinoRadius)
		coda?.frame = CGRectMake(centro!.x + radius! - codaRadius / 2, centro!.y - codaRadius / 2, codaRadius, codaRadius)
		
		// Setto i colori
		let strokeColor = UIColor.blackColor()
		strokeColor.setStroke()
		
		// disegno
		
		// Linea tratteggiata
		let linea:UIBezierPath = UIBezierPath()
		
		linea.lineWidth = 3
		let pattern:[CGFloat] = [20, 10]
		linea.setLineDash(pattern, count: 2, phase: 0)
		
		// Coordinate del cerchio
		let startPoint = CGPointMake(centro!.x + pallinoRadius / 2, centro!.y)
		let endPoint = CGPointMake(centro!.x + radius!, centro!.y)
		linea.moveToPoint(startPoint)
		linea.addLineToPoint(endPoint)
		
		linea.stroke()
		
		// Label distanza solo se sto muovendo il pallino
		if(radiuAdjust == true)
		{
			let point = CGPointMake(centro!.x + radius!, centro!.y)
			let distance:CLLocationDistance = getMapDistanceFromCenter(point)
			
			//print("distance in drawRect = \(distance)")
			
			let font = UIFont.systemFontOfSize(17)
			let attr:[String : AnyObject] = [NSFontAttributeName : font]
			let distString = NSMutableAttributedString(string:"\(Int(distance)) metri", attributes: attr)
			let stringSize = distString.size()
			let xCoord = ((endPoint.x - startPoint.x - stringSize.width) / 2) + startPoint.x
			let yCoord = startPoint.y + 5
			
			UIColor.blueColor().setStroke()
			distString.drawAtPoint(CGPointMake(xCoord, yCoord))
		}
	}
	
	func distanceBetween(p1: CGPoint, p2: CGPoint) -> CGFloat
	{
		return sqrt(pow(p2.x-p1.x,2)+pow(p2.y-p1.y,2));
	}
	
	// MARK: - apparizione e sperizione
	func hide()
	{
		self.hidden = true
	}
	
	func show()
	{
		self.hidden = false
		setNeedsDisplay()
	}
	
	// MARK: gestione touches custom
	
	// Ritorna true se il tocco è avvenuto nel pallino
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
	{
		if let touch:UITouch = touches.first
		{
			let touchPoint = touch.locationInView(self)
			if let laCoda = coda
			{
				if(CGRectContainsPoint(laCoda.frame, touchPoint) == true)
				{
					radiuAdjust = true
					map?.zoomEnabled = false
					map?.scrollEnabled = false
					map?.userInteractionEnabled = false
				}
			}
		}
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if(radiuAdjust == false)
		{
			return
		}
		
		if let touch:UITouch = touches.first
		{
			// Le coordinate del punto mi danno il nuovo raggio
			let point = touch.locationInView(self)
			var distance:CLLocationDistance = getMapDistanceFromCenter(point)
			
			radius = getRadiusForDistance(&distance, lowerLimit: MIN_DISTANCE, upperLimit: MAX_DISTANCE)
			//			//print("distanza in touchesMoved = \(distance)")
			
			setNeedsDisplay()
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
	{
		if radiuAdjust == false
		{
			return
		}
		
		updateRadius()
	}
	
	override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
	{
		if(radiuAdjust == false)
		{
			return
		}
		
		updateRadius()
	}
	
	func updateRadius()
	{
		// Le coordinate del punto mi danno il nuovo raggio
		let point = CGPointMake(centro!.x + radius!, centro!.y)
		var distance:CLLocationDistance = getMapDistanceFromCenter(point)
		
		if(distance < MIN_DISTANCE)
		{
			distance = MIN_DISTANCE
		}
		else if distance > MAX_DISTANCE
		{
			distance = MAX_DISTANCE
		}
		
		//		//print("distanza in touchesEnded = \(distance)")
		radiuAdjust = false
		delegate?.radiusUpdate(CGFloat(distance))
	}
	
	func getMapDistanceFromCenter(point: CGPoint)->CLLocationDistance
	{
		let pointCoords = map!.convertPoint(point, toCoordinateFromView: self)
		let centerCoords = map!.convertPoint(centro!, toCoordinateFromView: self)
		
		let loc1 = CLLocation(latitude: pointCoords.latitude, longitude: pointCoords.longitude)
		let loc2 = CLLocation(latitude: centerCoords.latitude, longitude: centerCoords.longitude)
		
		let distance:CLLocationDistance = loc1.distanceFromLocation(loc2)
		return distance
	}
	
	func getRadiusForDistance(inout distance: CLLocationDistance, lowerLimit: Double, upperLimit: Double)->CGFloat
	{
		if(distance < lowerLimit)
		{
			distance = lowerLimit
		}
		else if distance > upperLimit
		{
			distance = upperLimit
		}
		
		// creo una region per sapere dov'è il punto X
		let centerCoords = map!.convertPoint(centro!, toCoordinateFromView: self)
		let region = MKCoordinateRegionMakeWithDistance(centerCoords, distance * 2, distance * 2)
		let regionRect = map?.convertRegion(region, toRectToView: self)
		let finalPoint = CGPointMake(centro!.x + regionRect!.width / 2, centro!.y)
		
		let toRet = distanceBetween(finalPoint, p2: centro!)
		return toRet
	}
}
