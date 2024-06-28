import SpriteKit

class Ball: SKNode {
    let id: String

    private let imgOffsetContainer = SKNode()
    private let imgRotationContainer = SKNode()
    private let img = SKSpriteNode(imageNamed: "Ball")
    private let amazonImage = SKSpriteNode(imageNamed: "amzn") // New property

    let radius: CGFloat

    private let shadowSprite = SKSpriteNode(imageNamed: "ContactShadow")
    private let shadowContainer = SKNode() // For fading in/out

    private let squish = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.3, dampingRatio: 0.5))
    private let dragScale = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.2, dampingRatio: 0.8))

    var beingDragged = false {
        didSet(old) {
            if beingDragged != old {
                dragScale.animate(toValue: beingDragged ? 1.05 : 1, velocity: dragScale.velocity, completion: nil)
            }
        }
    }

    init(radius: CGFloat, pos: CGPoint, id: String) {
        self.id = id
        self.radius = radius
        super.init()
        self.position = pos

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.restitution = 0.6
        body.allowsRotation = false
        body.usesPreciseCollisionDetection = true
        body.contactTestBitMask = 1
        self.physicsBody = body

        addChild(shadowContainer)
        shadowContainer.addChild(shadowSprite)
        let shadowWidth: CGFloat = radius * 4
        shadowSprite.size = CGSize(width: shadowWidth, height: 0.564 * shadowWidth)
        shadowSprite.alpha = 0
        shadowContainer.alpha = 0

        addChild(imgOffsetContainer)
        imgOffsetContainer.addChild(imgRotationContainer)

        img.size = CGSize(width: radius * 2, height: radius * 2)
        imgRotationContainer.addChild(img)

        amazonImage.position = CGPoint(x: 0, y: 0)
        amazonImage.size = CGSize(width: radius * 1.5, height: radius * 2)
        amazonImage.zPosition = 1 // Ensure the image is behind the ball
        imgRotationContainer.addChild(amazonImage)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var rect: CGRect {
        CGRect(origin: .init(x: position.x - radius, y: position.y - radius), size: .init(width: radius * 2, height: radius * 2))
    }

    func animateShadow(visible: Bool, duration: TimeInterval) {
        if visible {
            shadowContainer.run(SKAction.fadeIn(withDuration: duration))
        } else {
            shadowContainer.run(SKAction.fadeOut(withDuration: duration))
        }
    }

    func update() {
        shadowSprite.position = CGPoint(x: 0, y: radius * 0.3 - position.y)
        let distFromBottom = position.y - radius
        shadowSprite.alpha = remap(x: distFromBottom, domainStart: 0, domainEnd: 200, rangeStart: 1, rangeEnd: 0)
        imgRotationContainer.xScale = squish.value

        let yDelta = -(1 - imgRotationContainer.xScale) * radius / 2
        imgOffsetContainer.position = .init(x: 0, y: yDelta)

        img.setScale(dragScale.value)
    }

    func didCollide(strength: Double, normal: CGVector) {
        let angle = atan2(normal.dy, normal.dx)
        imgRotationContainer.zRotation = angle
        img.zRotation = -angle

        let targetScale = remap(x: strength, domainStart: 0, domainEnd: 1, rangeStart: 1, rangeEnd: 0.8)
        let velocity = remap(x: strength, domainStart: 0, domainEnd: 1, rangeStart: -5, rangeEnd: -10)

        // Rotate the amazonImage differently based on the collision angle
        let initialRotation = -angle * 0.5
        amazonImage.zRotation = initialRotation

        // Calculate the rotation speed and duration based on the collision strength
        let rotationSpeed = CGFloat(remap(x: strength, domainStart: 0, domainEnd: 1, rangeStart: 0, rangeEnd: 2 * Double.pi))
        let rotationDuration = remap(x: strength, domainStart: 0, domainEnd: 1, rangeStart: 1, rangeEnd: 3)

        // Create and run the rotation action
        let rotateAction = SKAction.rotate(byAngle: rotationSpeed, duration: rotationDuration)
        amazonImage.run(rotateAction)

        // squish.animate(toValue: targetScale, velocity: velocity, completion: nil)

        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
        //     self.squish.animate(toValue: 1, velocity: self.squish.velocity, completion: nil)
        // }
    }
}

func remap(x: Double, domainStart: Double, domainEnd: Double, rangeStart: Double, rangeEnd: Double) -> Double {
    return rangeStart + (x - domainStart) * (rangeEnd - rangeStart) / (domainEnd - domainStart)
}
