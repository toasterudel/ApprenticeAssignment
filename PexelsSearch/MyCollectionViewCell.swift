//
//  MyCollectionViewCell.swift
//  PexelsSearch
//
//  Created by Chris Rudel on 6/14/20.
//  Copyright © 2020 Chris Rudel. All rights reserved.
//

import UIKit

class MyCollectionViewCell: UICollectionViewCell {
    
    //https://stackoverflow.com/questions/43543058/turn-image-link-into-uiimageview-swift
    
    @IBOutlet weak var imageView: UIImageView!

    
    func configure(with link: String){
        if let url = URL(string: link){
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
