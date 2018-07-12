//
//  ViewController.swift
//  SpeechToText
//
//  Created by Artem Klimenko on 13.07.18.
//  Copyright © 2018 velkonost. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var recordButton: UIButton!
	
	let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ru"))
	let audioEngine = AVAudioEngine()
	
	var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
	var recognitionTask: SFSpeechRecognitionTask?
	
	
	
	@IBAction func recordButtonTapped(_ sender: UIButton) {
		if audioEngine.isRunning {
			audioEngine.stop()
			
			recognitionRequest?.endAudio()
			recordButton.isEnabled = false
			recordButton.setTitle("Начать запись", for: .normal)
		} else {
			startRecording()
			recordButton.setTitle("Остановить запись", for: .normal)
		}
	}

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		recordButton.isEnabled = false
		
		speechRecognizer?.delegate = self
		
		SFSpeechRecognizer.requestAuthorization { status in
			var buttonState = false
			
			switch status {
			case .authorized:
				buttonState = true
			case .denied, .notDetermined, .restricted: break
			}
			
			DispatchQueue.main.async {
				self.recordButton.isEnabled = buttonState
			}
			
		}
	}
	
	func startRecording() {
		
		if recognitionTask != nil {
			recognitionTask?.cancel()
			recognitionTask = nil
		}
		
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(AVAudioSessionCategoryRecord)
			try audioSession.setMode(AVAudioSessionModeMeasurement)
			try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
		} catch {
			print(error.localizedDescription)
		}
		
		recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
		
		let inputNode = audioEngine.inputNode
		
		guard let recognitionRequest = recognitionRequest else { return }
		
		recognitionRequest.shouldReportPartialResults = true
		
		recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
			result, error in
			
			var isFinal = false
			
			if result != nil {
				self.textView.text = result?.bestTranscription.formattedString
				isFinal = (result?.isFinal)!
			}
			
			if error != nil || isFinal {
				self.audioEngine.stop()
				inputNode.removeTap(onBus: 0)
				
				self.recognitionRequest = nil
				self.recognitionTask = nil
				
				self.recordButton.isEnabled = true
			}
		}
		
		let format = inputNode.outputFormat(forBus: 0)
		
		inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
			self.recognitionRequest?.append(buffer)
		}
		
		audioEngine.prepare()
		
		do {
			try audioEngine.start()
		} catch {
			print(error.localizedDescription)
		}
		
		textView.text = "Помедленнее...Я записываю..."
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

extension ViewController: SFSpeechRecognizerDelegate {
	func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
		if available {
			recordButton.isEnabled = true
		} else {
			recordButton.isEnabled = false
		}
	}
}

