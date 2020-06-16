//
//  DetailViewController.swift
//  PexelsSearch
//
//  Created by Chris Rudel on 6/14/20.
//  Copyright © 2020 Chris Rudel. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController{
    
    var imageData: Dictionary<String, String> = [:]

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var photographerButton: UIButton!
    @IBAction func photographerButton(_ sender: Any) {
        if let url = URL(string: imageData["photographer_url"] ?? ""), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // sets a outline on the bottom of the profile button
    func setButtonLine(){
//      https://stackoverflow.com/questions/31107994/how-to-only-show-bottom-border-of-uitextfield-in-swift
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: photographerButton.frame.height - 1, width: photographerButton.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.gray.cgColor
        photographerButton.layer.addSublayer(bottomLine)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let link = imageData["original"]
        photographerButton.setTitle("\(imageData["photographer"] ?? "")", for: .normal)
        setButtonLine()
        imageView.enableZoom()
        if link != ""{
            if let url = URL(string: link ?? ""){
                // asynchronously get image
                let task = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
                    if error != nil{
                        print(error ?? "")
                        return
                    }
                    DispatchQueue.main.async {
                        let image = UIImage(data: data!)
                        self.imageView.image = image
                    }
                } )
                task.resume()
            }
        }
    }
}



extension UIImageView{
    /*
       below is giving pictures functionality to be zoomed in by pinching
       https://stackoverflow.com/questions/30014241/uiimageview-pinch-zoom-swift
    */
    func enableZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZoom(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(pinchGesture)
    }
    
    @objc private func startZoom(_ sender: UIPinchGestureRecognizer){
        let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
        guard let scale = scaleResult, scale.a > 1, scale.d > 1 else {return}
        sender.view?.transform = scale
        sender.scale = 1
    }
    
}
