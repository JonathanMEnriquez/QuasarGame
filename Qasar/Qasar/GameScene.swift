//
//  GameScene.swift
//  Qasar
//
//  Created by user on 1/11/18.
//  Copyright © 2018 tresAmigos. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import CoreMotion


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var player = AVPlayer()
    var Bplayer = AVPlayer()
    var blastVideoNode = SKSpriteNode()
    var motionManager : CMMotionManager?
    let alienCategory:UInt32 = 0x1 << 1
    let laserCategory:UInt32 = 0x1 << 0
    let userCategory:UInt32 = 0x1 << 2
    var user: SKSpriteNode?
    var gameTimer: Timer?
    var shotTimer: Timer?
    var blastTimer: Timer?
    var shot = 0
    var score = SKLabelNode(text: "0")
    var userShot = SKSpriteNode()
    

    

    
    override func sceneDidLoad() {
        self.physicsWorld.contactDelegate = self
        
        self.lastUpdateTime = 0
        score.position.x = 0.0
        score.position.y = -300.0
        score.fontSize = 200.0
        score.fontColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        score.zPosition = 4.0
        self.addChild(score)
        user = SKSpriteNode(imageNamed: "spaceship0000")
        user?.position = CGPoint(x: 0, y: 0)
        user?.scale(to: CGSize(width: (user?.size.width)! / 4, height: (user?.size.height)! / 4))
        
        // Set User Physics
        
        user?.physicsBody = SKPhysicsBody(rectangleOf: (user?.size)!)
        user?.physicsBody?.isDynamic = false
        
        user?.physicsBody?.categoryBitMask = userCategory
//        user?.physicsBody?.contactTestBitMask = laserCategory
        user?.physicsBody?.collisionBitMask = 2
        user?.zPosition = 1.0
        
        self.addChild(user!)
        
        let torpedoNode = SKSpriteNode(imageNamed: "laser3_0030")
        
        
        //Assigning instance of MotionManager to variable
        motionManager = CMMotionManager()
        
        //Safely unwrapping and accessing manager
        if let manager = motionManager {
            print("We have our manager")
            
            //Establish alternate Queueueueue to handle updates
            let myQ = OperationQueue()
            
            //Call method to start updates, sending in myQ and closure to handle data
            manager.startDeviceMotionUpdates(to: myQ, withHandler: {
                (data: CMDeviceMotion?, error: Error?) in
                
                //Safely unwrapping data or error
                if let myData = data {
                    
                    //Actually accessing data
                    if myData.userAcceleration.x > 1.1 || myData.userAcceleration.x < -1.1 {
                        print(Int(myData.userAcceleration.x * 100))
                        print("X")
                        
//                        self.fireTorpedo(torpedoNode)
                        //                        torpedoNode.position.y += 25
                        
                        
                    }
                    
                    if myData.userAcceleration.y > 0.9{
                        print(Int(myData.userAcceleration.x * 100))
                        print("Y")
                        
                        self.fireTorpedo(torpedoNode)
                    }
                }
                
                //Safely unwrapping errors
                if let myError = error {
                    print("error",myError)
                }
            })
        } else {
            print("We have no manager")
        }
        
        
        func getDegrees(radians: Double) -> Double {
            return 180 / Double.pi * radians
        }
        
        
        let videoNode: SKVideoNode? = {
            
            guard let urlString = Bundle.main.path(forResource: "qasarbackground_converted", ofType: "mp4") else {
                print("Fail")
                return nil
                
            }
            print(urlString)
            let url = URL(fileURLWithPath: urlString)
            
            let item = AVPlayerItem(url: url)
            
            player = AVPlayer(playerItem: item)
            
            return SKVideoNode(avPlayer: player)
            
        }()
        
        
        
        videoNode?.position = CGPoint( x: frame.midX,
                                       
                                       y: frame.midY)
        
        videoNode?.zPosition = 0.0
        videoNode?.size = CGSize(width: 2 * frame.maxX, height: 2 * frame.maxY)
        
        addChild((videoNode)!)
//
//
        player.play()
        
        
        
        
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               
                                               object: player.currentItem, queue: nil)
            
        { notification in
            
            self.player.seek(to: kCMTimeZero)
            
            self.player.play()
            
            print("reset Video")
            
        }

        //Set timer for shot limit
        
        shotTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(slowShot), userInfo: nil, repeats: true)
        
        // Set timer for enemies
        
        gameTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(addEnemy), userInfo: nil, repeats: true)
        
        blastTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(slowShot), userInfo: nil, repeats: true)
        
        
        
    }
    
    
    // MARK: - Game Methods
    
    @objc func slowShot () {
        
        if shot > 0 {
            
            shot -= 1
        }
    }
    
    

    
    
    
    @objc func addEnemy () {
        
        let enemy = SKSpriteNode(imageNamed: "alien")
        
        enemy.scale(to: CGSize(width: enemy.size.width / 6, height: enemy.size.height / 6))
        
        let position = CGFloat(0)
        
        enemy.position = CGPoint(x: position, y: self.frame.size.height + enemy.size.height)
        
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        
        enemy.physicsBody?.categoryBitMask = alienCategory
        enemy.physicsBody?.contactTestBitMask = laserCategory
        enemy.physicsBody?.collisionBitMask = 0
        enemy.zPosition = 3.0
        
        self.addChild(enemy)
        
        let animationDuration:TimeInterval = 3
        
        var actionArray = [SKAction]()
        
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -enemy.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        enemy.run(SKAction.sequence(actionArray))
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & laserCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
        
        if (firstBody.categoryBitMask & alienCategory) != 0 && (secondBody.categoryBitMask & userCategory) != 0 {
            alienDidCollideWithUser(alienNode: firstBody.node as! SKSpriteNode, userNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func alienDidCollideWithUser (alienNode: SKSpriteNode, userNode: SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = userNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        userNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 1.5)) {
            explosion.removeFromParent()
        }
            gameTimer?.invalidate()
    }
    
    func torpedoDidCollideWithAlien (torpedoNode: SKSpriteNode, alienNode :SKSpriteNode) {
        score.text = String(Int(score.text!)! + 100)

        print("SCORE:" + score.text!)
//        let frame = SKSpriteNode()
//        let wait = SKAction.wait(forDuration: 0.1)
//        var index = 0
//        var deadAlien = SKSpriteNode(imageNamed: <#T##String#>)
//        let shiftIndex = SKAction.run {
//
//            index += 1
//        }
//        let explosion = SKEmitterNode(fileNamed: "Explosion")!
//        explosion.position = alienNode.position
//        self.addChild(explosion)
        var count = 0
        var deadLoop = SKSpriteNode(imageNamed: "deadAlien000" + String(count))
        deadLoop.size = alienNode.size
        deadLoop.position = alienNode.position
        addChild(deadLoop)
        let frame = SKAction.run {
            deadLoop.removeFromParent()
            count += 1
            if count < 9{
                deadLoop = SKSpriteNode(imageNamed: "deadAlien000" + String(count))
                deadLoop.position = alienNode.position
                deadLoop.size = alienNode.size
                self.addChild(deadLoop)
            }
            if count > 9 && count < 21{
                deadLoop = SKSpriteNode(imageNamed: "deadAlien00" + String(count))
                deadLoop.position = alienNode.position
                deadLoop.size = alienNode.size
                self.addChild(deadLoop)
            }
            
        }
        let wait = SKAction.wait(forDuration: 0.1)
        let fireLoop = SKAction.sequence([frame, wait])
        let fireLoopForever = SKAction.repeatForever(fireLoop)
        self.run(SKAction.playSoundFileNamed("zap3.mp3", waitForCompletion: false))
        
        self.run(fireLoopForever)
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        
        self.run(SKAction.wait(forDuration: 1.5)) {
            deadLoop.removeFromParent()
        }
        
        
        
    }
    
    
 
    func fireTorpedo(_ torpedoNode: SKSpriteNode) {
        
        if shot > 0 {
            return
        }
        shot += 1
        
        torpedoNode.position.y += 5
        self.run(SKAction.playSoundFileNamed("zap1.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "laser3_0030")
        
        torpedoNode.scale(to: CGSize(width: torpedoNode.size.width / 5, height: torpedoNode.size.height / 5))
        torpedoNode.zRotation = 7.85
        
        torpedoNode.position = (user?.position)!
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = laserCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 0.3
        
        
        var actionArray = [SKAction]()
        
        
        actionArray.append(SKAction.move(to: CGPoint(x: (user?.position.x)!, y: self.frame.size.height + 10), duration: animationDuration))
        
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
        
        var count = 0
        var deadLoop = SKSpriteNode(imageNamed: "deadAlien000" + String(count))
        deadLoop.size = user!.size
        deadLoop.position = user!.position
        addChild(deadLoop)
        let frame2 = SKAction.run {
            var position = self.user!.position
            var size = self.user!.size
            deadLoop.removeFromParent()
            self.user!.removeFromParent()
            count += 1
            if count == 1 {
                deadLoop = SKSpriteNode(imageNamed: "spaceshipShot0000" )
                deadLoop.position = position
                deadLoop.size = size
                self.addChild(deadLoop)
            }
            else if count == 2 {
                deadLoop = SKSpriteNode(imageNamed: "spaceshipShot0001")
                deadLoop.position = position
                deadLoop.size = size
                self.addChild(deadLoop)
            }
            else if count == 3 {
                deadLoop = SKSpriteNode(imageNamed: "spaceshipShot0000")
                deadLoop.position = position
                deadLoop.size = size
                self.addChild(deadLoop)
            }
            else if count >= 4{
            self.addChild(self.user!)
            }
            
        }
        let wait2 = SKAction.wait(forDuration: 0.1)
        let fireLoop2 = SKAction.sequence([frame2, wait2])
        let fireLoopForever2 = SKAction.repeat(fireLoop2, count: 4)
        
        self.run(fireLoopForever2)
        
        
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
