import SwiftUI

struct CheckerboardBackground: View {
    let tileSize: CGFloat

    init(tileSize: CGFloat = 20) {
        self.tileSize = tileSize
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let numCols = Int(ceil(size.width / tileSize))
                let numRows = Int(ceil(size.height / tileSize))

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white)) // Optional: Fill background with white first

                for row in 0..<numRows {
                    for col in 0..<numCols {
                        if (row + col) % 2 == 0 { // Alternate colors
                            let rect = CGRect(x: CGFloat(col) * tileSize,
                                              y: CGFloat(row) * tileSize,
                                              width: tileSize,
                                              height: tileSize)
                            context.fill(Path(rect), with: .color(Color.gray.opacity(0.3)))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea() // Allow checkerboard to extend to edges if needed
    }
}

struct CheckerboardBackground_Previews: PreviewProvider {
    static var previews: some View {
        CheckerboardBackground()
            .frame(width: 200, height: 200)
    }
}