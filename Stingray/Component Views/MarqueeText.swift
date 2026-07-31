//
//  MarqueeText.swift
//  Stingray
//
//  Created by Ben Roberts on 7/30/26.
//

import SwiftUI

public struct MarqueeText: View {
    @State private var textWidth: CGFloat = .zero
    @State private var textHeight: CGFloat = 20
    @State private var separatorWidth: CGFloat = 20
    @State private var containerWidth: CGFloat = .greatestFiniteMagnitude
    @State private var animating: Bool = false
    private var doesOverflow: Bool { self.containerWidth - self.textWidth < 0 }

    private let duration: Double = 6
    private let delay: Double = 0
    private let text: String
    private let animate: Bool
    private let font: Font?

    /// Horizontally scrolling text when text cannot fit
    /// - Parameters:
    ///   - text: Text to display
    ///   - animate: Whether or not to animate the text or simply truncate it
    ///   - font: How the text is displayed
    public init(text: String, animate: Bool, font: Font?) {
        self.text = text
        self.animate = animate
        self.font = font
    }

    public var body: some View {
        GeometryReader { containerGeo in
            if self.doesOverflow && self.animate { // Long scrolling text
                Text(String(repeating: self.text + " • ", count: 3))
                    .font(self.font)
                    .fixedSize()
                    .offset(x: self.animating ? -(self.textWidth + self.separatorWidth) * 2 : -(self.textWidth + self.separatorWidth))
                    .onAppear { self.animating = true }
                    .onDisappear { self.animating = false }
                    .animation(
                        self.animating
                        ? Animation.linear(duration: self.duration)
                            .delay(self.delay)
                            .repeatForever(autoreverses: false)
                        : .default,
                        value: self.animating
                    )
            }
            else { // Short static text
                ZStack {
                    Text(self.text) // Only used for calculations
                        .font(self.font)
                        .lineLimit(1)
                        .fixedSize()
                        .background {
                            GeometryReader { textGeo in
                                Color.clear
                                    .onAppear {
                                        self.containerWidth = containerGeo.size.width
                                        self.textWidth = textGeo.size.width
                                        self.textHeight = textGeo.size.height
                                    }
                            }
                        }
                        .frame(width: self.containerWidth, alignment: .leading)
                        .hidden()
                    Text(" • ") // Has to be calculated separately from base text since base text determines if need to animate
                        .font(self.font)
                        .lineLimit(1)
                        .fixedSize()
                        .background {
                            GeometryReader { separatorGeo in
                                Color.clear
                                    .onAppear { self.separatorWidth = separatorGeo.size.width }
                            }
                        }
                        .frame(width: self.containerWidth, alignment: .leading)
                        .hidden()
                    Text(self.text) // Actual text
                        .lineLimit(1)
                        .font(self.font)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(height: self.textHeight)
        .clipped()
    }
}
