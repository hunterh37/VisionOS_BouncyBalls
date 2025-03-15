//
//  SceneReconstructionManager.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/8/23.
//

import ARKit
import RealityKit
import Combine
import AVKit

class SceneReconstructionManager {
    static var shared = SceneReconstructionManager()
    
    var showModel: Bool = true
    var showParticle: Bool = false
    var wallMaterial: SimpleMaterial = .init()
    
    init () {
        loadWallMaterial()
    }
    
    func loadWallMaterial() {
        wallMaterial.color = .init(tint: .white.withAlphaComponent(1),
                                   texture: .init(try! .load(named: "BallTexture2")))
    }
    
    func setWallMaterial(name: String) {
        wallMaterial.color = .init(tint: .white.withAlphaComponent(1),
                                   texture: .init(try! .load(named: "\(name)")))
    }
    
    func generate() {
        guard SceneReconstructionProvider.isSupported else { return }
        let session = ARKitSession()
        let sceneInfo = SceneReconstructionProvider(modes: [.classification])
        
        Task {
            try await session.run([sceneInfo])
            for await update in sceneInfo.anchorUpdates {
                handleUpdate(update: update)
            }
        }
    }
    
    func regenerate() async {
        for anchor in MeshAnchorTracker.anchors {
            await MeshAnchorTracker.shared.updateAnchor(anchor: anchor)
        }
    }
    
    /// Handle Anchor Updates from SceneReconstructionProvider
    /// since this will be ran continuously, we need to keep track of which anchors we've added and their corresponding ModelEntity
    ///
    /// If we already have an Anchor, update it with the new mesh information
    func handleUpdate(update: AnchorUpdate<MeshAnchor>) {
        _ = Task(priority: .low) {
            if MeshAnchorTracker.containsAnchor(anchor: update.anchor) {
                await MeshAnchorTracker.shared.updateAnchor(anchor: update.anchor)
            } else {
                await MeshAnchorTracker.shared.createNewModel(anchor: update.anchor)
            }
        }
    }
}
