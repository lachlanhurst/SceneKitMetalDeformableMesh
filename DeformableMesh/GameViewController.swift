//
//  GameViewController.swift
//  DeformableMesh
//
//  Created by Lachlan Hurst on 22/11/2015.
//  Copyright (c) 2015 Lachlan Hurst. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        deformer = MetalMeshDeformer(device: device)
        
        let scene = SCNScene()
        
        meshData = MetalMeshDeformable.buildPlane(device)
        let planeNode = SCNNode(geometry: meshData.geometry)
        
        var trans = SCNMatrix4Identity
        trans = SCNMatrix4Rotate(trans, Float(M_PI)/2, 1, 0, 0)
        planeNode.transform = trans
        
        scene.rootNode.addChildNode(planeNode)
        
        let scnView = self.view as! SCNView
        scnView.delegate = self
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.lightGrayColor()
        scnView.autoenablesDefaultLighting = true
        scnView.playing = true
        
        //scnView.debugOptions = SCNDebugOptions.ShowWireframe

    }
    
    var deformData:DeformData? = nil
    var meshData:MetalMeshData!
    
    var deformer:MetalMeshDeformer!
    
    var device:MTLDevice!
    var threadsPerGroup:MTLSize!
    var numThreadgroups: MTLSize!
    var pipelineState: MTLComputePipelineState!
    var defaultLibrary: MTLLibrary! = nil
    var commandQueue: MTLCommandQueue! = nil
    
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        
        guard let deformData = self.deformData else {
            return
        }
        
        
        deformer.deform(meshData, deformData: deformData)
        
        
        self.deformData = nil
    }
    
    
    func setupMetal() {
        let scnView = self.view as! SCNView
        device = scnView.device
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
