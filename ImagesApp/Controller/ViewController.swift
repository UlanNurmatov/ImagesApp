//
//  ViewController.swift
//  ImagesApp
//
//  Created by Ulan Nurmatov on 2/6/20.
//  Copyright © 2020 Ulan Nurmatov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photos: Photos = Photos()
    var currentPage: Int = 1
    let photosPerPage: Int = 10
    let accessKey = ["Authorization": Constants.AccessKey.accessKey]
    let cellInset: CGFloat = 10.0
    var activity = UIActivityIndicatorView()
    
    //Pagination
    var fetchingMoreData: Bool = false
    var endReached: Bool = false
    let screensForBatching: CGFloat = 2.0
    
    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        return refreshControl
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        showActivityIndicator()
        fetchPhotos(page: currentPage)
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refresher
        } else {
            collectionView.addSubview(refresher)
        }

    }
    
    func showActivityIndicator() {
        if #available(iOS 13.0, *) {
            activity.color = .label
            activity.style = .medium
        } else {
            activity.style = .gray
        }
        activity.hidesWhenStopped = true
        view.addSubview(activity)
        activity.center = view.center
        activity.startAnimating()
    }
    
    func fetchPhotos(page: Int) {
        ServerManager.shared.getPhotos(page: page, per_page: photosPerPage, header: accessKey, completion: success, error: error, networkError: showNetworkError)
    }
    
    @objc func refreshFeed() {
      currentPage = 1
      fetchPhotos(page: currentPage)
    }
    
    
    // MARK: Server response handlers
    
    //Received data
    func success(photos: Photos) {
        refresher.endRefreshing()
        activity.stopAnimating()
        self.photos = photos
        collectionView.reloadData()
    }
    
    //Received error
    func error(error: ErrorResponse) {
        activity.stopAnimating()
        refresher.endRefreshing()
        print(error.statusCode as Any)
    }
    
    //Received network error response
    func showNetworkError(message:String) {
        activity.stopAnimating()
        refresher.endRefreshing()
        let alert = UIAlertController(title: "Try Again", message: message,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style:
            UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}


// MARK: Collection View DataSource & Delegate

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
        let photoItem = photos.photos[indexPath.item]
        cell.setImage(photoInfo: photoItem)
        return cell
    }
    
    //Get more data when scrollView reaches the bottom
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        if offsetY > contentHeight - scrollView.frame.size.height * screensForBatching {
            if !fetchingMoreData && !endReached {
                fetchingMoreData = true
                ServerManager.shared.getPhotos(page: currentPage + 1, per_page: photosPerPage, header: accessKey, completion: appendFeed, error: error, networkError: showNetworkError)
            }
        }
    }
    
    func appendFeed(photos: Photos) {
        
        //If received empty array it means that we reached the end
        if photos.photos.isEmpty {
             endReached = true
             fetchingMoreData = false
            return
        }
        //Reached the last page
        if photos.photos.count < photosPerPage {
            self.photos.photos.append(contentsOf: photos.photos)
            endReached = true
             UIView.performWithoutAnimation {
                 collectionView.reloadSections(IndexSet(integer: 0))
             }
             fetchingMoreData = false
           } else {
        //Appended new photos. May append more."
            self.photos.photos.append(contentsOf: photos.photos)
            currentPage = currentPage + 1
            UIView.performWithoutAnimation {
               collectionView.reloadSections(IndexSet(integer: 0))
           }
            fetchingMoreData = false
        }
    }
    
}

// MARK: Collection View Delegate FlowLayout

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem + 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
}

// MARK: Device orientation change handler

extension ViewController {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
               if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
               let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
               let availableWidth = collectionView.frame.width - paddingSpace
               let widthPerItem = availableWidth / itemsPerRow
               layout.itemSize = CGSize(width: widthPerItem, height: widthPerItem + 100)
               layout.invalidateLayout()
           }
    }
    
}
    


