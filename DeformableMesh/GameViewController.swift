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

import Metal
import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var deformData:DeformData? = nil
    var planeNode:SCNNode? = nil
    var meshData:MetalMeshData!

    var device:MTLDevice!

    var deformer:MetalMeshDeformer!
    
    //plane's mesh params
    let length:Float = 70
    let width:Float = 150
    let step:Float = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scnView = self.view as! SCNView

        device = MTLCreateSystemDefaultDevice()
        deformer = MetalMeshDeformer(device: device)
        
        let scene = SCNScene()
        scnView.scene = scene
        
        newMesh()
        
        let spotLight = SCNLight()
        spotLight.type = SCNLight.LightType.spot
        spotLight.color = UIColor.white
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
        spotLightTransform = SCNMatrix4Rotate(spotLightTransform, 60 * Float.pi/180, 0, 1, 0)
        spotLightNode.transform = spotLightTransform
        
        scene.rootNode.addChildNode(spotLightNode)
        
        
        let ambientLight = SCNLight()
        ambientLight.color = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        ambientLight.type = SCNLight.LightType.ambient
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        
        scnView.delegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.lightGray
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
        
        //scnView.debugOptions = SCNDebugOptions.ShowWireframe

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameViewController.newMesh))
        tapGesture.numberOfTapsRequired = 2
        scnView.addGestureRecognizer(tapGesture)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        guard let deformData = self.deformData else {
            return
        }
        
        deformer.deform(meshData, deformData: deformData)
        
        self.deformData = nil
    }
    
    func cameraZaxis(_ view:SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
    }
    
    var isDeforming = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scnView = self.view as! SCNView
        
        let p = touches.first!.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [SCNHitTestOption.firstFoundOnly:1])
        isDeforming = hitResults.count > 0
        
        if isDeforming {
            scnView.gestureRecognizers?.forEach {$0.isEnabled = false}
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let scnView = self.view as! SCNView
        isDeforming = false
        scnView.gestureRecognizers?.forEach {$0.isEnabled = true}
        
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scnView = self.view as! SCNView
        
        let p = touches.first!.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [SCNHitTestOption.firstFoundOnly:1])
        if hitResults.count > 0 && isDeforming {
            
            
            let result = hitResults.first!
            
//            let loc = SCNVector3ToFloat3(result.localCoordinates)
			let loc = float3.init(result.localCoordinates)
			
            let globalDir = self.cameraZaxis(scnView) * -1
            let localDir  = result.node.convertPosition(globalDir, from: nil)
            
//            let dir = SCNVector3ToFloat3(localDir)
			let dir = float3.init(localDir)
			
            let dd = DeformData(location:loc, direction:dir, radiusSquared:16.0, deformationAmplitude: 1.5, pad1: 0, pad2: 0)
            self.deformData = dd

            /*print("coords = ",result.localCoordinates)
            print("normal = ",result.localNormal)
            print("camera axis = ", self.cameraZaxis(scnView))
            print("") */
        }
    }

    @objc func newMesh() {
        let scnView = self.view as! SCNView
        
        meshData = MetalMeshDeformable.buildPlane(device, width: width, length: length, step: step)
        let newPlaneNode = SCNNode(geometry: meshData.geometry)
        newPlaneNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "texture")
        newPlaneNode.castsShadow = true
        
        var trans = SCNMatrix4Identity
        trans = SCNMatrix4Rotate(trans, Float.pi/2, 1, 0, 0)
        newPlaneNode.transform = trans

        if let existingNode = planeNode {
            scnView.scene?.rootNode.replaceChildNode(existingNode, with: newPlaneNode)
        } else {
            scnView.scene?.rootNode.addChildNode(newPlaneNode)
        }
        planeNode = newPlaneNode
        
    }
    
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
