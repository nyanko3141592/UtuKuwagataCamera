//
//  CGSizeCalc.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/16.
//

import Foundation
import CoreGraphics

func +(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

func *(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
}

