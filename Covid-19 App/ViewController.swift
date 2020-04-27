//
//  ViewController.swift
//  Covid-19 App
//
//  Created by Mark Lawrence on 4/18/20.
//  Copyright © 2020 Mark Lawrence. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    @IBOutlet var graphView: GraphView!
    @IBOutlet var talkButton: UIButton!
    @IBOutlet var darkerMic: UIImageView!
    let scrollView = UIScrollView()
    @IBOutlet var headerResponseLabel: UILabel!
    @IBOutlet var recordRing: UIImageView!
    @IBOutlet var recordButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    let speechSynthesizer = AVSpeechSynthesizer()
    var node: AVAudioInputNode? = nil

    @IBOutlet var manImage: UIImageView!
    
    var userInput = ""
    var locationType = ""
    var locationNames = [String]()
    var type = "confirmed"
    
    var animationState: AnimationState = .initial

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //getGraphData()
        //userInput = "How many cases in Florida"
        //preformQuery()
        requestTranscribePermissions()
        speechSynthesizer.delegate = self
        // Do any additional setup after loading the view.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            
            try! audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.spokenAudio)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let currentRoute = AVAudioSession.sharedInstance().currentRoute
            for description in currentRoute.outputs {
                if description.portType == AVAudioSession.Port.headphones {
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                } else {
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                }
            }
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
    }
    
    
    
    @IBAction func tapTalkButton(_ sender: Any) {
        if isRecording{
            cancelRecording()
            isRecording = false
            recordButton.isUserInteractionEnabled = false
            animationState = .thinking
            
        } else{
            isRecording = true
            self.recordAndRecognizeSpeech()
            animationState = .listening
        }
        updateAnimationState()
    }
    
    func updateAnimationState(){
        switch animationState{
        case .initial:
            headerResponseLabel.text = "How can I help you?"
            manImage.image = UIImage(named: "standby.png")
        case .standby:
            manImage.image = UIImage(named: "standby.png")
            print("STATE: standby")
        case .listening:
            manImage.image = UIImage(named: "standby.png")
            print("STATE: listening")
            darkerMic.isHidden = false
            headerResponseLabel.text = "How can I help you?"
        case .thinking:
            print("STATE: thinking")
            manImage.image = UIImage(named: "thinking.png")
            spinAnimation()
            darkerMic.isHidden = true
            headerResponseLabel.text = "Let me think..."
        case .speaking:
            recordRing.layer.removeAllAnimations()
            recordRing.image = UIImage(named: "normal circle.png")
            manImage.image = UIImage(named: "talking.png")
            print("STATE: Speaking")
        }
    }
    
    func speakResponse(textToSpeak: String){
        animationState = .speaking
        updateAnimationState()
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: textToSpeak)
        //speechUtterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Fred")
        speechSynthesizer.speak(speechUtterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        animationState = .standby
        updateAnimationState()
        print("Done talking")
        recordButton.isUserInteractionEnabled = true
    }
    
    
    
    func spinAnimation(){
        recordRing.image = UIImage(named: "animating circle.png")
        let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 1 // or however long you want ...
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        recordRing.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    func updateResponseHeader(){
        var response = ""
        var startIndex1 = 0
        var endIndex1 = 0
        var startIndex2 = 0
        var endIndex2 = 0
        
        if type == "all"{
            response = "Here are the latest stats"
        } else{
            if type == "confirmed"{
                response = "Here are the cases"
            } else if type == "deaths"{
                response = "Here are the number of deaths"
            } else if type == "recovered"{
                response = "Here are the number who have recovered"
            }
            var i = 0
            if locationNames.first == "Afghanistan"{
                locationNames[0] = "worldwide"
            }
            for locations in locationNames{
                if locations != "worldwide"{
                    response += " in"
                }
                if i == 0{
                    startIndex1 = response.count
                } else{
                    startIndex2 = response.count
                }
                response += " \(locations)"
                if locationType == "county"{
                    response += " County"
                }
                if i == 0{
                    endIndex1 = response.count
                } else{
                    endIndex2 = response.count
                }
                i += 1
                if i != locationNames.count{
                    response += " and"
                }
            }
            
        }

        let mutableString = NSMutableAttributedString(string: response)
        if startIndex1 != 0{
            mutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(named: "yellow")!, range: NSRange(location: startIndex1,length: endIndex1-startIndex1))
            if startIndex2 != 0{
                mutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(named: "blue")!, range: NSRange(location: startIndex2,length: endIndex2-startIndex2))
            }
        }
        headerResponseLabel.attributedText = mutableString
    }
    
    func preformQuery(){
        //let userText = inputTextFeild.text
        let userText = userInput
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "us-central1-covidproject-blxxjl.cloudfunctions.net"
        urlComponents.path = "/access-dialogflow"
        let queryItemArticle = URLQueryItem(name: "userText", value: userText)
        urlComponents.queryItems = [queryItemArticle]
        let urlPath = urlComponents.url
        
        sendRequest(url: urlPath!.absoluteString) { (output) in
            DispatchQueue.main.async { // Correct
                //weather["currently"]!["summary"]!! as! String
                let outputString = output["text"]! as! String
                print(outputString)
                self.speakResponse(textToSpeak: outputString)
                self.getGraphData(jsonData: output)
            }
        }
    }
    
    
    func getGraphData(jsonData: [String: AnyObject]){
        var parameters = [String: AnyObject]()
        if let parametersCheck = jsonData["parameters"] as? [String : AnyObject]{
            parameters = parametersCheck
        } else{
            return
        }
        let states = (parameters as NSDictionary).value(forKeyPath: "fields.state.listValue.values") as? [[String : AnyObject]]
        let counties = (parameters as NSDictionary).value(forKeyPath: "fields.county.listValue.values") as? [[String : AnyObject]]
        let countries = (parameters as NSDictionary).value(forKeyPath: "fields.country.listValue.values") as? [[String : AnyObject]]
        let types = (parameters as NSDictionary).value(forKeyPath: "fields.type.listValue.values") as? [[String : AnyObject]]
        if types != nil {
            if types!.count != 0 {
                type = types![0]["stringValue"]! as! String
                if type == "all"{
                    type = "confirmed"
                }
            }
        }
        
        var urls = [String]()
        
        if counties == nil{
            //then worldwide stats
            locationType = "country"
            locationNames = ["worldwide"]
            urls.append("https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=jhu&timelines=true")
            
        } else{
            //Location stats
            if !counties!.isEmpty{
                locationType = "county"
                for county in counties!{
                    var county = county["stringValue"]!
                    county = county.components(separatedBy: " ").first as AnyObject
                    if !states!.isEmpty{
                        let state = states![0]["stringValue"]!
                        urls.append("https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&county=\(county)&province=\(state)&timelines=true")
                        
                    } else{
                        urls.append("https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&county=\(county)&timelines=true")
                    }
                }
            } else if !countries!.isEmpty{
                locationType = "country"
                for country in countries!{
                    let countryString = (country as NSDictionary).value(forKeyPath: "structValue.fields.alpha-2.stringValue")
                    urls.append("https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=jhu&country_code=\(countryString!)&timelines=true")
                }
                
            } else if states != nil{
                locationType = "province"
                for state in states!{
                    var state = state["stringValue"]! as! String
                    state = state.replacingOccurrences(of: " ", with: "%20")
                    urls.append("https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&province=\(state)&timelines=true")
                }
            }
        }
        
        var numberOfURLSCompleted = 0
        var allTimelineData = [[TimelineData]]()
        locationNames = [String]()
        for url in urls{
            sendRequest(url: url) { (output) in
                DispatchQueue.main.async { // Correct
                    var locations: [[String : AnyObject]]? = nil
                    if let locationcheck = output["locations"] as? [[String : AnyObject]]{
                        locations = locationcheck
                    }
                    if locations == nil{
                        self.graphView.graphData = []
                        self.graphView.reloadGraph()
                        self.updateResponseHeader()
                        return
                    }
                    var timelineData = [TimelineData]()
                    
                    self.locationNames.append(locations![0]["\(self.locationType)"] as! String)
                    
                    for location in locations!{
                        let confirmed = (location as NSDictionary).value(forKeyPath: "timelines.\(self.type).timeline") as? [String : AnyObject]
                        for date in confirmed!{
                            timelineData.append(TimelineData(date: date.key, cases: date.value as! Int))
                        }
                    }
                    timelineData.sort{ $0.date < $1.date }
                    timelineData = self.combineMultipleLocationsByDate(timelineData)
                    allTimelineData.append(timelineData)
                    numberOfURLSCompleted += 1
                    if numberOfURLSCompleted == urls.count{
                        if allTimelineData.count == 1{
                            self.graphView.graphData = [allTimelineData[0]]
                        } else if allTimelineData.count > 1{
                            //Make sure the first two are the same length
                            let length0 = allTimelineData[0].count
                            let length1 = allTimelineData[1].count
                            if length0 != length1{
                                if length0 > length1{
                                    allTimelineData[0] = allTimelineData[0].suffix(length1)
                                } else{
                                    allTimelineData[1] = allTimelineData[1].suffix(length0)
                                }
                            }
                            self.graphView.graphData = [allTimelineData[0], allTimelineData[1]]
                        }
                        self.graphView.reloadGraph()
                        self.updateResponseHeader()
                    }
                }
            }
        }
    }
    
    func combineMultipleLocationsByDate(_ timelineData: [TimelineData]) -> [TimelineData]{
        var newTimelineData = [TimelineData]()
        
        var previousDate = ""
        var newIndex = -1
        for data in timelineData{
            if previousDate != data.date{
                newTimelineData.append(data)
                newIndex += 1
            } else{
                newTimelineData[newIndex].incrementCases(by: data.cases)
            }
            previousDate = data.date
        }
        
        return newTimelineData
    }
    
    
    public func sendRequest(url: String , completionBlock: @escaping ([String: AnyObject]) -> Void) -> Void {
        print("Sending request")
        let requestURL = URL(string: url)
        let request = URLRequest(url: requestURL!)
        let requestTask = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if(error != nil) {
                print("Error sending url: \(String(describing: error))")
            } else {
                //let outputjson = try? JSONSerialization.jsonObject(with: data!, options: [])
                let outputjson = try? (JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : AnyObject])
                if outputjson != nil{
                    completionBlock(outputjson!);
                } else{
                    completionBlock(["text": "Sorry, something went wrong" as AnyObject]);
                    
                }
            }
        }
        requestTask.resume()
    }
}

extension ViewController: SFSpeechRecognizerDelegate{
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    func recordAndRecognizeSpeech() {
        node = audioEngine.inputNode
        let recordingFormat = node!.outputFormat(forBus: 0)
        node!.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
            guard
                let channelData = buffer.floatChannelData
                else {
                    return
            }
            
            let channelDataValue = channelData.pointee
            let channelDataValueArray = stride(from: 0,
                                               to: Int(buffer.frameLength),
                                               by: buffer.stride).map{ channelDataValue[$0] }
            let inner = channelDataValueArray.map{ $0 * $0 }.reduce(0, +)
            let rms = sqrt(inner / Float(buffer.frameLength))
            let avgPower = 20 * log10(rms)
            let meterLevel = self.scaledPower(power: avgPower)
            DispatchQueue.main.async {
                self.cropMic(heightRatio: Double(meterLevel))
            }
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        //animateRecordMic()
        request.shouldReportPartialResults = false
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                self.userInput = result.bestTranscription.formattedString
                print(self.userInput)
                self.preformQuery()
            } else if let error = error {
                print(error)
            }
        })
    }
    
    func cancelRecording() {
        recognitionTask?.finish()
        recognitionTask = nil
        
        // stop audio
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func scaledPower(power: Float) -> Float {
      guard power.isFinite else { return 0.0 }
      if power < -80.0 {
        return 0.0
      } else if power >= 1.0 {
        return 1.0
      } else {
        return (abs(-80.0) - abs(power)) / abs(-80.0)
      }
    }
    
    func cropMic(heightRatio: Double){
        if heightRatio < 0.25{
            darkerMic.image = UIImage(named: "1_8")
        } else if heightRatio < 0.375{
            darkerMic.image = UIImage(named: "2_8")
        } else if heightRatio < 0.5{
            darkerMic.image = UIImage(named: "3_8")
        } else if heightRatio < 0.625{
            darkerMic.image = UIImage(named: "4_8")
        } else if heightRatio < 0.75{
            darkerMic.image = UIImage(named: "5_8")
        } else if heightRatio < 0.875{
            darkerMic.image = UIImage(named: "6_8")
        } else if heightRatio <= 1{
            darkerMic.image = UIImage(named: "7_8")
        } else{
            darkerMic.image = UIImage(named: "8_8")
        }
    }
    
}

enum AnimationState{
    case initial
    case standby
    case listening
    case speaking
    case thinking
}

