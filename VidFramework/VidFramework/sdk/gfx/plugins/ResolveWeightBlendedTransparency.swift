//
//  ResolveWeightBlendedTransparency.swift
//  VidEngine
//
//  Created by David Gavilan on 2017/05/29.
//  Copyright © 2017 David Gavilan. All rights reserved.
//

import Foundation
import Metal
import MetalKit

// Weight-blended OIT
class ResolveWeightBlendedTransparency : GraphicPlugin {
    fileprivate var pipelineState: MTLRenderPipelineState! = nil
    
    init(device: MTLDevice, library: MTLLibrary, view: MTKView, gBuffer: GBuffer) {
        super.init(device: device, library: library, view: view)
        
        let fragmentProgram = library.makeFunction(name: "passResolveOIT")!
        let vertexProgram = library.makeFunction(name: "passThrough2DVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        // should be .BGRA8Unorm_sRGB
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = gBuffer.shadedTexture.pixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.sampleCount = view.sampleCount
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    override func draw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer, camera: Camera) {
        let gBuffer = Renderer.shared.gBuffer
        let renderPassDescriptor = Renderer.shared.createRenderPassWithColorAttachmentTexture(gBuffer.shadedTexture, clear: false)
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.label = "Resolve OIT Encoder"
        encoder?.pushDebugGroup("resolveOIT")
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setFragmentTexture(gBuffer.lightTexture, index: 0)
        encoder?.setFragmentTexture(gBuffer.revealTexture, index: 1)
        Renderer.shared.fullScreenQuad.draw(encoder: encoder!)
        encoder?.popDebugGroup()
        encoder?.endEncoding()
    }
}
