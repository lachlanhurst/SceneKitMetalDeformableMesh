//
//  MetalMeshDeformable.swift
//  DeformableMesh
//
//  Created by Lachlan Hurst on 22/11/2015.
//  Copyright © 2015 Lachlan Hurst. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

struct DeformData {
    var location:vector_float3
    var direction:vector_float3
    var radiusSquared:Float32
    var deformationAmplitude:Float32
}


class MetalMeshData {
    
    var geometry:SCNGeometry
    var vertexBuffer1:MTLBuffer
    var vertexBuffer2:MTLBuffer
    var normalBuffer:MTLBuffer
    var vertexCount:Int
    
    init(
        geometry:SCNGeometry,
        vertexCount:Int,
        vertexBuffer1:MTLBuffer,
        vertexBuffer2:MTLBuffer,
        normalBuffer:MTLBuffer) {
        self.geometry = geometry
        self.vertexCount = vertexCount
        self.vertexBuffer1 = vertexBuffer1
        self.vertexBuffer2 = vertexBuffer2
        self.normalBuffer = normalBuffer
    }
    
}

class MetalMeshDeformer {
    let device:MTLDevice
    
    var commandQueue:MTLCommandQueue!
    var defaultLibrary:MTLLibrary!
    var functionVertex:MTLFunction!
    var functionNormal:MTLFunction!
    var pipelineStateVertex: MTLComputePipelineState!
    var pipelineStateNormal: MTLComputePipelineState!
    
    init(device:MTLDevice) {
        self.device = device
        setupMetal()
    }

    func setupMetal() {
        commandQueue = device.newCommandQueue()
        
        defaultLibrary = device.newDefaultLibrary()
        functionVertex = defaultLibrary.newFunctionWithName("deformVertex")
        functionNormal = defaultLibrary.newFunctionWithName("deformNormal")
        
        do {
            pipelineStateVertex = try! device.newComputePipelineStateWithFunction(functionVertex)
            pipelineStateNormal = try! device.newComputePipelineStateWithFunction(functionNormal)
        }
    }
    
    func getBestThreadCount(count:Int) -> Int {
        
        if (count % 30 == 0) {
            return 30
        } else if (count % 27 == 0) {
            return 27
        } else if (count % 24 == 0) {
            return 24
        } else if (count % 21 == 0) {
            return 21
        } else if (count % 18 == 0) {
            return 18
        } else if (count % 15 == 0) {
            return 15
        } else if (count % 12 == 0) {
            return 12
        } else if (count % 9 == 0) {
            return 9
        } else if (count % 6 == 0) {
            return 6
        } else {
            return 3
        }
    }
    
    func deform(mesh:MetalMeshData, var deformData:DeformData) {
        let computeCommandBuffer = commandQueue.commandBuffer()
        let computeCommandEncoder = computeCommandBuffer.computeCommandEncoder()
        
        computeCommandEncoder.setComputePipelineState(pipelineStateVertex)

        computeCommandEncoder.setBuffer(mesh.vertexBuffer1, offset: 0, atIndex: 0)
        computeCommandEncoder.setBuffer(mesh.vertexBuffer2, offset: 0, atIndex: 1)
        
        computeCommandEncoder.setBytes(&deformData, length: sizeof(DeformData), atIndex: 2)
        
        let count = mesh.vertexCount
        let threadExecutionWidth = pipelineStateVertex.threadExecutionWidth
        let threadsPerGroup = MTLSize(width:threadExecutionWidth,height:1,depth:1)
        let ntg = Int(ceil(Float(count)/Float(threadExecutionWidth)))
        let numThreadgroups = MTLSize(width: ntg, height:1, depth:1)
        
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        computeCommandBuffer.commit()

        //computeCommandBuffer.waitUntilScheduled()
        
        /*
        let blitCommandBuffer = commandQueue.commandBuffer()
        
        let bufferSize = count * sizeof(vector_float3)
        let blitEncoder = blitCommandBuffer.blitCommandEncoder()
        blitEncoder.copyFromBuffer(mesh.vertexBuffer2, sourceOffset: 0, toBuffer: mesh.vertexBuffer1, destinationOffset: 0, size: bufferSize)
        blitEncoder.endEncoding()
        blitCommandBuffer.commit()
        */
        
        
        let normalComputeCommandBuffer = commandQueue.commandBuffer()
        let normalComputeCommandEncoder = normalComputeCommandBuffer.computeCommandEncoder()
        
        normalComputeCommandEncoder.setComputePipelineState(pipelineStateNormal)
        
        normalComputeCommandEncoder.setBuffer(mesh.vertexBuffer2, offset: 0, atIndex: 0)
        normalComputeCommandEncoder.setBuffer(mesh.vertexBuffer1, offset: 0, atIndex: 1)
        
        normalComputeCommandEncoder.setBuffer(mesh.normalBuffer, offset: 0, atIndex: 2)
        
        var maxThreads = pipelineStateNormal.threadExecutionWidth - pipelineStateNormal.threadExecutionWidth % 3
        maxThreads = min(mesh.vertexCount, maxThreads)
        
        let bestThreadsPerGroup = getBestThreadCount(mesh.vertexCount)
        let groupCount = mesh.vertexCount / bestThreadsPerGroup
        
        normalComputeCommandEncoder.dispatchThreadgroups(MTLSizeMake(groupCount,1,1), threadsPerThreadgroup: MTLSizeMake(bestThreadsPerGroup, 1, 1))
        normalComputeCommandEncoder.endEncoding()
        normalComputeCommandBuffer.commit()
        
        /*
        //debug info
        normalComputeCommandBuffer.waitUntilCompleted()
        
        let bufferSize = count * sizeof(vector_float3)
        var data = NSData(bytesNoCopy: mesh.normalBuffer.contents(), length: bufferSize, freeWhenDone: false)
        
        var resultArray = [vector_float3](count: count, repeatedValue: vector_float3(0,0,0))
        data.getBytes(&resultArray, length:bufferSize)
        
        for b in resultArray {
            print("pos: ", b.x,", " , b.y, ", ", b.z)
        }
        
        print("")
        */
    }
    
}



class MetalMeshDeformable {
    
    class func buildPlane(device:MTLDevice) -> MetalMeshData {
        
        var pointsList: [vector_float3] = []
        var normalsList: [vector_float3] = []
        var indexList: [CInt] = []
        
        let length:Float = 70
        let width:Float = 150
        let step:Float = 1
        
        let normal = vector_float3(0, 1, 0)
        
        var zPrevious:Float? = nil
        for var z:Float = 0; z <= length; z=z+step {
            
            var xPrevious:Float? = nil
            for var x:Float = 0; x <= width; x=x+step {
                
                if let xPrevious = xPrevious, zPrevious = zPrevious {
                    
                    let p0 = vector_float3(xPrevious, 0, zPrevious)
                    let p1 = vector_float3(xPrevious, 0, z)
                    let p2 = vector_float3(x, 0, z)
                    let p3 = vector_float3(x, 0, zPrevious)
                    
                    pointsList.append(p0)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p1)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p2)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                    
                    
                    
                    pointsList.append(p0)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p2)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                    
                    pointsList.append(p3)
                    normalsList.append(normal)
                    indexList.append(CInt(indexList.count))
                }
                
                xPrevious = x
            }
            
            zPrevious = z
        }
        
        let vertexFormat = MTLVertexFormat.Float3
        let vertexBuffer1 = device.newBufferWithBytes(&pointsList, length: pointsList.count * sizeof(vector_float3), options: .OptionCPUCacheModeDefault)
        let vertexBuffer2 = device.newBufferWithBytes(&pointsList, length: pointsList.count * sizeof(vector_float3), options: .OptionCPUCacheModeDefault)
        
        let vertexSource = SCNGeometrySource(
            buffer: vertexBuffer1,
            vertexFormat: vertexFormat,
            semantic: SCNGeometrySourceSemanticVertex,
            vertexCount: pointsList.count,
            dataOffset: 0,
            dataStride: sizeof(vector_float3))
        
        let normalFormat = MTLVertexFormat.Float3
        let normalBuffer = device.newBufferWithBytes(&normalsList, length: normalsList.count * sizeof(vector_float3), options: .OptionCPUCacheModeDefault)

        let normalSource = SCNGeometrySource(
            buffer: normalBuffer,
            vertexFormat: normalFormat,
            semantic: SCNGeometrySourceSemanticNormal,
            vertexCount: normalsList.count,
            dataOffset: 0,
            dataStride: sizeof(vector_float3))
        
        let indexData  = NSData(bytes: indexList, length: sizeof(CInt) * indexList.count)
        let indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.Triangles,
            primitiveCount: indexList.count/3,
            bytesPerIndex: sizeof(CInt)
        )
        
        let geo = SCNGeometry(sources: [vertexSource,normalSource], elements: [indexElement])
        geo.firstMaterial?.litPerPixel = false
        
        return MetalMeshData(
            geometry: geo,
            vertexCount: pointsList.count,
            vertexBuffer1: vertexBuffer1,
            vertexBuffer2: vertexBuffer2,
            normalBuffer: normalBuffer)
    }

}
