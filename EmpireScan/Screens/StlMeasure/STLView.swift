////
////  STLView.swift
////  STL_EDITOR
////
////  Created by MacOK on 16/05/2025.
////
import SwiftUI
import SceneKit

struct STLSceneView: UIViewRepresentable {
    
    var geometry: SCNGeometry
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = .black
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true

        // Add geometry node
        let node = SCNNode(geometry: geometry)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        // Center and scale the model
        let (minVec, maxVec) = geometry.boundingBox

        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)

        let width = maxVec.x - minVec.x
        let height = maxVec.y - minVec.y
        let depth = maxVec.z - minVec.z
        let maxDimension = max(width, height, depth)

        // Avoid division by zero
        let scale = maxDimension > 0 ? 2.0 / maxDimension : 1.0
        node.scale = SCNVector3(scale, scale, scale)
        scene.rootNode.addChildNode(node)

        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: STLSceneView
        var selectedPoints: [SCNVector3] = []
        var actionStack: [[SCNNode]] = []

        init(_ parent: STLSceneView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(undoLast), name: .undoLastAction, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(save), name: .saveAction, object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(location, options: nil)

            if let hit = hits.first {
                let point = hit.worldCoordinates
                selectedPoints.append(point)

                var currentActionNodes: [SCNNode] = []

                // Add point marker
                let sphere = SCNSphere(radius: 0.03)
                sphere.firstMaterial?.diffuse.contents = UIColor.red
                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.position = point
                sceneView.scene?.rootNode.addChildNode(sphereNode)
                currentActionNodes.append(sphereNode)

                if selectedPoints.count == 2 {
                    let lineNode = parent.createLineNode(from: selectedPoints[0], to: selectedPoints[1], color: .green)
                    let labelNode = parent.createDistanceLabel(from: selectedPoints[0], to: selectedPoints[1])

                    sceneView.scene?.rootNode.addChildNode(lineNode)
                    sceneView.scene?.rootNode.addChildNode(labelNode)
                    currentActionNodes.append(contentsOf: [lineNode, labelNode])
                    selectedPoints.removeAll()
                }

                actionStack.append(currentActionNodes)
            }
        }

        @objc func undoLast() {
            guard let lastAction = actionStack.popLast() else { return }
            for node in lastAction {
                node.removeFromParentNode()
            }
        }

        @objc func save() {
            guard let scene = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .windows.first(where: { $0.isKeyWindow })?.rootViewController?.view.subviews.compactMap({ $0 as? SCNView }).first?.scene else {
                print("Scene not found.")
                return
            }

            var triangles: [STLWriter.Triangle] = []

            for node in scene.rootNode.childNodes {
                guard let geometry = node.geometry else { continue }

                let transform = node.worldTransform

                let sources = geometry.sources(for: .vertex)
                let elements = geometry.elements

                guard let vertexSource = sources.first else { continue }

                let vertexStride = vertexSource.dataStride
                let vertexOffset = vertexSource.dataOffset
                let vertexBuffer = vertexSource.data

                let vertexCount = vertexSource.vectorCount

                func vertex(at index: Int) -> SCNVector3 {
                    let byteRange = vertexOffset + index * vertexStride
                    let floatSize = MemoryLayout<Float>.size

                    let x = vertexBuffer.withUnsafeBytes { $0.load(fromByteOffset: byteRange + 0 * floatSize, as: Float.self) }
                    let y = vertexBuffer.withUnsafeBytes { $0.load(fromByteOffset: byteRange + 1 * floatSize, as: Float.self) }
                    let z = vertexBuffer.withUnsafeBytes { $0.load(fromByteOffset: byteRange + 2 * floatSize, as: Float.self) }

                    let local = SCNVector3(x, y, z)
                    let world = node.convertPosition(local, to: nil)
                    return world
                }

                for element in elements {
                    if element.primitiveType != .triangles { continue }

                    let indexCount = element.primitiveCount * 3
                    let indices = element.data.withUnsafeBytes { ptr in
                        return Array(UnsafeBufferPointer(start: ptr.baseAddress!.assumingMemoryBound(to: UInt16.self), count: indexCount))
                    }

                    for i in stride(from: 0, to: indices.count, by: 3) {
                        let v1 = vertex(at: Int(indices[i]))
                        let v2 = vertex(at: Int(indices[i + 1]))
                        let v3 = vertex(at: Int(indices[i + 2]))

                        let normal = (v2 - v1).cross(v3 - v1).normalized()
                        triangles.append(STLWriter.Triangle(normal: normal, v1: v1, v2: v2, v3: v3))
                    }
                }
            }

            // Save to file in documents directory
            let fileName = "EditedModel.stl"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent(fileName)
                do {
                    try STLWriter.writeBinarySTL(triangles: triangles, to: fileURL)
                    print("STL saved to: \(fileURL)")
                } catch {
                    print("Failed to save STL: \(error)")
                }
            }
        }

    }

    func createLineNode(from: SCNVector3, to: SCNVector3, color: UIColor, radius: CGFloat = 0.01) -> SCNNode {
        let vector = to - from
        let height = CGFloat(vector.length())

        // Cylinder grows along Y, so we use it and rotate accordingly
        let cylinder = SCNCylinder(radius: radius, height: height)
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.readsFromDepthBuffer = false // Renders on top

        let node = SCNNode(geometry: cylinder)
        // Position halfway between from and to
        node.position = (from + to) * 0.5
        // Rotate cylinder to align with vector
        node.look(at: to, up: node.worldUp, localFront: SCNVector3(0, 1, 0))
        return node
    }
    
    func createDistanceLabel(from: SCNVector3, to: SCNVector3, color: UIColor = .red) -> SCNNode {
        let distance = (to - from).length()
        let distanceInMm = distance //* 1000.0
        let distanceText = String(format: "%.2f", distanceInMm)

        // Create SCNText
        let textGeometry = SCNText(string: distanceText, extrusionDepth: 0.2)
        textGeometry.firstMaterial?.diffuse.contents = color
        textGeometry.firstMaterial?.readsFromDepthBuffer = false
        textGeometry.firstMaterial?.writesToDepthBuffer = false
        textGeometry.font = UIFont.boldSystemFont(ofSize: 12)
        textGeometry.flatness = 0.2
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        textNode.renderingOrder = 10

        // Compute bounding box of text to size the background
        let (min, max) = textGeometry.boundingBox
        let width = CGFloat(max.x - min.x) * 0.01 + 0.01
        let height = CGFloat(max.y - min.y) * 0.01 + 0.01

        // Background plane behind text
        let background = SCNPlane(width: width, height: height)
        background.cornerRadius = 0.002
        background.firstMaterial?.diffuse.contents = UIColor.black
        background.firstMaterial?.isDoubleSided = true
        background.firstMaterial?.readsFromDepthBuffer = false
        background.firstMaterial?.writesToDepthBuffer = false

        let backgroundNode = SCNNode(geometry: background)
        backgroundNode.position = SCNVector3((min.x + max.x) * 0.005, (min.y + max.y) * 0.005, -0.01)
        backgroundNode.renderingOrder = 9

        // Combine into a parent node
        let parentNode = SCNNode()
        parentNode.addChildNode(backgroundNode)
        parentNode.addChildNode(textNode)

        // Position parent node at midpoint
        let midPoint = (from + to) * 0.5
        parentNode.position = midPoint
        parentNode.constraints = [SCNBillboardConstraint()] // Face the camera

        return parentNode
    }
    
    struct STLWriter {
        struct Triangle {
            var normal: SCNVector3
            var v1: SCNVector3
            var v2: SCNVector3
            var v3: SCNVector3
        }

        static func writeBinarySTL(triangles: [Triangle], to url: URL) throws {
            var data = Data()

            // 80-byte header
            let header = "Generated by STL_EDITOR".padding(toLength: 80, withPad: " ", startingAt: 0)
            data.append(header.data(using: .ascii)!)

            // Number of triangles
            var triangleCount = UInt32(triangles.count)
            data.append(Data(bytes: &triangleCount, count: 4))

            for tri in triangles {
                for vector in [tri.normal, tri.v1, tri.v2, tri.v3] {
                    var x = Float(vector.x), y = Float(vector.y), z = Float(vector.z)
                    data.append(Data(bytes: &x, count: 4))
                    data.append(Data(bytes: &y, count: 4))
                    data.append(Data(bytes: &z, count: 4))
                }
                var attrByteCount: UInt16 = 0
                data.append(Data(bytes: &attrByteCount, count: 2))
            }

            try data.write(to: url)
        }
    }

}

extension SCNVector3 {
    
    func cross(_ vector: SCNVector3) -> SCNVector3 {
            return SCNVector3(
                x: self.y * vector.z - self.z * vector.y,
                y: self.z * vector.x - self.x * vector.z,
                z: self.x * vector.y - self.y * vector.x
            )
        }

        func dot(_ vector: SCNVector3) -> Float {
            return self.x * vector.x + self.y * vector.y + self.z * vector.z
        }


        func normalized() -> SCNVector3 {
            let len = self.length()
            guard len > 0 else { return self }
            return self * (1.0 / len)
        }
    
    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    func length() -> Float {
        return sqrt(x * x + y * y + z * z)
    }
}
