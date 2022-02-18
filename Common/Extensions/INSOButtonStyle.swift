//
//  INSOButtonStyle.swift
//  LacrosseStats
//
//  Created by Jim Dabrowski on 2/16/22.
//  Copyright © 2022 Intangible Software. All rights reserved.
//

import Foundation
import SwiftUI

struct INSOButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .clipShape(Rectangle())
            .foregroundColor(configuration.isPressed ? Color.white : .accentColor)
            .background(configuration.isPressed ? .accentColor : Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.accentColor)
            )
    }
}

