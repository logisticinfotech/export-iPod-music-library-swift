

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
    
    var audioPlayer : AVAudioPlayer?
    var arrFetchedMedia = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        let url = URL(fileURLWithPath: "file:///var/mobile/Containers/Data/Application/52AE6115-96F0-4D20-9F98-7D21478D6CFE/Documents/custom.m4a")
        //
        //                do {
        //                    self.audioPlayer = try AVAudioPlayer(contentsOf:  url)
        //                    self.audioPlayer?.prepareToPlay()
        //                    self.audioPlayer?.play()
        //                } catch {
        //                    print("Error:", error.localizedDescription)
        //                }
        
    }
    
    @IBAction func doGo (_ sender: Any!) {
        self.presentPicker(sender)
    }
    
    @IBAction func playMusic(_ sender: Any) {
        self.playmedia()
        
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
    
    func playmedia() {
        do {
            //7 - Insert the song from our Bundle into our AVAudioPlayer
            let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileName = (arrFetchedMedia[0] as! NSMutableDictionary).value(forKey: "storagePath") as! URL
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
        }
    }
}

extension ViewController : MPMediaPickerControllerDelegate {
    // must implement these, as there is no automatic dismissal
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        arrFetchedMedia.removeAllObjects()
        
        for tempItem in mediaItemCollection.items {
            
            let dict = NSMutableDictionary()
            let item: MPMediaItem = tempItem
            let pathURL: URL? = item.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
            if pathURL == nil {
                print("Picking Error")
                return
            }
            
            //            // get file extension andmime type
            //            let str = pathURL!.absoluteString
            //            let str2 = str.replacingOccurrences( of : "ipod-library://item/item", with: "")
            //            let arr = str2.components(separatedBy: "?")
            //            var mimeType = arr[0]
            //            mimeType = mimeType.replacingOccurrences( of : ".", with: "")
            
            // Export the ipod library as .m4a file to local directory for remote upload
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
                    print("fileType \(fileType)")
                    
                    let exportSession = AVAssetExportSession(asset: AVAsset(url: pathURL!), presetName: AVAssetExportPresetAppleM4A)
                    exportSession?.shouldOptimizeForNetworkUse = true
                    //                    exportSession?.outputFileType = AVFileType.m4a
//                    exportSession?.outputFileType = AVFileType(rawValue: fileType! as String) ;
                    exportSession?.outputFileType = AVFileType.m4a ;
                    
                    let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    
                    var fileName = item.value(forProperty: MPMediaItemPropertyTitle) as! String
                    var fileNameArr = NSArray()
                    fileNameArr = fileName.components(separatedBy: " ") as NSArray
                    fileName = fileNameArr.componentsJoined(by: "")
                    fileName = fileName.replacingOccurrences(of: ".", with: "")
                    
                    print("fileName -> \(fileName)")
                    //                    let outputURL = documentURL.appendingPathComponent("\(fileName).m4a")
                    let outputURL = documentURL.appendingPathComponent("test.m4a")
                    //                    let outputURL = documentURL.appendingPathComponent(fileName).appendingPathExtension(ex!)
                    print("OutURL->\(outputURL)")
                    print("fileSizeString->\(item.fileSizeString)")
                    print("fileSize->\(item.fileSize)")
                    
                    dict.setValue(fileType, forKey: "fileType")
                    dict.setValue(ex, forKey: "extention")
                    dict.setValue(fileName, forKey: "title")
                    dict.setValue(outputURL, forKey: "storagePath")
                    dict.setValue(item.fileSize, forKey: "size")
                    dict.setValue(item.isCloudItem, forKey: "isCloudItem")
                    arrFetchedMedia.add(dict)
                    
                    //Delete Existing file
                    do {
                        try FileManager.default.removeItem(at: outputURL)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    exportSession?.outputURL = outputURL
                    exportSession?.exportAsynchronously(completionHandler: { () -> Void in
                        
                        if exportSession!.status == AVAssetExportSession.Status.completed  {
                            print("Export Successfull")
                            print("arr => \(self.arrFetchedMedia)")
                        } else {
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
