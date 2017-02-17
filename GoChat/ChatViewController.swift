//
//  ChatViewController.swift
//  GoChat
//
//  Created by Kristoffer Nielsen on 14/02/2017.
//  Copyright © 2017 Kristoffer Nielsen. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import SDWebImage

class ChatViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    
    var avatarDict = [String: JSQMessagesAvatarImage]()
    
    var messageRef = FIRDatabase.database().reference().child("messages")
    let photoCache = NSCache<AnyObject, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            
            self.senderId = currentUser.uid
            
            self.senderDisplayName = currentUser.email
            
        }
        
        observeMessages()
    }
    
    func observeUsers(id: String) {
        FIRDatabase.database().reference().child("users").child(id).observe(.value, with: {(snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let avatarUrl = dict["profileUrl"] as! String
                self.setupAvatar(url: avatarUrl, messageId: id)
            }
        })
    }
    
    func setupAvatar(url: String, messageId: String) {
        if url != "" {
            let fileUrl = NSURL(string: url)
            let data = NSData(contentsOf: fileUrl as! URL)
            let image = UIImage(data: data as! Data)
            let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
            avatarDict[messageId] = userImg
        } else {
            avatarDict[messageId] = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "profileImage"), diameter: 30)
        }
        
        collectionView.reloadData()
    }
    
    func observeMessages() {
        messageRef.observe(.childAdded, with: {(snapshot) in
            if let dict = snapshot.value as? [String: AnyObject] {
                let senderId = dict["senderId"] as! String
                let senderName = dict["senderName"] as! String
                let mediaType = dict["mediaType"] as! String
                
                self.observeUsers(id: senderId)
                
                if mediaType == "TEXT" {
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                } else if mediaType == "PHOTO" {
                    let photo = JSQPhotoMediaItem(image: nil)
                    
                    let fileUrl = dict["fileUrl"] as! String
                    let downloader = SDWebImageDownloader.shared()
                    downloader.downloadImage(with: NSURL(string: fileUrl) as URL?, options: [], progress: nil, completed: { (image, data, error, finished) in
                        DispatchQueue.main.async() {
                            photo?.image = image
                            
                            self.collectionView.reloadData()
                        }
                    })
                    
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                    
                    if self.senderId == senderId {
                        photo?.appliesMediaViewMaskAsOutgoing = true
                    } else {
                        photo?.appliesMediaViewMaskAsOutgoing = false
                    }
                } else if mediaType == "VIDEO" {
                    let fileUrl = dict["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video as URL!, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                    
                    if self.senderId == senderId {
                        videoItem?.appliesMediaViewMaskAsOutgoing = true
                    } else {
                        videoItem?.appliesMediaViewMaskAsOutgoing = false
                    }
                }
                
                self.collectionView.reloadData()
                self.scrollToBottom(animated: true)
            }
        })
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "mediaType": "TEXT"]
        
        newMessage.setValue(messageData)
        self.finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("did press accessory button")
        
        let sheet = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default, handler: { (alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeImage)
        })
        let videoLibrary = UIAlertAction(title: "Video Library", style: .default, handler: {(alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeMovie)
        })
        
        
        sheet.addAction(cancel)
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    func getMediaFrom(type: CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]

        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if (message.senderId == self.senderId) {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: .black)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .red)
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        return avatarDict[message.senderId]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        let message = messages[indexPath.item]
        if message .isMediaMessage {
            if let mediaItem = message.media as? JSQVideoMediaItem {
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                
                self.present(playerViewController, animated: true, completion: nil)
            }
            
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutDidTapped(_ sender: Any) {
        print("logout did tapped")
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let error {
            print(error)
        }
        
        //switch view by setting navigation controller as root view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.window?.rootViewController = loginVC
    }
    
    func sendMedia(picture: UIImage?, video: NSURL?) {
        if let picture = picture {
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            let data = UIImageJPEGRepresentation(picture, 1)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            
            FIRStorage.storage().reference().child(filePath).put(data!, metadata: metadata, completion: {(metadata, error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return;
                }
                
                let fileUrl = metadata?.downloadURLs![0].absoluteString
                
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "PHOTO"]
                
                newMessage.setValue(messageData)
            })
        } else if let video = video {
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)"
            let data = NSData(contentsOf: video as URL)
            let metadata = FIRStorageMetadata()
            metadata.contentType = "video/mp4"
            
            FIRStorage.storage().reference().child(filePath).put(data! as Data, metadata: metadata, completion: {(metadata, error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return;
                }
                
                let fileUrl = metadata?.downloadURLs![0].absoluteString
                
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "mediaType": "VIDEO"]
                
                newMessage.setValue(messageData)
            })
        }
    }
    
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("did finish picking image")
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(picture: picture, video: nil)
        } else if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
            sendMedia(picture: nil, video: video)
        }
        
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}
