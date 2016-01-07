import UIKit
import MapKit

class MyAnnotation: NSObject, MKAnnotation
{
	var vertexIndex:Int = 0
	
	var title:String?
	var subtitle:String?
	var radius:CLLocationDistance = 100
	
	var coordinate:CLLocationCoordinate2D
	
	init(location: CLLocationCoordinate2D)
	{
		coordinate = location
		super.init()
	}
}
