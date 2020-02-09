//
//  ImageCell.swift
//  ImagesApp
//
//  Created by Ulan Nurmatov on 2/7/20.
//  Copyright © 2020 Ulan Nurmatov. All rights reserved.
//

import UIKit
import Kingfisher

class ImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setImage(photoInfo: PhotoInfo) {
        guard let photo = photoInfo.src?.portrait else { return }
        let url = URL(string: photo)
        self.imageView.kf.setImage(with: url)
    }
    
}
