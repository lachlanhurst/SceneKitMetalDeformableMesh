//
//  GameViewController.swift
//  DeformableMesh
//
// Copyright (c) 2015 Lachlan Hurst
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var deformData:DeformData? = nil
    var planeNode:SCNNode? = nil
    var meshData:MetalMeshData!
    
    var deformer:MetalMeshDeformer!
    
    //plane's mesh params
    let length:Float = 70
    let width:Float = 150
    let step:Float = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scnView = self.view as! SCNView
        
        deformer = MetalMeshDeformer(device: scnView.device!)
        
        let scene = SCNScene()
        scnView.scene = scene
        
        newMesh()
        
        let spotLight = SCNLight()
        spotLight.type = SCNLightTypeSpot
        spotLight.color = UIColor.whiteColor()
        spotLight.zNear = 100.0
        spotLight.zFar = 1000.0
        spotLight.castsShadow = true
        spotLight.shadowBias = 5
        spotLight.spotOuterAngle = 55
        spotLight.spotOuterAngle = 75
        let spotLightNode = SCNNode()
        spotLightNode.light = spotLight
        
        var spotLightTransform = SCNMatrix4Identity
        spotLightTransform = SCNMatrix4Translate(spotLightTransform, width/2,-length/2,400)
        spotLightTransform = SCNMatrix4Rotate(spotLightTransform, 60 * Float(M_PI)/180, 0, 1, 0)
        spotLightNode.transform = spotLightTransform
        
        scene.rootNode.addChildNode(spotLightNode)
        
        
        let ambientLight = SCNLight()
        ambientLight.color = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        ambientLight.type = SCNLightTypeAmbient
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        
        scnView.delegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.lightGrayColor()
        scnView.autoenablesDefaultLighting = true
        scnView.playing = true
        
        //scnView.debugOptions = SCNDebugOptions.ShowWireframe

        let tapGesture = UITapGestureRecognizer(target: self, action: "newMesh")
        tapGesture.numberOfTapsRequired = 2
        scnView.addGestureRecognizer(tapGesture)
    }
    
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        
        guard let deformData = self.deformData else {
            return
        }
        
        deformer.deform(meshData, deformData: deformData)
        
        self.deformData = nil
    }
    
    func cameraZaxis(view:SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
    }
    
    var isDeforming = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let scnView = self.view as! SCNView
        
        let p = touches.first!.locationInView(scnView)
        let hitResults = scnView.hitTest(p, options: [SCNHitTestFirstFoundOnlyKey:1])
        isDeforming = hitResults.count > 0
        
        if isDeforming {
            scnView.gestureRecognizers?.forEach {$0.enabled = false}
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let scnView = self.view as! SCNView
        isDeforming = false
        scnView.gestureRecognizers?.forEach {$0.enabled = true}
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let scnView = self.view as! SCNView
        
        let p = touches.first!.locationInView(scnView)
        let hitResults = scnView.hitTest(p, options: [SCNHitTestFirstFoundOnlyKey:1])
        if hitResults.count > 0 && isDeforming {
            
            
            let result = hitResults.first!
            
            let loc = SCNVector3ToFloat3(result.localCoordinates)
            
            let globalDir = self.cameraZaxis(scnView) * -1
            let localDir  = result.node.convertPosition(globalDir, fromNode: nil)
            
            let dir = SCNVector3ToFloat3(localDir)
            
            let dd = DeformData(location:loc, direction:dir, radiusSquared:16.0, deformationAmplitude: 1.5)
            self.deformData = dd

            /*print("coords = ",result.localCoordinates)
            print("normal = ",result.localNormal)
            print("camera axis = ", self.cameraZaxis(scnView))
            print("") */
        }
    }

    func newMesh() {
        let scnView = self.view as! SCNView
        
        meshData = MetalMeshDeformable.buildPlane(scnView.device!, width: width, length: length, step: step)
        let newPlaneNode = SCNNode(geometry: meshData.geometry)
        newPlaneNode.castsShadow = true
        
        var trans = SCNMatrix4Identity
        trans = SCNMatrix4Rotate(trans, Float(M_PI)/2, 1, 0, 0)
        newPlaneNode.transform = trans

        if let existingNode = planeNode {
            scnView.scene?.rootNode.replaceChildNode(existingNode, with: newPlaneNode)
        } else {
            scnView.scene?.rootNode.addChildNode(newPlaneNode)
        }
        planeNode = newPlaneNode
        
    }
    
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
