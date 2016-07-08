//
//  GameScene.swift
//  DoodleJumpClone
//
//  Created by Lara Carli on 6/20/16.
//  Copyright (c) 2016 Larisa Carli. All rights reserved.
//

func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
}
func random(min min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
}

import SpriteKit
import CoreMotion

enum GameState {
    case Start
    case Play
    case waitingForThePlayerToFall
    case GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: Player!
    var world: SKNode!
    var bottomSprite = SKSpriteNode()
    var gameState = GameState.Start
    var score = 0
    var startHeight = 0
    var level = 1
    var label = UILabel(frame: CGRectMake(0, 0, 200, 21))
    let brickWidth = Brick(position: CGPointZero).size.width
    let manager = CMMotionManager()
    var playerPosition = CGPointZero
    let playerHeight: CGFloat = 50
    let tapToStart = SKSpriteNode(imageNamed: "TapToStart.png")
    
    override func didMoveToView(view: SKView) {
        self.physicsWorld.contactDelegate = self
        backgroundColor = SKColor.whiteColor()
        playerPosition = CGPointMake(size.width*0.5, size.height*0.4)
        
        // CoreMotion
        manager.startAccelerometerUpdates()
        manager.accelerometerUpdateInterval = 0.1
        manager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {(data, error) in
            self.physicsWorld.gravity = CGVectorMake(CGFloat((data?.acceleration.x)!*1.5), -9.8)
        }
        
        setupBackground()
        world = SKNode()
        addChild(world)
        player = Player(position: playerPosition)
        world.addChild(player)
        view.addSubview(setupLabel())
        setupBottomSprite()
        setBestScore(0)
        setupTapToStart()
    }
    
    func setupLabel() -> UILabel {
        label.center = CGPointMake(size.width/2, 20)
        label.textAlignment = NSTextAlignment.Center
        label.text = "Score: \(score)"
        label.hidden = true
        
        return label
    }
    
    func setupBottomSprite() {
        //when collision between bottom and brick occours, the brick is removed
        bottomSprite.position = CGPointMake(0, 0)
        bottomSprite.size = CGSizeMake(size.width, 2)
        bottomSprite.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(size.width, 2))
        bottomSprite.physicsBody?.dynamic = false
        bottomSprite.physicsBody?.categoryBitMask = PhysicsCategory.Bottom
        bottomSprite.physicsBody?.contactTestBitMask = PhysicsCategory.Brick
        bottomSprite.physicsBody?.collisionBitMask = PhysicsCategory.None
        bottomSprite.physicsBody?.usesPreciseCollisionDetection = true
        world.addChild(bottomSprite)
    }
    
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "light-blue.png")
        background.anchorPoint = CGPointMake(0, 0)
        background.size = self.size
        background.alpha = 0
        addChild(background)
    }
    
    func setupAtNewGame() {
        //the brick under the player:
        let brickUnderPlayer = Brick(position: CGPointMake(player.position.x + 20, player.position.y - 20))
        world.addChild(brickUnderPlayer)
        
        //bricks
        for i in 0...30 {
            let randomX = random(min: 0, max: size.width - brickWidth)
            let y = playerPosition.y - 100 + CGFloat(i) * 30
            let brick = Brick(position: CGPointMake(randomX, y))
            world.addChild(brick)
        }
        //score
        score = 0
        label.hidden = false
    }
    
    func setupTapToStart() {
        gameState = .Start
        tapToStart.size = CGSizeMake(115, 95)
        tapToStart.position = CGPointMake(playerPosition.x, playerPosition.y + playerHeight + 35)
        tapToStart.zPosition = Layer.tapToPlay.rawValue
        world.addChild(tapToStart)
    }
    
    func numberBasedOnLevel() -> Int {
        switch score {
        case  0 ..< 2500:
            level = 1
            return 9
        case  0 ..< 6000:
            level = 2
            return 8
        case  0 ..< 12000:
            level = 3
            return 7
        case  0 ..< 30000:
            level = 4
            return 6
        default:
            level = 5
            return 5 //very hard (after level 4)
        }
    }
    
    func gameOver() {
        gameState = .GameOver
        takeCareOfScoring()
        player.setAtGameOver(&startHeight, playerPosition: &playerPosition, scene: self)
        removeAllBricks()
        setupTapToStart()
    }
    
    func newGame() {
        setupAtNewGame()
        gameState = .Play
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.velocity = CGVectorMake(0, player.maxVelocityY)
        tapToStart.removeFromParent()
    }
    
    func letPlayerFall() {
        gameState = .waitingForThePlayerToFall
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            if gameState == .Start {
                let playSound = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false)
                let playNewGame = SKAction.runBlock(newGame)
                runAction(SKAction.sequence([playSound, playNewGame]))
                
            } else if gameState == .Play {
                if location.x + 30 < player.position.x { player.physicsBody?.applyImpulse(CGVectorMake(-50, 0)) }
                else if location.x - 30 > player.position.x { player.physicsBody?.applyImpulse  (CGVectorMake(50, 0))}
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.Brick && contact.bodyB.categoryBitMask == PhysicsCategory.Player {
            player.collidedWithBrick(contact.bodyA.node as! Brick)
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.Player && contact.bodyB.categoryBitMask == PhysicsCategory.Brick  {
            player.collidedWithBrick(contact.bodyB.node as! Brick)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        if gameState == .Play {
            if player.shouldRegulatePositionY(self, world: world, bottomSprite: bottomSprite) && countAllBricks() < numberBasedOnLevel() + 8 {addNewBricks()}
            player.regulatePositionX(size)
            removeBricksOutOfBounds()
            if player.fellDown(world, scene: self) {gameOver()}
            
            let currentScore = Int(player.position.y) - startHeight
            if currentScore > score {
                score = Int(Double(currentScore)*Double(level)/2)
                label.text = "Score: \(score)"
            }
        } else if gameState == .waitingForThePlayerToFall {
            player.regulatePositionX(size)
            if !self.intersectsNode(player) {gameOver()}
        }
    }
    
    // Brick functions:
    
    func addNewBricks() {
        for i in 0...numberBasedOnLevel() {
            let randomX = random(min: 20, max: size.width - brickWidth)
            let y = player.position.y + CGFloat(i) * 30 + 300
            let position = CGPointMake(randomX, y)
            let brick = Brick(position: position)
            world.addChild(brick)
        }
    }
    
    func countAllBricks() -> Int {
        var counter = 0
        world.enumerateChildNodesWithName("brick") { node, _ in
            counter = counter + 1
        }
        return counter
    }
    
    func removeBricksOutOfBounds() {
        world.enumerateChildNodesWithName("brick") {node, stop in
            if (node.position.y < self.player.position.y - self.size.height*0.5) {
                node.removeFromParent()
            }
        }
    }
    
    func removeAllBricks() {
        world.enumerateChildNodesWithName("brick") {node, stop in
            node.removeFromParent()
        }
    }
    
    // Scoring:
    
    func takeCareOfScoring() {
        if score > bestScore() {
            setBestScore(score)
            label.text = "New High Score: \(score)!"
        } else {label.text = "Game Over! Score: \(score)"}
    }
    
    func bestScore() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("BestScore")
    }
    
    func setBestScore(bestScore: Int) {
        NSUserDefaults.standardUserDefaults().setInteger(bestScore, forKey: "BestScore")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}