//
//  DeformCompute.metal
//  DeformableMesh
//
//  Created by Lachlan Hurst on 23/11/2015.
//  Copyright © 2015 Lachlan Hurst. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DeformData {
    float3 location;
    float3 direction;
    float radiusSquared;
    float deformationAmplitude;
};

kernel void deformVertex(const device float3 *inVerts [[ buffer(0) ]],
                         device float3 *outVerts [[ buffer(1) ]],
                         constant DeformData &deformD [[ buffer(2)]],
                         uint id [[ thread_position_in_grid ]])
{
    const float3 inVert = inVerts[id];
    
    const float3 toVert = inVert - deformD.location;
    const float deformation = deformD.deformationAmplitude * max(0.0, deformD.radiusSquared - length_squared(toVert)) / deformD.radiusSquared;
    
    const float3 outVert = inVert + deformation * deformD.direction;
    outVerts[id] = outVert;
}


kernel void deformNormal(const device float3 *inVerts [[ buffer(0) ]],
                          device float3 *outVerts [[ buffer(1) ]],
                          device float3 *outNormals [[ buffer(2) ]],
                          uint id [[ thread_position_in_grid ]])
{
    
    if (id % 3 == 0) {
        
        const float3 v1 = inVerts[id];
        const float3 v2 = inVerts[id + 1];
        const float3 v3 = inVerts[id + 2];
        
        const float3 v12 = v2 - v1;
        const float3 v13 = v3 - v1;
        
        const float3 normal = fast::normalize(cross(v12, v13));
        
        outVerts[id] = v1;
        outVerts[id + 1] = v2;
        outVerts[id + 2] = v3;
        
        outNormals[id] = normal;
        outNormals[id + 1] = normal;
        outNormals[id + 2] = normal;
    }
}



