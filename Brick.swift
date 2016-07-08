//
//  Brick.swift
//  DoodleJumpClone
//
//  Created by Lara Carli on 6/20/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//


import SpriteKit

enum Layer: CGFloat {
    case background
    case bottom
    case brick
    case spring
    case player
    case tapToPlay
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Bottom: UInt32 = 0b1
    static let Brick: UInt32 = 0b10
    static let Spring: UInt32 = 0b100
    static let Player: UInt32 = 0b1000
}

class Brick: SKSpriteNode {
    
    init(position:CGPoint) {
        let texture = SKTexture(imageNamed: "brick.png")
        super.init(texture: texture, color: UIColor.clearColor(), size: CGSizeMake(60, 9))
        self.position = position
        self.name = "brick"
        self.zPosition = Layer.brick.rawValue
        self.physicsBody = SKPhysicsBody(rectangleOfSize: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.dynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.Brick
        self.physicsBody?.contactTestBitMask = PhysicsCategory.Player | PhysicsCategory.Bottom
        self.physicsBody?.collisionBitMask = PhysicsCategory.None
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}