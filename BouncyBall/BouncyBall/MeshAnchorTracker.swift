//
//  MeshAnchorTracker.swift
//  ImmersiveSpaceTemplate
//
//  Created by Hunter Harris on 11/19/23.
//

import ARKit
import RealityKit
import Combine

class MeshAnchorTracker {
    static var shared = MeshAnchorTracker()
    
    static var anchors: [MeshAnchor] = []
    static var models: [ModelEntity] = []
    
    @MainActor
    func createNewModel(anchor: MeshAnchor) async {
        let entity = ModelEntity()
        entity.name = "\(anchor.id)"
        
        MeshAnchorTracker.addAnchor(anchor: anchor)
        MeshAnchorTracker.addModel(model: entity)
        
        do {
            let shape = try await ShapeResource.generateStaticMesh(from: anchor)
            
            Task { @MainActor in
                //print("MeshAnchorTracker: Successfully generated mesh for scene collision.")
                
                entity.components[PhysicsBodyComponent.self] = .init(
                    massProperties: .default,
                    material: .default,
                    mode: .static)
                entity.components[CollisionComponent.self] = .init(shapes: [shape])
                rootEntity.addChild(entity)
                
                await generateMeshModel(anchor: anchor, entity: entity)
            }
        } catch {
            print("MeshAnchorTracker: Error during createNewModel")
        }
    }
    
    @MainActor
    func updateAnchor(anchor: MeshAnchor) async {
        let index = MeshAnchorTracker.models.firstIndex { $0.name == "\(anchor.id)" }
        guard let index else { return }
        
        // Test: Only update existing anchor if the faces are different
        guard anchor.geometry.faces.count != MeshAnchorTracker.anchors[index].geometry.faces.count else { return }
        
       // print("MeshAnchorTracker: updateAnchor for id: \(anchor.id)")
        await generateMeshModel(anchor: anchor, entity: MeshAnchorTracker.models[index])
    }
    
    @MainActor
    func generateMeshModel(anchor: MeshAnchor, entity: ModelEntity) async {
        do {
          //  print("MeshAnchorTracker: generateMeshModel for id: \(anchor.id)")
            entity.transform = .init(matrix: anchor.originFromAnchorTransform)
            
            let geom = anchor.geometry
            // let classification: MeshAnchor.MeshClassification = anchor.geometry.classificationOf(faceWithIndex: 0)
            var desc = MeshDescriptor()
            let posValues = geom.vertices.asSIMD3(ofType: Float.self)
            desc.positions = .init(posValues)
            let normalValues = geom.normals.asSIMD3(ofType: Float.self)
            desc.normals = .init(normalValues)
            do {
                desc.primitives = .polygons(
                    (0..<geom.faces.count).map { _ in UInt8(geom.faces.primitive.indexCount ) },
                    (0..<geom.faces.count * geom.faces.primitive.indexCount).map {
                        geom.faces.buffer.contents()
                            .advanced(by: $0 * geom.faces.bytesPerIndex)
                            .assumingMemoryBound(to: UInt32.self).pointee
                    }
                )
            }
            
            do {
                let meshResource = try await MeshResource.init(from: [desc])
                entity.components[ModelComponent.self] = ModelComponent(
                    mesh: meshResource,
                    materials: [SceneReconstructionManager.shared.wallMaterial])
                
                entity.components[SceneUnderstandingComponent.self] = .init(entityType: .meshChunk)
                do {
                    let anchorShape: ShapeResource = try await .generateStaticMesh(from: anchor)
                    let collision = CollisionComponent(shapes: [anchorShape], mode: .default)
                    entity.components[CollisionComponent.self] = collision
                } catch {
                    
                }
            }
        } catch {
            print("MeshAnchorTracker: Error during generateMeshModel.")
        }
    }
}

extension MeshAnchorTracker {
    static func addAnchor(anchor: MeshAnchor) {
        if !anchors.contains(where: { $0.id == anchor.id }) {
            anchors.append(anchor)
        }
    }
    static func addModel(model: ModelEntity) {
        if !models.contains(where: { $0.name == model.name }) {
            models.append(model)
        }
    }
}

extension MeshAnchorTracker {
    static func getModel(anchorId: String) -> ModelEntity? {
        if let model = models.first(where: { $0.name == anchorId }) {
            return model
        } else {
            return nil
        }
    }
    static func containsModel(anchorId: String) -> Bool {
        if let _ = models.first(where: { $0.name == anchorId }) {
            return true
        } else {
            return false
        }
    }
    static func getAnchor(anchor: MeshAnchor) -> MeshAnchor? {
        if let anchor = anchors.first(where: { $0.id == anchor.id }) {
            return anchor
        } else {
            return nil
        }
    }
    static func containsAnchor(anchor: MeshAnchor) -> Bool {
        if anchors.first(where: { $0.id == anchor.id }) != nil {
            return true
        } else {
            return false
        }
    }
}



extension GeometrySource {
    func asArray<T>(ofType: T.Type) -> [T] {
        dispatchPrecondition(condition: .onQueue(.main))
        assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
        return (0..<self.count).map {
            buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
        }
    }
    
    // SIMD3 has the same storage as SIMD4.
    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}


// MARK: - Extensions

extension MeshAnchor.Geometry {
    
    func classificationOf(faceWithIndex index: Int) -> MeshAnchor.MeshClassification {
        guard let classification = self.classifications else { return .none }
        assert(classification.format == MTLVertexFormat.uchar, "Expected one unsigned char (one byte) per classification")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = Int(classificationPointer.assumingMemoryBound(to: CUnsignedChar.self).pointee)
        return MeshAnchor.MeshClassification(rawValue: classificationValue) ?? .none
    }
}


extension MeshAnchor {
    var boundingBox: BoundingBox {
        self.geometry.vertices.asSIMD3(ofType: Float.self).reduce(BoundingBox(), { return $0.union($1) })
    }
}

extension Entity {
    func scaleIn() {
        var transformWithZeroScale = transform
        transformWithZeroScale.scale = .zero
        
        if let animation = try? AnimationResource.generate(with: FromToByAnimation<Transform>(
            from: transformWithZeroScale,
            to: transform,
            duration: 1.0,
            bindTarget: .transform
        )) {
            playAnimation(animation)
        }
    }
}
