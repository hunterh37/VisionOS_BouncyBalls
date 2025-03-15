//
//  ImmersiveView.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/7/23.
//

import Foundation
import SwiftUI
import _RealityKit_SwiftUI

struct ImmersiveView: View {
    var viewModel: ViewModel
    var sceneReconstructionManager = SceneReconstructionManager.shared
    
    @ObservedObject var gestureModel: HandGestureModel
    
    var body: some View {
        RealityView { content in
            content.add(rootEntity)
            content.add(leftHandEntity)
            content.add(rightHandEntity)
            
            viewModel.spawnFloor()
            viewModel.spawnBall()
        }
        .gesture(dragGesture).gesture(rotateGesture)
        
        .task {
            sceneReconstructionManager.generate()
        }.task {
            await gestureModel.start()
        }
        .task {
            await gestureModel.publishHandTrackingUpdates()
        }
        .task {
            await gestureModel.monitorSessionEvents()
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in // When drag begins/changes, set Rigidbody to kinematic
                guard let parent = value.entity.parent else { return }
                value.entity.position = value.convert(value.location3D, from: .local, to: parent)
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic
            }
            .onEnded({ value in // When drag ends, set Rigidbody back to dynamic
                value.entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
            })
    }
    
    var rotateGesture: some Gesture {
        RotateGesture()
            .targetedToAnyEntity()
    }
}
