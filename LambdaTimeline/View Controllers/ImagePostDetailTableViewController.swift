//
//  ImagePostDetailTableViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/14/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class ImagePostDetailTableViewController: UITableViewController {
    
    //MARK: - Properties
    
    var post: Post! {
        didSet{
            DispatchQueue.main.async {
                      self.tableView.reloadData()
                  }
        }
    }
    var postController: PostController!
    var imageData: Data?
    private var selectedAudioCell: UITableViewCell?
    
    private var audioPlayer: AVAudioPlayer? {
        didSet{
            audioPlayer?.delegate = self
        }
    }
    private var isPlaying: Bool {
       return audioPlayer!.isPlaying
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        try? prepareAudioSession()
    
    }
    
    //MARK: - Custom Methods
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else { return }
        
        title = post?.title
        
        imageView.image = image
        
        titleLabel.text = post.title
        authorLabel.text = post.author.displayName
    }
    
    func togglePlay() {
        if isPlaying{
            audioPlayer?.pause()
            selectedAudioCell?.imageView?.image = UIImage(systemName: "play.fill")
        }else{
            audioPlayer?.play()
            selectedAudioCell?.imageView?.image = UIImage(systemName: "pause.fill")
        }
        updateViews()
    }
    
    //MARK: - Action
    @IBAction func createComment(_ sender: Any) {
        
        let alert = UIAlertController(title: "Add a comment", message: "Write your comment below:", preferredStyle: .alert)
        
        var commentTextField: UITextField?
        
        alert.addTextField { (textField) in
            textField.placeholder = "Comment:"
            commentTextField = textField
        }
        
        let addCommentAction = UIAlertAction(title: "Add Text Comment", style: .default) { (_) in
            
            guard let commentText = commentTextField?.text else { return }
            
            self.postController.addComment(with: commentText, audioURL: nil, to: &self.post!)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        //Option to create an audio comment
        let audioComment = UIAlertAction(title: "Add Audio Comment", style: .default) { (action) in
            
             let audioCommentVC = self.storyboard?.instantiateViewController(withIdentifier: "AudioCommentVC") as! AudioCommentViewController  
 
            self.present(audioCommentVC, animated: true) {
                //Pass the post to the controller to create a new audio post
                audioCommentVC.post = self.post
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        
        alert.addAction(audioComment)
        alert.addAction(addCommentAction)
        alert.addAction(cancelAction)
        
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pullToRefresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.refreshControl?.endRefreshing()
        
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (post?.comments.count ?? 0) - 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        
        let comment = post?.comments[indexPath.row + 1]
        
        if let commentText =  comment?.text {
            cell.textLabel?.text = commentText
        }
        
        if let _ = comment?.audioURL {
            cell.imageView?.image = UIImage(systemName: "play.fill")
            cell.textLabel?.text = "Audio Comment, Tap to play!"
        }
        cell.detailTextLabel?.text = comment?.author.displayName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let comment = post?.comments[indexPath.row + 1]
        selectedAudioCell = tableView.cellForRow(at: indexPath)
        
        if let audioURL = comment?.audioURL{
            print("didSelectRowAt URL: \(audioURL)")
            do{
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                togglePlay()
            }catch{
                print("Could not find audio file: \(error), URL: \(audioURL)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapView"{
            guard let mapVC = segue.destination as? MapViewController else{return}
            mapVC.post = self.post
            
            
        }
    }
    //MARK: - Custom Methods
    func prepareAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try session.setActive(true, options: []) // can fail if on a phone call, for instance
    }
    
    //MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageViewAspectRatioConstraint: NSLayoutConstraint!
    
}

extension ImagePostDetailTableViewController: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        selectedAudioCell?.imageView?.image = UIImage(systemName: "play.fill")
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Error playing \(error)")
        }
    }
}
