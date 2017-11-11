//
//  ViewController.swift
//  Hello-AR-World
//
//  Created by Bill Barbour on 11/3/17.
//  Copyright © 2017 Bill Barbour. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case box = 1
    case plane = 2
}

class ViewController: UIViewController, ARSCNViewDelegate {

    var sceneView: ARSCNView!
    var planes = [OverlayPlane]()
    private let label :UILabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Inject the scene view
        self.sceneView = ARSCNView(frame: self.view.frame)
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        self.label.frame = CGRect(x: 0, y: 0, width: self.sceneView.frame.size.width, height: 44)
        self.label.center = self.sceneView.center
        self.label.textAlignment = .center
        self.label.textColor = UIColor.white
        self.label.font = UIFont.preferredFont(forTextStyle: .headline)
        self.label.alpha = 0
        self.sceneView.addSubview(self.label)
        self.view.addSubview(self.sceneView)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let scene = SCNScene()
        
        // Displaying text
//        let textGeometry = SCNText(string: "Hello, World", extrusionDepth: 1.0)
//        textGeometry.firstMaterial?.diffuse.contents = UIColor.black
//        let textNode = SCNNode(geometry: textGeometry)
//        textNode.position = SCNVector3(0,0.1,-0.5)
//        textNode.scale = SCNVector3(0.02, 0.02, 0.02)
//        scene.rootNode.addChildNode(textNode)
        
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let material = SCNMaterial()
        material.name = "Color"
        material.diffuse.contents = UIImage(named: "brick.jpg")
        
        let node = SCNNode()
        node.geometry = box
        node.geometry?.materials = [material]
        node.position = SCNVector3(0, 0.1, -0.5)
        
        // Add a sphere
        let sphere = SCNSphere(radius: 0.2)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIImage(named: "earth.jpg")
        
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        sphereNode.geometry?.materials = [sphereMaterial]
        sphereNode.position = SCNVector3(0.5, 0.1, -1.0)
        
        // scene.rootNode.addChildNode(node) // Add the brick cube
        // scene.rootNode.addChildNode(sphereNode) // Add the earth globe
        
        sceneView.scene = scene

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
//    change color of the box
//    @objc func tapped(recognizer :UIGestureRecognizer) {
//        let sceneView = recognizer.view as! SCNView
//        let touchLocation = recognizer.location(in: sceneView)
//        let hitResults = sceneView.hitTest(touchLocation, options: [:])
//
//        if !hitResults.isEmpty {
//            let node = hitResults[0].node
//            let material = node.geometry?.material(named: "Color")
//
//            material?.diffuse.contents = UIColor.random()
//        }
//    }

    @objc func tapped(recognizer :UIGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)

        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else { return }
            addBox(hitResult :hitResult)
        }
    }
    
    private func addBox(hitResult :ARHitTestResult) {
        let boxGeometry = SCNBox(width: 0.2, height: 0.2, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "brick.jpg")
        boxGeometry.materials = [material]
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
//        boxNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(boxGeometry.height / 2),
//        hitResult.worldTransform.columns.3.z)
        boxNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y + Float(0.5),
                                      hitResult.worldTransform.columns.3.z)
        self.sceneView.scene.rootNode.addChildNode(boxNode)
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !(anchor is ARPlaneAnchor) {
            return
        }

        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
            // Plane detection debug
//        DispatchQueue.main.async {
//            self.label.text = "Plane Found"
//
//            UIView.animate(withDuration: 3.0, animations: {
//                self.label.alpha = 1.0
//            }) {  (completion :Bool) in
//                self.label.alpha = 0.0
//            }
//        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
        }.first
        
        if plane == nil {
            return
        }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
