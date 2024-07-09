//
//  LocationServiceDelegate.swift
//  OnlyAR
//
//  Created by Haruto Hamano on 2024/07/09.
//

import CoreLocation

protocol LocationServiceDelegate: class {
    func trackingLocation(for currentLocation: CLLocation)
    func trackingLocationDidFail(with error: Error)
}
