////
////  STLParser.swift
////  STL_EDITOR
////
////  Created by MacOK on 16/05/2025.
////
import Foundation
import SceneKit

struct Triangle {
    let normal: SIMD3<Float>
    let vertices: [SIMD3<Float>] // 3 vertices per triangle
}

class STLParser {
    static func loadBinarySTL(from url: URL) -> [Triangle]? {
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to load data from \(url)")
            return nil
        }
        
        guard data.count > 84 else {
            print("Invalid STL file size")
            return nil
        }
        
        let triangleCount = Int(data.subdata(in: 80..<84).withUnsafeBytes { $0.load(as: UInt32.self) })
        var triangles: [Triangle] = []
        var offset = 84
        
        for _ in 0..<triangleCount {
            guard offset + 50 <= data.count else { break }
            let normal = data.subdata(in: offset..<offset+12).withUnsafeBytes {
                SIMD3<Float>($0.load(fromByteOffset: 0, as: Float.self),
                             $0.load(fromByteOffset: 4, as: Float.self),
                             $0.load(fromByteOffset: 8, as: Float.self))
            }
            offset += 12
            
            var vertices: [SIMD3<Float>] = []
            for _ in 0..<3 {
                let vertex = data.subdata(in: offset..<offset+12).withUnsafeBytes {
                    SIMD3<Float>($0.load(fromByteOffset: 0, as: Float.self),
                                 $0.load(fromByteOffset: 4, as: Float.self),
                                 $0.load(fromByteOffset: 8, as: Float.self))
                }
                vertices.append(vertex)
                offset += 12
            }
            
            offset += 2 // skip attribute byte count
            triangles.append(Triangle(normal: normal, vertices: vertices))
        }
        
        return triangles
    }
    
    static func buildGeometry(from triangles: [Triangle]) -> SCNGeometry {
        var allVertices: [SIMD3<Float>] = []
        var indices: [Int32] = []
        var currentIndex: Int32 = 0
        
        for triangle in triangles {
            for vertex in triangle.vertices {
                allVertices.append(vertex)
                indices.append(currentIndex)
                currentIndex += 1
            }
        }
        
        let vertexSource = SCNGeometrySource(vertices: allVertices.map { SCNVector3($0.x, $0.y, $0.z) })
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: indices.count / 3,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
