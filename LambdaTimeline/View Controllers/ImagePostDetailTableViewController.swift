//
//  ImagePostDetailTableViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/14/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class ImagePostDetailTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else { return }
        
        title = post?.title
        
        imageView.image = image
        
        titleLabel.text = post.title
        authorLabel.text = post.author.displayName
    }
    
    // MARK: - Table view data source
    
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (post?.comments.count ?? 0) - 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        
        let comment = post?.comments[indexPath.row + 1]
        
        cell.textLabel?.text = comment?.text
        cell.detailTextLabel?.text = comment?.author.displayName
        
        return cell
    }
    
    var post: Post!
    var postController: PostController!
    var imageData: Data?
    
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageViewAspectRatioConstraint: NSLayoutConstraint!
}
