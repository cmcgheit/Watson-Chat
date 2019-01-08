//
//  ViewController.swift
//  Watson-Chat
//
//  Created by C McGhee on 6/18/17.
//  Copyright © 2017 C McGhee. All rights reserved.
//

import Foundation
import UIKit
import AssistantV1
import MessageKit
import MapKit
import BMSCore

class ViewController: MessagesViewController {
    
    fileprivate let kCollectionViewCellHeight: CGFloat = 12.5
    
    var messageList: [AssistantMessages] = []
    
    var now = Date()
    
    var assistant: Assistant?
    var context: Context?
    
    var workspaceID: String?
    
    // Users
    var current = Sender(id: "123456", displayName: "You")
    let watson = Sender(id: "654321", displayName: "Watson")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate Assistant Instance
        self.instantiateAssistant()
        
        // Registers data sources and delegates + setup views
        self.setupMessagesKit()
        
        // Register observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        
    }
    
    // MARK: - Setup Methods
    // Method to instantiate assistant service
    func instantiateAssistant() {
        
        // Activity Spinner?
        
        // Credentials
        guard let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let configuration = NSDictionary(contentsOfFile: configurationPath) else {
                
                showAlert(.missingCredentialsPlist)
                return
        }
        
        // API Version Date to initialize the Assistant API
        let date = "2018-02-01"
        
        // Set the Watson credentials for Assistant service from the BMSCredentials.plist
        // If using IAM authentication
        if let apikey = configuration["conversationApikey"] as? String,
            let url = configuration["conversationUrl"] as? String {
            
            // Initialize Watson Assistant object
            let assistant = Assistant(version: date, apiKey: apikey)
            
            // Set the URL for the Assistant Service
            assistant.serviceURL = url
            
            self.assistant = assistant
            
            // If using user/pwd authentication
        } else if let password = configuration["conversationPassword"] as? String,
            let username = configuration["conversationUsername"] as? String,
            let url = configuration["conversationUrl"] as? String {
            
            // Initialize Watson Assistant object
            let assistant = Assistant(username: username, password: password, version: date)
            
            // Set the URL for the Assistant Service
            assistant.serviceURL = url
            
            self.assistant = assistant
            
        } else {
            showAlert(.missingAssistantCredentials)
        }
        
        // Workspace
        if let workspaceID = configuration["workspaceID"] as? String {
            
            print("Workspace ID:", workspaceID)
            
            // Set the workspace ID Globally
            self.workspaceID = workspaceID
            
            // Ask Watson for its first message
            retrieveFirstMessage()
            
        } else {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                // Check training message
            }
            // Retrieve a list of Workspaces/default to the first one
            guard let assistant = assistant else {
                return
            }
            assistant.listWorkspaces(failure: failAssistantWithError,
                                     success: workspaceList)
        }
    }
    
    // Method to start convesation from workspace list
    func workspaceList(_ list: WorkspaceCollection) {
        
        // training model deployed
        guard let workspace = list.workspaces.first else {
            showAlert(.noWorkspacesAvailable)
            return
        }
        
        // Check if we have a workspace ID
        guard !workspace.workspaceID.isEmpty else {
            showAlert(.noWorkspaceId)
            return
        }
        
        self.workspaceID = workspace.workspaceID
        
        // Ask Watson for its first message
        retrieveFirstMessage()
        
    }
    
    // Method to handle errors with Watson Assistant
    func failAssistantWithError(_ error: Error) {
        showAlert(.error(error.localizedDescription))
    }
    
    // MARK: - Message Kit Function
    func setupMessagesKit() {
        
        // Register datasources and delegates
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        // Configure views
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
    }
    
    // Retrieves the first message from Watson
    func retrieveFirstMessage() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            // Talking to Watson Message
        }
        
        guard let assistant = self.assistant else {
            showAlert(.missingAssistantCredentials)
            return
        }
        
        guard let workspace = workspaceID else {
            showAlert(.noWorkspaceId)
            return
        }
        
        // Initial assistant message from Watson
        assistant.message(workspaceID: workspace, failure: failAssistantWithError) { response in
            
            for watsonMessage in response.output.text {
                
                // Set current context
                self.context = response.context
                
                DispatchQueue.main.async {
                    
                    // Add message to assistant message array
                    let uniqueID = UUID().uuidString
                    let date = self.dateAddingRandomTime()
                    
                    let attributedText = NSAttributedString(string: watsonMessage,
                                                            attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                         .foregroundColor: UIColor.blue])
                    
                    // Create a Message for adding to the Message View
                    let message = AssistantMessages(attributedText: attributedText, sender: self.watson, messageId: uniqueID, date: date)
                    
                    // Add the response to the Message View
                    self.messageList.insert(message, at: 0)
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom()
                }
            }
        }
    }
    
    // Method to create a random date
    func dateAddingRandomTime() -> Date {
        let randomNumber = Int(arc4random_uniform(UInt32(10)))
        var date: Date?
        if randomNumber % 2 == 0 {
            date = Calendar.current.date(byAdding: .hour, value: randomNumber, to: now) ?? Date()
        } else {
            let randomMinute = Int(arc4random_uniform(UInt32(59)))
            date = Calendar.current.date(byAdding: .minute, value: randomMinute, to: now) ?? Date()
        }
        now = date ?? Date()
        return now
    }
    
    // Method to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ error: AssistantError) {
        // Log the error to the console
        print(error)
        
        DispatchQueue.main.async {
            
            // If an alert is not currently being displayed
            if self.presentedViewController == nil {
                // Set alert properties
                let alert = UIAlertController(title: error.alertTitle,
                                              message: error.alertMessage,
                                              preferredStyle: .alert)
                // Add an action to the alert
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
                // Show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Method to retrieve assistant avatar
    func getAvatarFor(sender: Sender) -> Avatar {
        switch sender {
        case current:
            return Avatar(image: UIImage(named: "avatar_small"), initials: "GR")
        case watson:
            return Avatar(image: UIImage(named: "watson_avatar"), initials: "WAT")
        default:
            return Avatar()
        }
    }
}

// MARK: - MessagesDataSource
extension ViewController: MessagesDataSource {
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func currentSender() -> Sender {
        return current
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        struct AssistantDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter
            }()
        }
        let formatter = AssistantDateFormatter.formatter
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
}

// MARK: - MessagesDisplayDelegate
extension ViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
    // MARK: - All Messages
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let avatar = getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
    }
    
    // MARK: - Location Messages
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "pin")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
}

// MARK: - MessagesLayoutDelegate
extension ViewController: MessagesLayoutDelegate {
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }
    
    // MARK: - Location Messages
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
    
}

// MARK: - MessageCellDelegate
extension ViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
    }
    
    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
}

// MARK: - MessageLabelDelegate
extension ViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
}

// MARK: - MessageInputBarDelegate
extension ViewController: MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        
        guard let assist = assistant else {
            showAlert(.missingAssistantCredentials)
            return
        }
        
        guard let workspace = workspaceID else {
            showAlert(.noWorkspaceId)
            return
        }
        
        let attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
        let id = UUID().uuidString
        let message = AssistantMessages(attributedText: attributedText, sender: currentSender(), messageId: id, date: Date())
        messageList.append(message)
        inputBar.inputTextView.text = String()
        messagesCollectionView.insertSections([messageList.count - 1])
        messagesCollectionView.scrollToBottom()
        
        // cleanup text that gets sent to Watson, which doesn't care about whitespace or newline characters
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: ". ")
        
        // Lets pass the indent to Watson Assistant and see what the response is ?
        // Get response from Watson based on user text create a message Request first
        let messageRequest = MessageRequest(input: InputData(text:cleanText), context: self.context)
        
        // Call the Assistant API
        assist.message(workspaceID: workspace, request: messageRequest, failure: failAssistantWithError) { response in
            
            for watsonMessage in response.output.text {
                guard !watsonMessage.isEmpty else {
                    continue
                }
                // Set current context
                self.context = response.context
                DispatchQueue.main.async {
                    
                    let attributedText = NSAttributedString(string: watsonMessage, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
                    let id = UUID().uuidString
                    let message = AssistantMessages(attributedText: attributedText, sender: self.watson, messageId: id, date: Date())
                    self.messageList.append(message)
                    inputBar.inputTextView.text = String()
                    self.messagesCollectionView.insertSections([self.messageList.count - 1])
                    self.messagesCollectionView.scrollToBottom()
                    
                }
            }
        }
    }
}




