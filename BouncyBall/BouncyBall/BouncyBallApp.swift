//
//  BouncyBallApp.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/7/23.
//

import SwiftUI

@main
struct BouncyBallApp: App {
    @StateObject var viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }.defaultSize(CGSize(width: 400, height: 600))
        
        ImmersiveSpace(id: "Space") {
            ImmersiveView(viewModel: viewModel, gestureModel: HandGestureModelContainer.handGestureModel)
        }.immersionStyle(selection: $viewModel.immersionStyle, in: .full, .mixed)
    }
}
