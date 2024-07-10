//
//  ViewController.swift
//  OnlyAR
//
//  Created by Haruto Hamano on 2024/07/09.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import MapKit
import Vision

class ViewController: UIViewController, UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var mapView: MapView!
    var pickerGroupView: UIView!
    var contentView: UIView!
    var scrollView: UIScrollView!
    var mapImageView: UIImageView!
    var mapImage: UIImage = UIImage(named: "map")!
    var pickerTitleLabel: UILabel!
    let PickerView = UIPickerView()
    let kakuninButton = UIButton()
    var roomArray: [(id: String, index: Character)] = []
    var start: Character = "H"
    var goal: Character = "H"
    
    private var resetButton: UIButton!
    private var stopButton: UIButton!
    
    var startLabel: UILabel!
    var goalLabel: UILabel!

    var locations: [CLLocation] = []
    
    var orientationTimer: Timer?
    var orientationRecords: [OrientationRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomArray = [
            (id: "H705", index: "H"),
            (id: "H706", index: "I"),
            (id: "H707", index: "J"),
            (id: "H708", index: "M"),
            (id: "H709", index: "N"),
            (id: "H723", index: "G"),
            (id: "H724", index: "F"),
            (id: "H725", index: "E"),
            (id: "H726", index: "D"),
            (id: "H727", index: "C"),
            (id: "H728", index: "B"),
            (id: "H729", index: "A")]
        
        setupScrollView()
        setupPickerGroupView()
        setupResetButton()
        setupStopButton()
        
        // Add annotation
        addAnnotation(at: CGPoint(x: 131, y: 846), title: "location")
    }
    
    private func setupResetButton() {
        resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(resetButton)
        
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 40),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupStopButton() {
        stopButton = UIButton(type: .system)
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        stopButton.layer.cornerRadius = 10
        stopButton.addTarget(self, action: #selector(stopOrientationButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(stopButton)
        
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.widthAnchor.constraint(equalToConstant: 80),
            stopButton.heightAnchor.constraint(equalToConstant: 40),
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    @objc private func resetButtonTapped() {
        mapView.path.removeAll()
        stopOrientationRecording()
        orientationRecords = []
        self.pickerGroupView.isHidden = false
    }
    
    @objc private func stopOrientationButtonTapped() {
        stopOrientationRecording()
        createFile()
    }

    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let aspectRatio = mapImage.size.height / mapImage.size.width
        mapImageView = UIImageView(image: mapImage)
        mapImageView.contentMode = .scaleAspectFit
        contentView.addSubview(mapImageView)
        
        mapImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mapImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mapImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            mapImageView.heightAnchor.constraint(equalTo: mapImageView.widthAnchor, multiplier: aspectRatio)
        ])
        
        mapView = MapView(frame: mapImageView.bounds)
        mapView.backgroundColor = .clear
        mapImageView.addSubview(mapView)
        
        // Ensuring contentView is tall enough to enable scrolling
        let bottomPadding: CGFloat = 200
        contentView.bottomAnchor.constraint(equalTo: mapImageView.bottomAnchor, constant: bottomPadding).isActive = true
    }

    
    func setupPickerGroupView() {
        pickerGroupView = UIView()
        view.addSubview(pickerGroupView)
            
        pickerGroupView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add labels for start and goal
        startLabel = UILabel()
        startLabel.text = "Start"
        startLabel.textAlignment = .center
        startLabel.backgroundColor = .clear
        startLabel.textColor = .white
        startLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        pickerGroupView.addSubview(startLabel)
        
        goalLabel = UILabel()
        goalLabel.text = "Goal"
        goalLabel.textAlignment = .center
        goalLabel.backgroundColor = .clear
        goalLabel.textColor = .white
        goalLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        pickerGroupView.addSubview(goalLabel)
        
        pickerGroupView.addSubview(PickerView)
        pickerGroupView.addSubview(kakuninButton)
        
        PickerView.delegate = self
        PickerView.dataSource = self

        PickerView.translatesAutoresizingMaskIntoConstraints = false
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        goalLabel.translatesAutoresizingMaskIntoConstraints = false
        kakuninButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pickerGroupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            pickerGroupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            pickerGroupView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            pickerGroupView.bottomAnchor.constraint(equalTo: kakuninButton.bottomAnchor, constant: 20),
                
            PickerView.leadingAnchor.constraint(equalTo: pickerGroupView.leadingAnchor),
            PickerView.trailingAnchor.constraint(equalTo: pickerGroupView.trailingAnchor),
            PickerView.topAnchor.constraint(equalTo: pickerGroupView.topAnchor),
            PickerView.heightAnchor.constraint(equalToConstant: 150),
                
            startLabel.leadingAnchor.constraint(equalTo: pickerGroupView.leadingAnchor),
            startLabel.trailingAnchor.constraint(equalTo: PickerView.centerXAnchor),
            startLabel.topAnchor.constraint(equalTo: PickerView.topAnchor, constant: 10),
                
            goalLabel.leadingAnchor.constraint(equalTo: PickerView.centerXAnchor),
            goalLabel.trailingAnchor.constraint(equalTo: pickerGroupView.trailingAnchor),
            goalLabel.topAnchor.constraint(equalTo: PickerView.topAnchor, constant: 10),
                
            kakuninButton.leadingAnchor.constraint(equalTo: pickerGroupView.leadingAnchor),
            kakuninButton.trailingAnchor.constraint(equalTo: pickerGroupView.trailingAnchor),
            kakuninButton.topAnchor.constraint(equalTo: PickerView.bottomAnchor, constant: 20),
            kakuninButton.heightAnchor.constraint(equalToConstant: 40)
        ])
            
        kakuninButton.setTitle("Confirmed Start and Goal", for: .normal)
        kakuninButton.titleLabel?.font = UIFont(name: "HiraKakuProN-W6", size: 14)
        kakuninButton.setTitleColor(.white, for: .normal)
        kakuninButton.backgroundColor = UIColor(red: 0.13, green: 0.61, blue: 0.93, alpha: 1.0)
        kakuninButton.addTarget(self, action: #selector(tapKakuninButton(_:)), for: .touchUpInside)
            
        PickerView.layer.borderWidth = 1.0
        PickerView.layer.borderColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.0).cgColor
        
        pickerGroupView.backgroundColor = .gray.withAlphaComponent(0.8)
    }
    
    func addAnnotation(at point: CGPoint, title: String) {
        let annotationView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        annotationView.backgroundColor = .red
        annotationView.center = point
        mapView.addSubview(annotationView)
        
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.backgroundColor = .white
        mapView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: annotationView.centerXAnchor),
            label.topAnchor.constraint(equalTo: annotationView.bottomAnchor, constant: 5)
        ])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return roomArray.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return roomArray[row].id
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            print(roomArray[row].id)
            start = roomArray[row].index
        case 1:
            print(roomArray[row].id)
            goal = roomArray[row].index
        default:
            break
        }
    }

    @objc func tapKakuninButton(_ sender: UIButton) {
        print(PickerView.selectedRow(inComponent: 0))
        
//        PickerView.removeFromSuperview()
//        kakuninButton.removeFromSuperview()
        
        self.pickerGroupView.isHidden = true
        
        let nodes = createNodes()
        if let startNode = nodes[start], let goalNode = nodes[goal] {
            let path = aStar(startNode: startNode, goalNode: goalNode)
            ///2D Map
            mapView.path = path
            
            startOrientationRecording()
        }
    }
    
    func createNodes() -> [Character: Node] {
        let map = [
            "#####",
            "#GsH#",
            "##r##",
            "##q##",
            "#FpI#",
            "##o##",
            "##n##",
            "#EmJ#",
            "##l##",
            "##k##",
            "#Dj##",
            "##i##",
            "##h##",
            "#Cg##",
            "##f##",
            "##e##",
            "#BdM#",
            "##c##",
            "##b##",
            "#AaN#",
            "#####"
        ]

        var nodes: [Character: Node] = [:]
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for (i, row) in map.enumerated() {
            for (j, char) in row.enumerated() {
                if char != "#" {
                    nodes[char] = Node(id: char, x: i, y: j)
                }
            }
        }

        for node in nodes.values {
            for direction in directions {
                let nx = node.x + direction.0
                let ny = node.y + direction.1
                if nx >= 0 && ny >= 0 && nx < map.count && ny < map[nx].count {
                    let neighborChar = Array(map[nx])[ny]
                    if neighborChar != "#", let neighbor = nodes[neighborChar] {
                        node.neighbors.append(neighbor)
                    }
                }
            }
        }
        
        return nodes
    }
}




extension ViewController: LocationServiceDelegate {
    func trackingLocation(for currentLocation: CLLocation) {

    }
    
    func modifyLocationCoordinates(location: CLLocation, newLatitude: CLLocationDegrees, newLongitude: CLLocationDegrees) -> CLLocation {
            return CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude),
                altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy,
                verticalAccuracy: location.verticalAccuracy,
                course: location.course,
                speed: location.speed,
                timestamp: location.timestamp
            )
        }
    
    func trackingLocationDidFail(with error: Error) {
        print("error")
    }
}

///2D Map
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView") ?? MKAnnotationView()
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        annotationView.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.1)
            renderer.strokeColor = .red
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let alertController = UIAlertController(title: "Welcome to \(String(describing: title))", message: "You've selected \(String(describing: title))", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}


/// Get and Record Orientation
extension ViewController {
    func createFile() {
        let fileManager = FileManager.default
        do {
            let currentTime = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let currentTimeString = dateFormatter.string(from: currentTime)
            
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent("2D_orientationRecords_\(currentTimeString).csv")
                    
            // CSVファイルのヘッダー
            var csvText = "timestamp,orientation\n"
                    
            // orientationRecords配列をCSV形式に変換
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for record in orientationRecords {
                let dateString = dateFormatter.string(from: record.timestamp)
                csvText += "\(dateString),\(record.orientation)\n"
            }
                    
            // データをファイルに書き込み
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file created successfully at \(fileURL.path)")
            } catch {
                print("Error creating CSV file: \(error.localizedDescription)")
            }
    }
    
    @objc func checkOrientation() {
        let orientation = UIDevice.current.orientation
        let orientationValue = getOrientationValue(orientation)
        let currentTime = Date()
        let record = OrientationRecord(timestamp: currentTime, orientation: orientationValue)
        orientationRecords.append(record)
        print("Recorded Orientation at \(currentTime): \(orientationValue)")
    }
    
    func getOrientationValue(_ orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .unknown:
            return 0
        case .portrait:
            return 1
        case .portraitUpsideDown:
            return 2
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 4
        case .faceUp:
            return 5
        case .faceDown:
            return 6
        @unknown default:
            return -1
        }
    }
    
    func startOrientationRecording() {
        // 既にタイマーが動作している場合は無視する
        guard orientationTimer == nil else { return }
        
        orientationTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(checkOrientation), userInfo: nil, repeats: true)
        print("Orientation recording started.")
    }
    
    func stopOrientationRecording() {
        orientationTimer?.invalidate()
        orientationTimer = nil
        print("Orientation recording stopped.")
    }
}
