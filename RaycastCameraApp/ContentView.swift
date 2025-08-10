import SwiftUI
import RealityKit
import ARKit
import Combine

struct ContentView: View {
    @State private var showHelp: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)

            HStack {
                Text("Raycast from camera. Tap to place sphere at hit.")
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Spacer()
                Button(action: { showHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding([.top, .horizontal])
        }
        .sheet(isPresented: $showHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Как это работает")
                    .font(.title2).bold()
                Text("Приложение использует ARKit для построения карты мира. Луч трассируется из центра экрана вперёд. Результат пересечения с плоскостями визуализируется линией; по касанию ставится сфера в точку попадания.")
                Text("Подсказки:")
                    .font(.headline)
                Text("• Перемещайте устройство, чтобы система смогла обнаружить плоскости.\n• При плохой инициализации трассировка может не находить попадания.")
                Spacer()
            }
            .padding()
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.configure(arView: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        private weak var arView: ARView?
        private var rayEntity: Entity?
        private var rayLine: ModelEntity?
        private var cancellables: [Cancellable] = []

        func configure(arView: ARView) {
            self.arView = arView
            arView.automaticallyConfigureSession = false

            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal, .vertical]
            config.environmentTexturing = .automatic
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                config.frameSemantics.insert(.sceneDepth)
            }
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tap)

            // Update ray each frame
            let subscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                self?.updateRayVisualization()
            }
            cancellables.append(subscription)
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let point = gesture.location(in: arView)
            if let result = raycastFromScreenPoint(point, in: arView) {
                placeSphere(at: result.worldTransform.translation, in: arView)
            }
        }

        private func updateRayVisualization() {
            guard let arView else { return }
            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let hit = raycastFromScreenPoint(center, in: arView)

            let cameraTransform = arView.cameraTransform
            let origin = cameraTransform.matrix.translation
            let direction = cameraTransform.matrix.columns.2.xyz * -1

            let endPoint: SIMD3<Float> = {
                if let hit { return hit.worldTransform.translation }
                return origin + direction * 2.0
            }()

            drawOrUpdateLine(from: origin, to: endPoint, color: hit == nil ? .red : .green, in: arView)
        }

        private func raycastFromScreenPoint(_ point: CGPoint, in arView: ARView) -> ARRaycastResult? {
            let query = arView.makeRaycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
            if let query, let result = arView.session.raycast(query).first { return result }
            return nil
        }

        private func drawOrUpdateLine(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor, in arView: ARView) {
            let lineVector = end - start
            let length = simd_length(lineVector)
            guard length > 0.001 else { return }

            let cylinder = MeshResource.generateCylinder(height: length, radius: 0.002, radialSegments: 12)
            let material = SimpleMaterial(color: color, isMetallic: false)
            let lineEntity = ModelEntity(mesh: cylinder, materials: [material])

            let midPoint = (start + end) / 2
            lineEntity.position = midPoint

            let axis = simd_normalize(SIMD3<Float>(0, 1, 0))
            let dir = simd_normalize(lineVector)
            let rotation = simd_quatf(from: axis, to: dir)
            lineEntity.orientation = rotation

            if let existing = rayLine { existing.removeFromParent() }

            if rayEntity == nil {
                let anchor = AnchorEntity(world: .zero)
                rayEntity = anchor
                arView.scene.addAnchor(anchor)
            }
            rayEntity?.addChild(lineEntity)
            rayLine = lineEntity
        }

        private func placeSphere(at position: SIMD3<Float>, in arView: ARView) {
            let mesh = MeshResource.generateSphere(radius: 0.03)
            let material = SimpleMaterial(color: .systemBlue, isMetallic: true)
            let sphere = ModelEntity(mesh: mesh, materials: [material])
            sphere.position = position

            let anchor = AnchorEntity(world: position)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
        }
    }
}

private extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { .init(x, y, z) }
}

private extension simd_float4x4 {
    var translation: SIMD3<Float> { columns.3.xyz }
}