//
//  ContentView.swift
//  MeasureAR
//
//  Created by Daniel Magnusson on 1/22/25.
//

import SwiftUI
import RealityKit
import Spatial

struct ContentView : View {
    @State private var lastTap: CGPoint? = nil
    @State private var dragStart: CGPoint? = nil
    @State private var dragEnd: CGPoint? = nil
    
    
    @State private var measureDistance: Float? = nil
    @State private var measureOrigin: SIMD3<Float>? = nil
    
    private let cameraAnchor = AnchorEntity(.camera)
    private let cubeSize: Float = 0.01
    
    var body: some View {
        RealityView { content in
            content.add(cameraAnchor)
            content.camera = .spatialTracking

        } update: { content in
            if let end = dragEnd,
               let endHit = content.hitTest(point: end, in: .global).first,
               let measure = getEntity(named: "Measure", from: content),
               let origin = measureOrigin {
                let endPosition = endHit.position
                let forward = normalize(endPosition - origin)
                let distance = distance(origin, endPosition)
                measure.position = origin + forward * distance/2
                measure.transform.rotation = simd_quatf(Rotation3D(forward: Vector3D(forward)))
                measure.components[ModelComponent.self]?.mesh = .generateBox(size: [cubeSize, cubeSize, distance], cornerRadius: 0.01)
                Task {
                    measureDistance = distance
                }
            } else if let start = dragStart,
                      let startHit = content.hitTest(point: start, in: .global).first {
                
                if let entity = getEntity(named: "Measure", from: content){
                    content.remove(entity)
                }
                
                let startPosition = startHit.position
                let measure = makeCube(named: "Measure", at: startPosition, colored: .white)
                measure.transform.rotation = simd_quatf(Rotation3D(forward: Vector3D(startHit.normal)))
                content.add(measure)
                Task {
                    measureOrigin = measure.position
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture { position in
            lastTap = position
        }
        .gesture(dragGesture)
        .onLongPressGesture {
            
        }
        if let distance = measureDistance {
            if distance >= 1.0 {
                Text("Distance: \(String(format: "%.2f", distance))m")
                    .font(.title2)
            } else if distance >= 0.1 {
                Text("Distance: \(String(format: "%.1f", distance * 100.0))cm")
                    .font(.title2)
            } else {
                Text("Distance: \(String(format: "%.0f", distance * 1000.0))mm")
                    .font(.title2)
            }
        } else {
            Text("Distance: 0m")
                .font(.title2)
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: CoordinateSpace.global)
            .onChanged { drag in
                self.dragStart = drag.startLocation
                self.dragEnd = drag.location
            }
            .onEnded { _ in
                self.dragStart = nil
                self.dragEnd = nil
                self.measureOrigin = nil
            }
    }
    
    func getEntity(named: String, from content: RealityViewCameraContent) -> Entity? {
        return content.entities.first(where: { entity in entity.name == named })
    }

    func makeCube(named name: String, at position: SIMD3<Float>, colored: UIColor) -> Entity {
        let model = Entity()
        model.components.set(ModelComponent(mesh: .generateBox(size: cubeSize, cornerRadius: 0.01),
                                            materials: [SimpleMaterial(color: colored, isMetallic: false)]))
        model.position = position
        model.name = name
        return model
    }
}

#Preview {
    ContentView()
}
