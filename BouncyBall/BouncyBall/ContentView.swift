//
//  ContentView.swift
//  BouncyBall
//
//  Created by Hunter Harris on 10/7/23.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject var viewModel: ViewModel
    
    @State var showImmersiveSpace = false
    @State var spaceActive = false
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        
        VStack {
            Text("Bouncy Ball").font(.extraLargeTitle)
            
            Image("BouncyBall").padding()
            
            HStack {
                Button(action: {
                    if showImmersiveSpace {
                        Task {
                            showImmersiveSpace = false
                            await dismissImmersiveSpace()
                        }
                    } else {
                        Task {
                            showImmersiveSpace = true
                            await openImmersiveSpace(id: "Space")
                        }
                    }
                }, label: {
                    Text(showImmersiveSpace ? "Exit" : "Enter")
                })
            }.padding()
            
            HStack {
                Button(action: {
                    viewModel.biggerBalls()
                }, label: {
                    Image(systemName: "arrowshape.up.fill")
                })
                Button(action: {
                    viewModel.smallerBalls()
                }, label: {
                    Image(systemName: "arrowshape.down.fill")
                })
            }
            
            HStack {
                Button(action: {
                    viewModel.spawnBall()
                }, label: {
                   Text("+1 Ball")
                })
            }.padding()

        }
    }
}

#Preview {
    ContentView(viewModel: .init())
}
