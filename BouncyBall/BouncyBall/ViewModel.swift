//
//  ViewModel.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/7/23.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit

let rootEntity = Entity()
var floorEntity = ModelEntity()
var leftHandEntity = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [UnlitMaterial(color: .green)], collisionShape: .generateSphere(radius: 0.02), mass: 100)
var rightHandEntity = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [UnlitMaterial(color: .green)], collisionShape: .generateSphere(radius: 0.02), mass: 100)

@MainActor class ViewModel: ObservableObject {
    @Published var immersionStyle: ImmersionStyle = .mixed
    
    @Published var balls: [ModelEntity] = []
    
    func spawnBall() {
        guard let resource = try? TextureResource.load(named: "BallTexture1") else { return }
        
        var material = UnlitMaterial()
        material.color = .init(texture: .init(resource))
        
        let ballEntity = ModelEntity(mesh: .generateSphere(radius: 0.3), materials: [material], collisionShape: .generateSphere(radius: 0.3), mass: 100)
        
        ballEntity.components[PhysicsBodyComponent.self] = .init(massProperties: .default, material: .default,  mode: .dynamic)
        ballEntity.position = .init(x: 0, y: 5, z: 0)
        ballEntity.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .all)
        ballEntity.generateCollisionShapes(recursive: true)
        rootEntity.addChild(ballEntity)
        balls.append(ballEntity)
    }
    
    func spawnFloor() {
        let material = UnlitMaterial(color: .clear)
        floorEntity = ModelEntity(mesh: .generateBox(width: 30, height: 1, depth: 20), materials: [material], collisionShape: .generateBox(width: 30, height: 1, depth: 20), mass: 100000)
        floorEntity.components[PhysicsBodyComponent.self] = .init(massProperties: .init(mass: 100000), material: .default,  mode: .static)
        
        floorEntity.position = .init(x: 0, y: -0.5, z: 0)
        rootEntity.addChild(floorEntity)
    }
    
    func biggerBalls() {
        for ball in balls {
            
            ball.components[PhysicsBodyComponent.self]?.mode = .kinematic
            ball.scaleUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                ball.components[PhysicsBodyComponent.self]?.mode = .dynamic
            }
        }
    }
    
    func smallerBalls() {
        for ball in balls {
            
            ball.components[PhysicsBodyComponent.self]?.mode = .kinematic
            ball.scaleDown()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                ball.components[PhysicsBodyComponent.self]?.mode = .dynamic
            }
        }
    }
    
    func earthquake() {
        for ball in balls {
            ball.addForce(.init(x: 1000, y: 1000, z: 1000), relativeTo: rootEntity)
        }
    }
}



extension Entity {
    
    func scaleUp() {
        // Get the current transform scale
        let currentScale = transform.scale
        
        // Calculate the new scale by increasing it by 10%
        let newScale = currentScale * 1.2
        
        if let animation = try? AnimationResource.generate(with: FromToByAnimation<Transform>(
            from: transform,
            to: Transform(scale: newScale, rotation: transform.rotation, translation: transform.translation),
            duration: 1.0,
            bindTarget: .transform
        )) {
            playAnimation(animation)
        }
    }
    
    func scaleDown() {
        // Get the current transform scale
        let currentScale = transform.scale
        
        // Calculate the new scale by increasing it by 10%
        let newScale = currentScale * 0.8
        
        if let animation = try? AnimationResource.generate(with: FromToByAnimation<Transform>(
            from: transform,
            to: Transform(scale: newScale, rotation: transform.rotation, translation: transform.translation),
            duration: 1.0,
            bindTarget: .transform
        )) {
            playAnimation(animation)
        }
    }
    
    func animateMaterial(to: UnlitMaterial) {
        // Get the current transform scale
        let currentScale = transform.scale
        
        // Calculate the new scale by increasing it by 10%
        let newScale = currentScale * 0.8
        
        if let animation = try? AnimationResource.generate(with: FromToByAnimation<Material>(
            from: transform,
            to: Transform(scale: newScale, rotation: transform.rotation, translation: transform.translation),
            duration: 1.0,
            bindTarget: .transform
        )) {
            playAnimation(animation)
        }
    }
}
