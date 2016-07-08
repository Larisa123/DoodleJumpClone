//
//  Player.swift
//  DoodleJumpClone
//
//  Created by Lara Carli on 6/21/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import Foundation
import SpriteKit


class Player: SKSpriteNode {
    let maxVelocityY: CGFloat = 900
    var startPositionY: CGFloat!
    //var beforeY: CGFloat!
    
    init(position: CGPoint) {
        let texture = SKTexture(imageNamed: "doodler.png")
        super.init(texture: texture, color: UIColor.blackColor(), size: CGSizeMake(50, 50))
        self.zPosition = Layer.player.rawValue
        self.position = position
        self.startPositionY = position.y
        self.physicsBody = SKPhysicsBody(rectangleOfSize: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.dynamic = true
        self.physicsBody!.restitution = 0
        self.physicsBody?.categoryBitMask = PhysicsCategory.Player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.Brick
        self.physicsBody?.collisionBitMask = PhysicsCategory.None
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.mass = 1
        self.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
    }
    
    func setAtGameOver(inout startHeight: Int, inout playerPosition: CGPoint, scene: GameScene) {
        startHeight = Int(self.position.y)
        playerPosition = CGPointMake(scene.size.width * 0.5, self.position.y + scene.size.height*0.5)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.velocity = CGVectorMake(0, 0)
    }
    
    func regulatePositionX(sceneSize: CGSize) {
        if self.position.x < 0 { self.position.x = sceneSize.width - self.size.width }
        else if self.position.x >= sceneSize.width { self.position.x = 0 }
    }
    
    func shouldRegulatePositionY(scene: SKScene, world: SKNode, bottomSprite: SKSpriteNode) -> Bool {
        if self.position.y > bottomSprite.position.x + 200 {
            world.position.y = -self.position.y + 250
            return true
        }
        return false
    }
    
    func yChangedFor() -> CGFloat {
        return (self.position.y - startPositionY)
    }
    
    func collidedWithBrick(brick: Brick) {
        if self.position.y > brick.position.y {
            self.physicsBody?.velocity.dy = self.maxVelocityY
            animateJump()
        }
    }
    
    func fellDown(world: SKNode, scene: GameScene) -> Bool {
        var result = true
        world.enumerateChildNodesWithName("brick") { node, stop in
            if self.position.y + scene.size.height*0.4 > node.position.y {
                result = false
                stop.memory = true
            }
        }
        return result
    }
    
    func animateJump() {
        //shrink a little on landing
        let shrink = SKAction.scaleYTo(0.6, duration: 0.1)
        self.runAction(shrink)
        //let reverseShrink = SKAction.reversedAction(shrink)
        //self.runAction(reverseShrink())
        
        let toNormal = SKAction.scaleYTo(1, duration: 0.1)
        self.runAction(toNormal)
        //jumping feet:
        let animationFrames = [SKTexture(imageNamed: "doodler.png"), SKTexture(imageNamed: "doodler2.png"), SKTexture(imageNamed: "doodler.png")]
        self.runAction(SKAction.animateWithTextures(animationFrames, timePerFrame: 0.1))
        runAction(SKAction.playSoundFileNamed("blop.wav", waitForCompletion: false))
        
        //scale it out and back:
        /*
        let out = SKAction.scaleYTo(1.4, duration: 0.1)
        self.runAction(out)
        self.runAction(toNormal)*/
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}