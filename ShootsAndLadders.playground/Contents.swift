
import UIKit
import PlaygroundSupport

//Configuration goes here
let numPlayers:Int = 5
let boardSize:Int = 8 //creates an X by X board
let turnInterval:Double = 3 //in seconds


//board has to be bigger than 2x2
assert(boardSize > 3, "The board is too small, needs to be at least of size 4x4");

//max 5 players, could be more just need to add more colors to the array
assert(numPlayers <= 5, "This version supports a max of 5 players");

let queue = DispatchQueue(label: "com.sartogo.queue", qos: DispatchQoS.userInteractive)

class ViewController : UIViewController {
    
    var containerView:UIView!
    var playTimer:Timer!
    var log:UITextView!
    var containerSize:Double!
    var players:[player] = [player]()
    var currentPlayer  = 0
    var dice:die = die()
    var numMoves:Int = 0
    
    var screenSize:(width:Double, height:Double) = (width: 0, height: 0)
    let finalSquare = boardSize * boardSize
    var board:[Int] = [Int]()
    var squareMatrix:[Int: UIView] = [Int: UIView]()
    
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var loadingView: UIView = UIView()
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        screenSize.width = Double(view.frame.size.width)
        screenSize.height = Double(view.frame.size.height)
        containerSize = getSquareSize() * Double(boardSize)
        let xPos = (screenSize.width / 2 - containerSize / 2)
        let yPos:Double = 60 //spacing from the top of the screen
        containerView = UIView(frame: CGRect(x: xPos, y: yPos, width: containerSize, height: containerSize ))
        let title = UILabel()
        title.text = "Shoots and Ladders"
        title.font = UIFont.systemFont(ofSize:24)
        title.textColor = UIColor.white
        title.sizeToFit()
        title.center = CGPoint(x: containerView.center.x, y: 40)
        let padding:CGFloat = 10
        log = UITextView()
        log.isSelectable = false
        log.isScrollEnabled = true
        writeLog(text: "Welcome to Shoots and Ladders")
        writeLog(text: "Your game is being prepared")
        log.textColor = UIColor.black
        log.font = UIFont.systemFont(ofSize:12)
        log.isEditable = false
        log.backgroundColor = UIColor.lightGray
        log.layer.frame.size.width = CGFloat(screenSize.width) - 20 - padding
        log.layer.frame.size.height = CGFloat(screenSize.height) - containerView.frame.height - 180
        log.center = CGPoint(x: (CGFloat(screenSize.width / 2)), y: CGFloat(containerSize) + log.layer.frame.size.height / 2 + 160)

        let logPadding = UIView(frame: CGRect(x: 0, y: 0, width: log.layer.frame.size.width + padding, height: log.layer.frame.size.height + padding ))
        logPadding.backgroundColor = UIColor.lightGray
        logPadding.center = log.center
        self.view.addSubview(title)
        self.view.addSubview(logPadding)
        self.view.addSubview(log)
        self.view.addSubview(containerView)

        board = [Int](repeating: 0, count: finalSquare)
        //create the players
        for index in 1...numPlayers{
            let p = player(number: index)
            p.createPlaceholder(squareSize: getSquareSize())
            p.legend.center = CGPoint(x: CGFloat(screenSize.width / Double(numPlayers) * Double(index) - screenSize.width / Double(numPlayers)/2), y: CGFloat(containerSize) + 80)
            players.append(p)
            self.view.addSubview(p.legend)
        }
        
        dice.draw(size: screenSize.width/10)
        self.view.addSubview(dice.image)
        dice.image.center = CGPoint(x: players[0].legend.center.x, y: players[0].legend.center.y + 40)
        
        
        
        self.play()
        
        
    }
    
    func setupBoard(board: inout [Int]){
        //draw it
        let squareSize = getSquareSize()
        var index = 0;
        var even = false
        for row in 1...boardSize{
            for column in 1...boardSize{
                let y:Double
                let x:Double
                if(even){
                    y = containerSize - Double(row) * squareSize
                    x = containerSize - (Double(column - 1) * squareSize) - squareSize
                }
                else{
                    y = containerSize - Double(row) * squareSize
                    x = Double(column - 1) * squareSize
                }
                //autoreleasepool {
                    self.drawCell(index: index, x: x, y: y)
                //}
                index += 1
            }
            even = !even
        }


        //create shoots
        var numShoots = random.randomInt(lower: 2,upper: Int(ceil(Double(boardSize)/2)) + 2)
        while numShoots > 0 {
            //shoots start at the second row
            let shootStart = random.randomInt(lower: (boardSize), upper: finalSquare - 2)
            let shootEnd = random.randomInt(lower: 0, upper: shootStart - boardSize + 1)
            //avoid squares already taken
            if(board[shootStart] != 0 || board[shootEnd] != 0){
                continue
            }
            numShoots -= 1
            //autoreleasepool {
                drawShootOrLadder(start: shootStart, end: shootEnd);
            //}
            board[shootStart] = shootEnd - shootStart
        }
        //create ladders
        var numLadders = random.randomInt(lower: 2,upper: Int(ceil(Double(boardSize)/2)) + 1)
        while numLadders > 0 {
            //shoots can't start at the top row
            let ladderStart = random.randomInt(lower: 1, upper: finalSquare - boardSize - 1)
            let ladderEnd = random.randomInt(lower: ladderStart + boardSize - 1, upper: finalSquare - 2)
            //avoid squares already taken
            if(board[ladderStart] != 0 || board[ladderEnd] != 0){
                continue
            }
            numLadders -= 1
            //autoreleasepool {
                drawShootOrLadder(start: ladderStart, end: ladderEnd);
            //}
            board[ladderStart] = ladderEnd - ladderStart
        }
        //add the players placeholders
        DispatchQueue.main.async {
            for index in 0...numPlayers - 1{
                self.containerView.layer.addSublayer(self.players[index].placeHolder)
                self.movePlaceholder(player: index, square: 0)
            }
        }
    }
    
    func play(){
        //queue.async {
            //DispatchQueue.main.async {
                self.showLoadingIndicator()
            //}
        //}
        //queue.async {
        self.setupBoard(board: &self.board);
    
        
        
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.writeLog(text: "The board is ready and the game will start now. Good luck!")
            }
            sleep(2)
            DispatchQueue.main.async {
                self.playTimer = Timer.scheduledTimer(timeInterval: turnInterval, target: self, selector: #selector(ViewController.move), userInfo: nil, repeats: true)
            }
        //}
        

    }
    
    func move(){
        numMoves += 1
        self.players[self.currentPlayer].numTurns += 1
        let player:Int = self.currentPlayer
        let dr:Int = self.dice.roll()
        self.dice.image.center = CGPoint(x: self.players[self.currentPlayer].legend.center.x, y: self.players[self.currentPlayer].legend.center.y + 40)
        var newSquare:Int = self.players[player].currentSquare + dr
        let log:String = "\(self.players[player].name) rolls a \(dr) "
        let degrees:CGFloat = CGFloat(225 * numMoves * 10);
        
    queue.async {
        DispatchQueue.main.async {
            //animate the die
            UIView.animate(withDuration: 0.3, animations: {
                self.dice.image.transform = CGAffineTransform(rotationAngle: CGFloat(degrees * CGFloat(M_PI) / 180));
            })
            self.dice.show(number:dr)
        }
        usleep(useconds_t(Int((floor(Double(Int(turnInterval * 1000000) / 4))))))
        switch newSquare {
            case (self.finalSquare - 1):
                self.players[player].currentSquare = newSquare
                DispatchQueue.main.async {
                    self.playTimer.invalidate()
                    self.movePlaceholder(player: player, square: newSquare)
                    self.writeLog(text: log + " and wins in \(self.players[player].numTurns) turns!")
                }
            break
            case let newSquare where newSquare > (self.finalSquare - 1):
                // diceRoll will move us beyond the final square, so roll again
                DispatchQueue.main.async {
                    self.writeLog(text: log + " and overshoots the final square!")
                }
            break
            default:
                // this is a valid move, so find out its effect
                let sq = newSquare
                self.players[player].currentSquare = sq
                DispatchQueue.main.async {
                    self.movePlaceholder(player: player, square: sq)
                    self.writeLog(text: log + "and goes to square \(sq + 1)")
                }
                var jump = self.board[newSquare]
            
                while(jump != 0){
                    usleep(useconds_t(Int((floor(Double(Int(turnInterval * 1000000) / 4))))))
                    let j = jump
                    let sq = newSquare + j
                    DispatchQueue.main.async {
                        if j > 0 {
                            self.writeLog(text: "\(self.players[player].name) jumps! \(j) squares to square \(sq + 1)")
                        }
                        else if j < 0 {
                            self.writeLog(text: "\(self.players[player].name) shoots! slides \(j) squares to square \(sq + 1)")
                        }
                        self.movePlaceholder(player: player, square: sq)
                    }
                    self.players[player].currentSquare = sq
                    newSquare += jump
                    jump = self.board[newSquare]
                }
            
        }
    }
        self.currentPlayer += 1
        if(self.currentPlayer > numPlayers - 1){
            self.currentPlayer = 0
        }
    
    }
    
    func drawCell(index:Int, x:Double, y:Double){
        let squareSize = getSquareSize()
        let border = UIView(frame: CGRect(x: x, y: y, width: squareSize, height: squareSize))
        border.backgroundColor = UIColor.black
        containerView.addSubview(border)
        let square = UIView(frame: CGRect(x: x+1, y: y+1, width: squareSize-2, height: squareSize-2))
        square.backgroundColor = UIColor.white
        containerView.addSubview(square)
        let squareNumber = UILabel()
        squareNumber.text = String(index + 1)
        squareNumber.font = UIFont.systemFont(ofSize:14)
        squareNumber.textColor = UIColor.black
        squareNumber.sizeToFit()
        squareNumber.center = CGPoint(x: x + squareSize / 2, y: y + squareSize / 2)
        containerView.addSubview(squareNumber)

        squareMatrix[index] = square
    }
    
    func drawShootOrLadder(start: Int, end: Int){
        let aPath = UIBezierPath()
        
        aPath.move(to: CGPoint(x:(squareMatrix[start]?.center.x)!, y:(squareMatrix[start]?.center.y)!))
        
        aPath.addLine(to: CGPoint(x:(squareMatrix[end]?.center.x)!, y:(squareMatrix[end]?.center.y)!))
        aPath.close()
    
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = aPath.cgPath
        
        if(end > start){
            //ladder
            shapeLayer.strokeColor = UIColor.green.cgColor
        }
        else{
            //shoot
            shapeLayer.strokeColor = UIColor.red.cgColor
        }
        shapeLayer.lineWidth = 4.0
        shapeLayer.borderWidth = 1
        DispatchQueue.main.async {
            self.containerView.layer.addSublayer(shapeLayer)
        }
            
        
    }
    
    func movePlaceholder(player:Int, square:Int){
        let ph = players[player].placeHolder
        let sq = squareMatrix[square]
        ph.position = (sq?.center)!
        //this is to arrange the placeholders within a cell so they are all visible
        let squareSize = getSquareSize()
        var posModifiers = [(x: -(squareSize/4), y: -(squareSize/4)), (x: (squareSize/4), y: -(squareSize/4)), (x: 0, y: 0), (x: -(squareSize/4), y: (squareSize/4)), (x: (squareSize/4), y: (squareSize/4))]
        let mod = posModifiers[player]
        var pos = players[player].placeHolder.position
        pos.x = pos.x + CGFloat(mod.x)
        pos.y = pos.y + CGFloat(mod.y)
        players[player].placeHolder.position = pos
        if(square == finalSquare - 1){
            players[player].legend.backgroundColor = UIColor.white
            playTimer.invalidate()
        }
        
        
    }
    
    func writeLog(text:String){
        log.text = text + "\n" + log.text!
    }
    
    func getSquareSize() -> Double{
        return ceil((screenSize.width - 20) / Double(boardSize))
    }
    
    
    func showLoadingIndicator() {

            self.loadingView = UIView()
            self.loadingView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
            self.loadingView.center = self.view.center
            //self.loadingView.backgroundColor = UIColor.lightGray
            //self.loadingView.alpha = 0.7
            //self.loadingView.clipsToBounds = true
            //self.loadingView.layer.cornerRadius = 10
            
            self.spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.center = CGPoint(x:self.loadingView.bounds.size.width / 2, y:self.loadingView.bounds.size.height / 2)
            
            self.loadingView.addSubview(self.spinner)
            self.view.addSubview(self.loadingView)
        
            self.spinner.startAnimating()
    }
    
    func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
    
    
}


class random{
    
    static func randomInt(lower:Int, upper: Int) -> Int {
        var m: Int
        let u = upper + 1 - lower
        var r = Int(arc4random())
        if u > Int.max {
            m = 1 + ~u
        }
        else {
            m = ((upper + 1 - (u * 2)) + 1) % u
        }
        while r < m {
            r = Int(arc4random())
        }
        return (r % u) + lower
    }

}

class die{

    let number:Int
    var image:UIView
    var dots:[CAShapeLayer]
    
    init(){
        number = 0
        image = UIView()
        dots = [CAShapeLayer]()
    }

    func draw(size:Double){
        let borderWidth:Double = 4
        image = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size ))
        let border = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        border.backgroundColor = UIColor.white
        image.addSubview(border)
        let square = UIView(frame: CGRect(x: Double(borderWidth), y: Double(borderWidth), width: size - (borderWidth * 2), height: size - (borderWidth * 2)))
        square.backgroundColor = UIColor.white
        let radius:Double = (size - (borderWidth * 2))/6
        let diameter:Double = radius * 2

        for index in 0...8 {
            //we are drawing 9 circles to represent the die numbers
            let dotLayer:CAShapeLayer = CAShapeLayer()
            let temp:Double = ((((Double(index) + 1) + 3) / 3 - (1 / 3)) * 10)
            let xMod:Double = floor(temp.truncatingRemainder(dividingBy: 10) / 3) //convoluted way to get 0,1,2 for every row
            let yMod:Double = floor(Double(index)/3)
            let xPos:Double = xMod * diameter + radius
            let yPos:Double = yMod * diameter + radius
            
            let circle = UIBezierPath(arcCenter: CGPoint(x: xPos,y: yPos), radius: CGFloat(radius), startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
            
            dotLayer.path = circle.cgPath
            dotLayer.fillColor = UIColor.black.cgColor
            dotLayer.strokeColor = UIColor.black.cgColor
            dotLayer.lineWidth = 0.5
            dotLayer.isHidden = true
            square.layer.addSublayer(dotLayer)
            dots.append(dotLayer)
        }
        image.addSubview(square)
    }
    
    func move(point:CGPoint){
        
    }
    
    func roll() -> Int{
        return random.randomInt(lower: 1,upper: 6)
    }
    
    func show(number:Int){

        hideDots()
        switch number{
            case 1:
                dots[4].isHidden = false
            break
            case 2:
                dots[0].isHidden = false
                dots[8].isHidden = false
            break
            case 3:
                dots[0].isHidden = false
                dots[4].isHidden = false
                dots[8].isHidden = false
            break
            case 4:
                dots[0].isHidden = false
                dots[2].isHidden = false
                dots[6].isHidden = false
                dots[8].isHidden = false
            break
            case 5:
                dots[0].isHidden = false
                dots[2].isHidden = false
                dots[4].isHidden = false
                dots[6].isHidden = false
                dots[8].isHidden = false
            break
            case 6:
                dots[0].isHidden = false
                dots[2].isHidden = false
                dots[3].isHidden = false
                dots[5].isHidden = false
                dots[6].isHidden = false
                dots[8].isHidden = false
            break
         
            default: break
        
        }
    }
    
    func hideDots(){
        for index in 0...8{
            dots[index].isHidden = true;
        }
    }

}

class player{
    
    let number: Int
    var currentSquare:Int
    var numTurns:Int
    var name:String
    var color:UIColor
    var playerColors = [UIColor.yellow, UIColor.cyan, UIColor.green, UIColor.magenta, UIColor.orange]
    var placeHolder:CAShapeLayer
    var legend:UILabel

    
    init(number:Int){
        self.number = number
        currentSquare = 0
        numTurns = 0
        name = "Player " + String(number)
        color = playerColors[number - 1]
        placeHolder = CAShapeLayer()
        legend = UILabel()
        legend.text = name
        legend.font = UIFont.systemFont(ofSize:12)
        legend.textColor = color
        legend.sizeToFit()
        legend.textAlignment = .center
    }
    
    func createPlaceholder(squareSize:Double ){
        let circle = UIBezierPath(arcCenter: CGPoint(x: 0,y: 0), radius: CGFloat(squareSize/5), startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
        
        placeHolder.path = circle.cgPath
        placeHolder.fillColor = color.cgColor
        placeHolder.strokeColor = UIColor.black.cgColor
        placeHolder.lineWidth = 0.5
    }
    

}

PlaygroundPage.current.liveView = ViewController()
PlaygroundPage.current.needsIndefiniteExecution = true













