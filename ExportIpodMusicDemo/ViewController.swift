

import UIKit
import MediaPlayer
import AVFoundation

func delay(_ delay:Double, closure:@escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}


extension CGRect {
    init(_ x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) {
        self.init(x:x, y:y, width:w, height:h)
    }
}
extension CGSize {
    init(_ width:CGFloat, _ height:CGFloat) {
        self.init(width:width, height:height)
    }
}
extension CGPoint {
    init(_ x:CGFloat, _ y:CGFloat) {
        self.init(x:x, y:y)
    }
}
extension CGVector {
    init (_ dx:CGFloat, _ dy:CGFloat) {
        self.init(dx:dx, dy:dy)
    }
}

func checkForMusicLibraryAccess(andThen f:(()->())? = nil) {
    let status = MPMediaLibrary.authorizationStatus()
    switch status {
    case .authorized:
        f?()
    case .notDetermined:
        MPMediaLibrary.requestAuthorization() { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    f?()
                }
            }
        }
    case .restricted:
        // do nothing
        break
    case .denied:
        // do nothing, or beg the user to authorize us in Settings
        break
    }
}

class ViewController: UIViewController {
    
    
    //    let urlString = "https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/AudioPreview18/v4/9c/db/54/9cdb54b3-5c52-3063-b1ad-abe42955edb5/mzaf_520282131402737225.plus.aac.p.m4a"
    
    @IBOutlet weak var viewPlayer: UIView!
    @IBOutlet weak var constPlayerHeight: NSLayoutConstraint!
    @IBOutlet weak var lblBeatName: UILabel!
    @IBOutlet weak var lblCurruntTime: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var btnRestart: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var lblTotalTime: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var overlayView : UIView? // This should be a class variable

    var isPaused = false
    var audioPlayer : AVAudioPlayer?
    var arrFetchedMedia = NSMutableArray()
    
    var timer = Timer()

    var arrFetchedDirMedia = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.title = "LI Export iPod Music"
        //        if((UserDefaults.standard.array(forKey: "MediaArray")) != nil){
        if let unarchivedObject = UserDefaults.standard.object(forKey: "MediaArray") as? Data {
            
            self.arrFetchedMedia = (NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject as Data) as? NSMutableArray)!
        }
        //        }
        constPlayerHeight.constant = 80
        self.tableView.reloadData()
        fetchImportedBeat()
        
    }
    
    
    @IBAction func onClickRestart(_ sender: Any) {
        if((audioPlayer) != nil){
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateVideoPlayerSlider), userInfo: nil, repeats: true)

            if(audioPlayer!.isPlaying || isPaused ){
                
                audioPlayer!.stop()
                audioPlayer!.currentTime =  0
                btnPlay.setTitle("Pause", for: .normal)
                audioPlayer!.play()
            }else{
                btnPlay.setTitle("Pause", for: .normal)
                audioPlayer!.play()
            }
        }
        
    }
    
    @IBAction func onClickPlay(_ sender: Any) {
        if((audioPlayer) != nil){
            if(audioPlayer!.isPlaying){
                audioPlayer!.pause()
                isPaused = true
                btnPlay.setTitle("Play", for: .normal)
            }else{
                audioPlayer!.play()
                isPaused = false
                btnPlay.setTitle("Pause", for: .normal)
            }
            
        }
        
    }
    
    @IBAction func onClickInsert(_ sender: Any) {
        self.presentPicker(sender)
    }
    
    func presentPicker (_ sender: Any) {
        checkForMusicLibraryAccess {
            let picker = MPMediaPickerController(mediaTypes:.music)
            picker.showsCloudItems = false
            picker.delegate = self
            picker.allowsPickingMultipleItems = true
            picker.modalPresentationStyle = .popover
            picker.preferredContentSize = CGSize(500,600)
            self.present(picker, animated: true)
            if let pop = picker.popoverPresentationController {
                if let b = sender as? UIBarButtonItem {
                    pop.barButtonItem = b
                }
            }
        }
    }
    
    
    var documentURL = { () -> URL in
        let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documentURL
    }
    
    func fetchImportedBeat(){
        
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        var theItems = [String]()
        
        if let dirPath = paths.first
        {
            let mediaURL = URL(fileURLWithPath: dirPath)
            
            do {
                theItems = try FileManager.default.contentsOfDirectory(atPath: mediaURL.path)
                arrFetchedDirMedia = theItems
                print(theItems)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    func playmedia(fileName:URL) {
        
        do {
            //7 - Insert the song from our Bundle into our AVAudioPlayer
            //            let fileName = (arrFetchedMedia[0] as! NSMutableDictionary).value(forKey: "storagePath") as! URL
            audioPlayer = try AVAudioPlayer(contentsOf: fileName)
            //8 - Prepare the song to be played
            audioPlayer!.prepareToPlay()
            
            //9 - Create an audio session
            let audioSession = AVAudioSession.sharedInstance()
            do {
                //10 - Set our session category to playback music
                try audioSession.setCategory(.playback, mode: .default, options: .defaultToSpeaker)
                //11 -
            } catch let sessionError {
                
                print(sessionError)
            }
            //12 -
        } catch let songPlayerError {
            print(songPlayerError)
        }
        if((audioPlayer) != nil){
            
            audioPlayer!.play()
            progressView.progress = 0.0
            isPaused = false
            btnPlay.setTitle("Pause", for: .normal)
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateVideoPlayerSlider), userInfo: nil, repeats: true)


        }
        
    }
    @objc func updateVideoPlayerSlider() {
        if((audioPlayer) != nil){
            if(audioPlayer!.isPlaying || isPaused){
                let currentTimeInSeconds = audioPlayer!.currentTime
                
                let curruntMins = currentTimeInSeconds / 60
                let CurruntSec = currentTimeInSeconds.truncatingRemainder(dividingBy: 60)
                
                let timeformatter = NumberFormatter()
                timeformatter.minimumIntegerDigits = 2
                timeformatter.minimumFractionDigits = 0
                timeformatter.roundingMode = .down
                guard let curruntMinsStr = timeformatter.string(from: NSNumber(value: curruntMins)), let curruntSecsStr = timeformatter.string(from: NSNumber(value: CurruntSec)) else {
                    return
                }
                lblCurruntTime.text = "\(curruntMinsStr).\(curruntSecsStr)"
                
                let totalDuration = audioPlayer!.duration
                let totalMins = totalDuration / 60
                let totalSec = totalDuration.truncatingRemainder(dividingBy: 60)
                
                guard let totalMinsStr = timeformatter.string(from: NSNumber(value: totalMins)), let totalSecsStr = timeformatter.string(from: NSNumber(value: totalSec)) else {
                    return
                }
                lblTotalTime.text = "\(totalMinsStr).\(totalSecsStr)"
                
                progressView.progress = Float(currentTimeInSeconds/totalDuration)
                
            }else{
                timer.invalidate()
                lblCurruntTime.text = "00:00"
                btnPlay.setTitle("Play", for: .normal)
            }
          
        }
    }

}

extension ViewController :UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrFetchedMedia.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MediaCell
        cell.lblMediaName.text = ((arrFetchedMedia[indexPath.row] as! [String:Any])["title"] as! String)
        cell.lblSizeName.text = ((arrFetchedMedia[indexPath.row] as! [String:Any])["size"] as! String)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        lblBeatName.text = ((arrFetchedMedia[indexPath.row] as! [String:Any])["title"] as! String)
        constPlayerHeight.constant = 0
        self.playmedia(fileName: ((arrFetchedMedia[indexPath.row] as! [String:Any])["storagePath"] as! URL))
    }
}

extension ViewController : MPMediaPickerControllerDelegate {
    // must implement these, as there is no automatic dismissal
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        self.view.showBlurLoader()
        for tempItem in mediaItemCollection.items {
            
            var dict = [String:Any]()
            let item: MPMediaItem = tempItem
            let pathURL: URL? = item.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            if pathURL == nil {
                print("Picking Error")
                return
            }
            let songAsset = AVURLAsset(url: pathURL!, options: nil)
            
            let tracks = songAsset.tracks(withMediaType: .audio)
            
            if(tracks.count > 0){
                let track = tracks[0]
                if(track.formatDescriptions.count > 0){
                    let desc = track.formatDescriptions[0]
                    let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(desc as! CMAudioFormatDescription)
                    let formatID = audioDesc?.pointee.mFormatID
                    
                    var fileType:NSString?
                    var ex:String?
                    
                    switch formatID {
                    case kAudioFormatLinearPCM:
                        print("wav or aif")
                        let flags = audioDesc?.pointee.mFormatFlags
                        if( (flags != nil) && flags == kAudioFormatFlagIsBigEndian ){
                            fileType = "public.aiff-audio"
                            ex = "aif"
                        }else{
                            fileType = "com.microsoft.waveform-audio"
                            ex = "wav"
                        }
                        
                    case kAudioFormatMPEGLayer3:
                        print("mp3")
                        fileType = "com.apple.quicktime-movie"
                        ex = "mp3"
                        break;
                        
                    case kAudioFormatMPEG4AAC:
                        print("m4a")
                        fileType = "com.apple.m4a-audio"
                        ex = "m4a"
                        break;
                        
                    case kAudioFormatAppleLossless:
                        print("m4a")
                        fileType = "com.apple.m4a-audio"
                        ex = "m4a"
                        break;
                        
                    default:
                        break;
                    }
                    let exportSession = AVAssetExportSession(asset: AVAsset(url: pathURL!), presetName: AVAssetExportPresetAppleM4A)
                    exportSession?.shouldOptimizeForNetworkUse = true
                    //                    exportSession?.outputFileType = AVFileType.m4a
                    //                    exportSession?.outputFileType = AVFileType(rawValue: fileType! as String) ;
                    exportSession?.outputFileType = AVFileType.m4a ;
                    
                    var fileName = item.value(forProperty: MPMediaItemPropertyTitle) as! String
                    var fileNameArr = NSArray()
                    fileNameArr = fileName.components(separatedBy: " ") as NSArray
                    fileName = fileNameArr.componentsJoined(by: "")
                    fileName = fileName.replacingOccurrences(of: ".", with: "")
                    
                    print("fileName -> \(fileName)")
                    let outputURL = documentURL().appendingPathComponent("\(fileName).m4a")
                    print("OutURL->\(outputURL)")
                    print("fileSizeString->\(item.fileSizeString)")
                    print("fileSize->\(item.fileSize)")
                    
                    dict = [
                        "fileType":fileType as Any,
                        "extention":ex as Any,
                        "title":fileName,
                        "storagePath":outputURL,
                        "size":item.fileSizeString,
                        "isCloudItem":item.isCloudItem
                    ]

                    let namePredicate = NSPredicate(format: "title like %@",dict["title"] as! String);
                    
                    let filteredArray = arrFetchedMedia.filter { namePredicate.evaluate(with: $0) };
                    print("names = ,\(filteredArray)");
                    
                    if(filteredArray.count == 0)
                    {
                        arrFetchedMedia.add(dict)
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: outputURL)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    exportSession?.outputURL = outputURL
                    exportSession?.exportAsynchronously(completionHandler: { () -> Void in
                        
                        if exportSession!.status == AVAssetExportSession.Status.completed  {
                           self.view.removeBluerLoader()
                            print("Export Successfull")
                            self.fetchImportedBeat()
                            let arrArchive = NSKeyedArchiver.archivedData(withRootObject: self.arrFetchedMedia) as NSData
                            
                            let defaults = UserDefaults.standard
                            
                            defaults.set(arrArchive, forKey: "MediaArray")
                            print("arr => \(self.arrFetchedMedia)")
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            
                        } else {
                            self.view.removeBluerLoader()
                            print("Export failed")
                            print(exportSession!.error as Any)
                        }
                    })
                }
            }
        }
        self.dismiss(animated:true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        print("cancel")
        self.dismiss(animated:true)
    }
    
}

extension UIView{
    func showBlurLoader(){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.8
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.startAnimating()
        
        blurEffectView.contentView.addSubview(activityIndicator)
        activityIndicator.center = blurEffectView.contentView.center
        
        self.addSubview(blurEffectView)
    }
    
    func removeBluerLoader(){
        DispatchQueue.main.async {
            self.subviews.compactMap {  $0 as? UIVisualEffectView }.forEach {
                $0.removeFromSuperview()
            }
        }
        
    }
}

extension MPMediaItem{
    
    // Value is in Bytes
    var fileSize: Int{
        get{
            if let size = self.value(forProperty: "fileSize") as? Int{
                return size
            }
            return 0
        }
    }
    
    var fileSizeString: String{
        let formatter = Foundation.NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        //Byte to MB conversion using 1024*1024 = 1,048,567
        return (formatter.string(from: NSNumber(value: Float(self.fileSize)/1048567.0)) ?? "0") + " MB"
    }
    
}

extension ViewController : UIBarPositioningDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
