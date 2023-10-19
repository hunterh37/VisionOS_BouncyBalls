//
//  HandGestureModel.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/8/23.
//

#if targetEnvironment(simulator)
import ARKit
#else
@preconcurrency import ARKit
#endif
import RealityKit
import SwiftUI


/// **HandGesture Tracking is currently not available on VisionOS Simulator
@MainActor
enum HandGestureModelContainer {
    private(set) static var handGestureModel = HandGestureModel()
}


@MainActor
class HandGestureModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {

        configureHandCollision()
        
        do {
            if HandTrackingProvider.isSupported {
                print("ARKitSession starting.")
                try await session.run([handTracking])
            } else {
                print("not running ARKitSession, not supported")
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .added:
                let anchor = update.anchor
                // Publish updates only if the hand and the relevant joints are tracked.
                guard anchor.isTracked else { continue }
               
            case .updated:
                let anchor = update.anchor
                
                guard anchor.isTracked else { continue }
                
                if anchor.chirality == .left {
                    latestHandTracking.left = anchor
                    leftHandEntity.position = anchor.originFromAnchorTransform.translation
                } else if anchor.chirality == .right {
                    latestHandTracking.right = anchor
                    rightHandEntity.position = anchor.originFromAnchorTransform.translation
                }
                
            default:
                break
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Stop the game, ask the user to grant hand tracking authorization again in Settings.
                }
            case .dataProviderStateChanged(dataProviders: let dataProviders, newState: let newState, error: _):
                print("Data provide state changed: \(dataProviders.count) - \(newState.description)")
            @unknown default:
                print("Session event \(event)")
            }
        }
    }
}


extension HandGestureModel {
    private func configureHandCollision() {
        leftHandEntity.generateCollisionShapes(recursive: true)
        leftHandEntity.components[PhysicsBodyComponent.self] = .init(
            massProperties: .default, material: nil,  mode: .kinematic)
        
        rightHandEntity.generateCollisionShapes(recursive: true)
        rightHandEntity.components[PhysicsBodyComponent.self] = .init(
            massProperties: .default, material: nil,  mode: .kinematic)
    }
}


/// Extension for float4x4 -> SIMD3 translation
extension float4x4 {
    var translation: SIMD3<Float> {
        SIMD3(columns.3.x, columns.3.y, columns.3.z)
    }
    init(translation vector: SIMD3<Float>) {
        self.init(.init(1, 0, 0, 0),
                  .init(0, 1, 0, 0),
                  .init(0, 0, 1, 0),
                  .init(vector.x, vector.y, vector.z, 1))
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
}

