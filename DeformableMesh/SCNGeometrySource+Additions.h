//
//  SCNGeometrySource+Additions.h
//  DeformableMesh
//
//  Created by Simon Wilson on 3/6/18.
//  Copyright © 2018 Simon Wilson. All rights reserved.
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

#import <SceneKit/SceneKit.h>
#import <Metal/Metal.h>

// In iOS 11.4, this function is defined behind the SCN_ENABLE_METAL macro. It defaults to 1, but Swift can't see it, so we don't end up
// with an appropriate Swift version. This extension allows us to properly use this method.
//
// I am not a Swift developer, so I'm not sure if there's a better way to do this, but it works... 
@interface SCNGeometrySource ()
+ (instancetype)geometrySourceWithBuffer:(id <MTLBuffer>)mtlBuffer vertexFormat:(MTLVertexFormat)vertexFormat semantic:(SCNGeometrySourceSemantic)semantic vertexCount:(NSInteger)vertexCount dataOffset:(NSInteger)offset dataStride:(NSInteger)stride API_AVAILABLE(macos(10.11), ios(9.0));
@end
