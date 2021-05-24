//
//  ViewController.swift
//  DemoRecorder
//
//  Created by Pyramidions on 24/05/21.
//

import UIKit
import AVKit
import MobileCoreServices
import AVFAudio
import AVFoundation
import ReplayKit

class ViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate,UITextFieldDelegate {

    @IBOutlet var audioPlayBtn: UIButton!
    @IBOutlet var audioRecBtn: UIButton!
    @IBOutlet var screenPlayBtn: UIButton!
    @IBOutlet var screenRecBtn: UIButton!
    @IBOutlet var videoPlayBtn: UIButton!
    @IBOutlet var videoRecBtn: UIButton!
    @IBOutlet var mainTextField: UITextField!
    
    var videoAndImageReview = UIImagePickerController()
    var videoURL: URL?
    var soundRecorder : AVAudioRecorder?
    var soundPlayer : AVAudioPlayer?
    var fileName : String = "audioFile.m4a"
    let recorder = RPScreenRecorder.shared()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        audioRecBtn.layer.borderColor = UIColor.black.cgColor
        audioRecBtn.layer.borderWidth = 1
        audioPlayBtn.layer.borderColor = UIColor.white.cgColor
        audioPlayBtn.layer.borderWidth = 1
        
        screenPlayBtn.layer.borderColor = UIColor.black.cgColor
        screenPlayBtn.layer.borderWidth = 1
        screenRecBtn.layer.borderColor = UIColor.white.cgColor
        screenRecBtn.layer.borderWidth = 1

        videoRecBtn.layer.borderColor = UIColor.black.cgColor
        videoRecBtn.layer.borderWidth = 1
        videoPlayBtn.layer.borderColor = UIColor.white.cgColor
        videoPlayBtn.layer.borderWidth = 1
        
        setupRecorder()
        self.mainTextField.delegate = self

    }
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard
            let mediaType = info[UIImagePickerControllerMediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerControllerMediaURL] as? URL,
            UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
            else {
                return
        }
        
        // Handle a movie capture
        UISaveVideoAtPathToSavedPhotosAlbum(
            url.path,
            self,
            #selector(video(_:didFinishSavingWithError:contextInfo:)),
            nil)
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was Saved" : "Video Failed to Save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
  

    @IBAction func videoRecAction(_ sender: Any)
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            print("Camera Available")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera UnAvaialable")
        }
    }
    
    @IBAction func videoPlayAction(_ sender: Any)
    {
        videoAndImageReview.sourceType = .savedPhotosAlbum
        videoAndImageReview.delegate = self
        videoAndImageReview.mediaTypes = ["public.movie"]
        present(videoAndImageReview, animated: true, completion: nil)
    }
    
    func videoAndImageReview(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        videoURL = info[UIImagePickerControllerMediaURL] as? URL
        print("videoURL:\(String(describing: videoURL))")
        self.dismiss(animated: true, completion: nil)
    }
    func getDocumentsDirector() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setupRecorder() {
        let audioFilename = getDocumentsDirector().appendingPathComponent(fileName)
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless ,
                              AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey : 320000,
                              AVNumberOfChannelsKey : 2,
                              AVSampleRateKey : 44100.2 ] as [String : Any]
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting)
            soundRecorder?.delegate = self
            soundRecorder?.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        let audioFilename = getDocumentsDirector().appendingPathComponent(fileName)
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            soundPlayer?.delegate = self
            soundPlayer?.prepareToPlay()
            soundPlayer?.volume = 1.0
        } catch {
            print(error)
        }

    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        audioPlayBtn.isEnabled = true
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayBtn.setTitle("Play", for: .normal)
    }
    @IBAction func screenRecAction(_ sender: Any)
    {
        recorder.startRecording { (error) in
            if let error = error {
                print(error)
            }
            let dialogMessage = UIAlertController(title: "Great !!", message: "Select Stop in Screen Recording and See the Recorded Video \n Type Some thing in Textfield to See the Recording and Press Stop", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
             })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)

            self.screenPlayBtn.setTitle("Stop", for: .normal)
        }
    }
    
    @IBAction func screenPlayAction(_ sender: Any)
    {
        recorder.stopRecording { (previewVC, error) in
            if let previewVC = previewVC {
                previewVC.previewControllerDelegate = self
                self.present(previewVC, animated: true, completion: nil)
            }
            
            if let error = error
            {
                let dialogMessage = UIAlertController(title: "OOPS", message: "Please Record the VIDEO?", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                 })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                print(error)
            }
        }
    }
    
    @IBAction func audioRecBtn(_ sender: Any)
    {
        if audioRecBtn.titleLabel?.text == "Record" {
            soundRecorder?.record()
            audioRecBtn.setTitle("Stop", for: .normal)
        } else {
            soundRecorder?.stop()
            audioRecBtn.setTitle("Record", for: .normal)
        }
    
    }

    @IBAction func audioPlayBtn(_ sender: Any)
    {
        if audioPlayBtn.titleLabel?.text == "Play" {
            setupPlayer()
            soundPlayer?.play()
            audioPlayBtn.setTitle("Stop", for: .normal)
        } else {
            soundPlayer?.stop()
            audioPlayBtn.setTitle("Play", for: .normal)
        }

    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           self.view.endEditing(true)
           return false
       }
}
extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        self.screenPlayBtn.setTitle("Play", for: .normal)
        dismiss(animated: true, completion: nil)
    }
}
