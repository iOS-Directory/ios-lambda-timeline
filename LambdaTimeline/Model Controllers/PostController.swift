//
//  PostController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import MapKit

class PostController {
    
    //FIXME: Handle the geoTag
    func createPost(with title: String, ofType mediaType: MediaType, mediaData: Data?, dataURL: URL?, ratio: CGFloat? = nil, geoTag: CLLocationCoordinate2D?,  completion: @escaping (Bool) -> Void = { _ in }) {
        
        guard let currentUser = Auth.auth().currentUser,
            let author = Author(user: currentUser) else { return }
        
        if mediaType == .image{
            guard let mediaData = mediaData else { return }
            
        store(mediaData: mediaData, mediaType: mediaType, geoTag: geoTag) { (mediaURL) in
            
            guard let mediaURL = mediaURL else { completion(false); return }
            
            guard let lon = geoTag?.longitude else { completion(false); return }
            
            guard let lat = geoTag?.latitude else { completion(false); return }
            
            let imagePost = Post(title: title, mediaURL: mediaURL, ratio: ratio, mediaType: mediaType, author: author, lon: lon, lat: lat)
            
            self.postsRef.childByAutoId().setValue(imagePost.dictionaryRepresentation) { (error, ref) in
                if let error = error {
                    NSLog("Error posting image post: \(error)")
                    completion(false)
                }
                completion(true)
            }
        }
        }else{
            guard let dataURL = dataURL else { return }
            
            storeVideo(mediaURL: dataURL, mediaType: mediaType, geoTag: geoTag ) { (mediaURL)  in
                
                guard let mediaURL = mediaURL else { completion(false); return }
                
                guard let lon = geoTag?.longitude else { completion(false); return }
                guard let lat = geoTag?.latitude else { completion(false); return }
                
                let videoPost = Post(title: title, mediaURL: mediaURL, ratio: ratio, mediaType: mediaType, author: author, lon: lon, lat: lat)
                
                self.postsRef.childByAutoId().setValue(videoPost.dictionaryRepresentation) { (error, ref) in
                    if let error = error {
                        NSLog("Error posting image post: \(error)")
                        completion(false)
                    }
                    
                    completion(true)
                }
            }
        }
    }
    
    func addComment(with text: String?, audioURL: URL?, to post: inout Post) {
        
        guard let currentUser = Auth.auth().currentUser,
            let author = Author(user: currentUser) else { return }
        
        let comment = Comment(text: text, audioURL: audioURL, author: author)
        post.comments.append(comment)
        
        savePostToFirebase(post)
    }

    func observePosts(completion: @escaping (Error?) -> Void) {
        
        postsRef.observe(.value, with: { (snapshot) in
            
            guard let postDictionaries = snapshot.value as? [String: [String: Any]] else { return }
            
            var posts: [Post] = []
            
            for (key, value) in postDictionaries {
                
                guard let post = Post(dictionary: value, id: key) else { continue }
                
                posts.append(post)
            }
            
            self.posts = posts.sorted(by: { $0.timestamp > $1.timestamp })
            
            completion(nil)
            
        }) { (error) in
            NSLog("Error fetching posts: \(error)")
        }
    }
    
    func savePostToFirebase(_ post: Post, completion: (Error?) -> Void = { _ in }) {
        
        guard let postID = post.id else { return }
        
        let ref = postsRef.child(postID)
        
        ref.setValue(post.dictionaryRepresentation)
    }

    private func store(mediaData: Data, mediaType: MediaType, geoTag: CLLocationCoordinate2D?, completion: @escaping (URL?) -> Void) {
        
        let mediaID = UUID().uuidString
        
        let mediaRef = storageRef.child(mediaType.rawValue).child(mediaID)
        
        let uploadTask = mediaRef.putData(mediaData, metadata: nil) { (metadata, error) in
            if let error = error {
                NSLog("Error storing media data: \(error)")
                completion(nil)
                return
            }
            
            if metadata == nil {
                NSLog("No metadata returned from upload task.")
               completion(nil)
                return
            }
            
            mediaRef.downloadURL(completion: { (url, error) in
                
                if let error = error {
                    NSLog("Error getting download url of media: \(error)")
                }
                
                guard let url = url else {
                    NSLog("Download url is nil. Unable to create a Media object")
                    
                    completion(nil)
                    return
                }
                
                completion(url)
            })
        }
        
        uploadTask.resume()
    }
    
    var posts: [Post] = []
    let currentUser = Auth.auth().currentUser
    let postsRef = Database.database().reference().child("posts")
    
    let storageRef = Storage.storage().reference()
    
    
    
    private func storeVideo(mediaURL: URL, mediaType: MediaType, geoTag: CLLocationCoordinate2D?, completion: @escaping (URL? ) -> Void) {
        
        let mediaID = UUID().uuidString
        
        let mediaRef = storageRef.child(mediaType.rawValue).child(mediaID)
        
        guard let meta = geoTag else { return }
        
        let metaData = getLocationMetaData(geoTag: meta)
        
        let uploadTask = mediaRef.putFile(from: mediaURL, metadata: metaData) { (metadata, error) in
            
            if let error = error {
                NSLog("Error storing media data: \(error)")
                completion(nil)
                return
            }
            
            if metadata == nil {
                NSLog("No metadata returned from upload task.")
                completion(nil)
                return
            }
            
            mediaRef.downloadURL(completion: { (url, error) in
                
                if let error = error {
                    NSLog("Error getting download url of media: \(error)")
                }
                
                guard let url = url else {
                    NSLog("Download url is nil. Unable to create a Media object")
                    
                    completion(nil)
                    return
                }
                
            
                
                completion(url)
            })
        }
        
        uploadTask.resume()
    }
    
    private func getLocationMetaData(geoTag: CLLocationCoordinate2D) -> StorageMetadata {
        let lon = geoTag.longitude
        let lat = geoTag.latitude
        let meta = StorageMetadata(dictionary: ["longitude" : lon, "latitude": lat])
        
        return meta!
    }
    
}
