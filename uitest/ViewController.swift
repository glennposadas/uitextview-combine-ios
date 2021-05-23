//
//  ViewController.swift
//  uitest
//
//  Created by Glenn Posadas on 5/23/21.
//

import Combine
import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var voiceTextView: UITextView!
  
  @IBOutlet weak var label: UILabel!
  let vm = VM()
  
  var cancellables = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textView
      .textPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: \.ttt1, on: vm)
      .store(in: &cancellables)
    
    voiceTextView
      .textPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: \.ttt2, on: vm)
      .store(in: &cancellables)
    
    vm.$ttt2
      .assign(to: \UITextView.text!, on: voiceTextView)
      .store(in: &cancellables)
    
    vm.state
      .sink { [unowned self] state in
        switch state {
        case let .typingOrListening(text, _):
          label.text = text
          
        case .paused:
          break
        }
      }
      .store(in: &cancellables)
    
    
  }
  
  @IBAction func appendVoiceValueToFinalValue(_ sender: Any) {
    vm.appendVoiceToFinalValue()
  }
}

enum State {
  /// Currently listening or capturing thoughts - either by typing or voice.
  /// Has associated values of text value and number of characters
  case typingOrListening(String, Int)
  /// Currently paused - not typing and not capturing thoughts by speech.
  case paused
}

class VM: NSObject {
  var state = CurrentValueSubject<State, Never>(.typingOrListening("", 0))
   
  var cancellables = Set<AnyCancellable>()
  
  @Published var ttt1: String = ""
  @Published var ttt2: String = ""
  
  func appendVoiceToFinalValue() {
    ttt1 += " \(ttt2)"
    ttt2 = ""
  }
  
  override init() {
    super.init()
    
    $ttt1.sink { [unowned self] str in
      print("TEST FROM VM: \(str)")
      state.send(.typingOrListening(str, str.count))
    }
    .store(in: &cancellables)
  }
  
}


extension UITextView {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: self)
            .compactMap { $0.object as? UITextView }
            .compactMap(\.text)
            .eraseToAnyPublisher()
    }
}
