//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(UIKit)

import UIKit

public typealias PlatformColor = UIColor

#elseif canImport(AppKit)

import AppKit

public typealias PlatformColor = NSColor

#endif
