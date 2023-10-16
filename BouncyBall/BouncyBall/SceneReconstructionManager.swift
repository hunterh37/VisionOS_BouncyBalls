//
//  SceneReconstructionManager.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/8/23.
//

import RealityKit
import ARKit

class SceneReconstructionManager {
    static let shared: SceneReconstructionManager = {
        let manager = SceneReconstructionManager()
        return manager
    }()
    
    var generated: Bool = false
    
    func generate() async {
        guard SceneReconstructionProvider.isSupported else { return }
        let session = ARKitSession()
        let sceneInfo = SceneReconstructionProvider(modes: [.classification])
        
        if SceneReconstructionProvider.isSupported {
            Task {
                try await session.run([sceneInfo])
                
                for await update in sceneInfo.anchorUpdates {
                    handleUpdate(update: update)
                }
            }
        }
    }
    
    func handleUpdate(update: AnchorUpdate<MeshAnchor>) {
        guard !generated else { return }
        _ = Task(priority: .low) {
            do {
                let shape = try await ShapeResource.generateStaticMesh(from: update.anchor)

                // Call synchronous RealityKit methods from the main actor.
                Task { @MainActor in

                    let entity = Entity()
                    entity.components[CollisionComponent.self] = .init(shapes: [shape])
                    entity.components[PhysicsBodyComponent.self] = .init(
                        massProperties: .default,
                        material: .default,
                        mode: .static)
                    rootEntity.addChild(entity)
                    generated = true
                    print("Successfully generated mesh for scene collision.")
                }
            }
        }
    }
}
