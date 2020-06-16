//
//  ViewController.swift
//  PexelsSearch
//
//  Created by Chris Rudel on 6/13/20.
//  Copyright © 2020 Chris Rudel. All rights reserved.
//

import UIKit

// api key 563492ad6f91700001000001de05a172d02045b08e3214137131e055

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBAction func textInputFinished(_ sender: UITextField) {
    }
    /*
        occasionally there are issues with onChange for textInput because
        characters are being input before the request can be fully processed.
        this can be mitigated to switching it to onFinish. however that was not
        in line with the outlined assignment specifications, so i
        kept it as onChange
     */
    @IBAction func textInputChanged(_ sender: UITextField) {
        pageNum = 1
        if canMakeRequest{
            callApi(pageNum)
        }
    }
    @IBAction func pexelsLabel(_ sender: Any) {
        if let url = URL(string: "https://www.pexels.com"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

    }
    var imageData: [Dictionary<String, String>] = []
    var imageSegueNum: Int = 0 // keeping track of which image picked
    let refreshControl = UIRefreshControl()
    var canMakeRequest: Bool = true
    let requestLimit: Int = 100 // requests before stops
    var numSearchResults: Int = 0
    var pageNum: Int = 1 // starts at 1 because page 0 and 1 are the same on page request
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.textInput.delegate = self
        
        // loading search image into textInput
        let image = UIImage(named: "search")
        let searchImage = UIImageView(frame: CGRect(x: 10, y: 5, width: 20, height: 20))
        searchImage.image = image
        let iconContainerView = UIView(frame: CGRect(x: 20, y: 0, width: 30, height: 30))
        iconContainerView.addSubview(searchImage)
        textInput.leftViewMode = .always
        textInput.leftView = iconContainerView
        
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.textInput.resignFirstResponder()
        return true
    }
    
    //  sets up url with headers to be requested via GET request
    func callApi(_ num: Int) -> Void {
        if num == 1{
            self.imageData.removeAll()
        }
        // url needs to be encoded in case user inputs multiple words in search
        let urlStr = "https://api.pexels.com/v1/search?query=\(textInput.text ?? "")&per_page=30&page=\(num)"
        let encodedUrl = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        let url = URL(string: encodedUrl ?? "")

        guard let reqURL = url else {return}
        let authKey = "563492ad6f91700001000001de05a172d02045b08e3214137131e055"
        
        var req = URLRequest(url: reqURL)
        req.httpMethod = "GET"
        req.addValue(authKey, forHTTPHeaderField: "Authorization")
        fetchData(with: req)
    }
    
    
    func fetchData(with req: URLRequest) {
        // makes request asynchronously, don't know when going to return
        let task = URLSession.shared.dataTask(with: req) { (data, response, err) in
            if let error = err {
                print("Error occured: \(error)")
                return
            }

            if let res = response as? HTTPURLResponse{
//                print(res)
                let remainingReq = res.value(forHTTPHeaderField: "x-ratelimit-remaining")
                let remainingReqInt = Int(remainingReq ?? "0")
//                print(remainingReqInt ?? 0)
                /*
                    if the response returns that there are less requests remaining
                    than we previously defined, stop the app from making additional requests
                 */
                if remainingReqInt ?? 0 < self.requestLimit {
                    self.canMakeRequest = false
                    return
                }
            }

            if let data = data, let _ = String(data: data, encoding: .utf8){
                do{
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                        /*
                            lets us know the total number of pictures available
                            later if we reach the total, we stop asking for more picutres
                        */
                        self.numSearchResults = json["total_results"] as? Int ?? 0
                        if let photos = json["photos"] as? Array<Dictionary<String, Any>> {
                            for photo in photos{
                                var imgInfo: Dictionary<String, String> = [:]
                                imgInfo["photographer"] = photo["photographer"] as? String ?? ""
                                imgInfo["photographer_url"] = photo["photographer_url"] as? String ?? ""
                                if let src = photo["src"] as? Dictionary<String, String>{
                                    /*
                                        we ask for "large" in addition to "original" because
                                        the original image size is too large (typically
                                        over 1Mb). the large photo allows the photos to
                                        be stored in system cache by default. pictures stored
                                        in cache are good to limit number of requests
                                     */
                                    imgInfo["large"] = src["large"] ?? ""
                                    imgInfo["original"] = src["original"] ?? ""
                                }
                                self.imageData.append(imgInfo)
                            }
                        }
                    }
                }catch let parseError{
                    print("JSON parse err: \(parseError.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                // collectionview can only be refreshed on the main thread
                self.collectionView.reloadData()
            }
        }
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
            transferring imageData from this ViewController to the next
         */
        let vc = segue.destination as! DetailViewController
        vc.imageData = imageData[imageSegueNum]
    }

    
    /*
     taken from: https://stackoverflow.com/questions/51282164/how-to-add-pagination-in-uicollectionview-in-swift
     */
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if(indexPath.row == imageData.count - 1){
            /*
                the if statement prevents it from continually refreshing
                it is checking to make sure we have not reached the total
                number of pictures available
            */
            if(imageData.count < numSearchResults){
                pageNum += 1
                callApi(pageNum)
            }
        }
    }


}
extension ViewController: UICollectionViewDelegate{
    // this function executes when a user taps on an image in the collectionview
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        // we take note of which image we pressed so we know which data to send
        imageSegueNum = indexPath.row
        performSegue(withIdentifier: "showDetail", sender: self)
    }
}

extension ViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageData.count
    }
    
    /*
        this method is responsible for creating, configuring, and returning the appropriate
        cell for the given item. it calls upon a customized configuration of
        UICollectionViewCell located in MyCollectionViewCell.swift, and returns it
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell =  UICollectionViewCell()
        
        if let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MyCollectionViewCell{
            imageCell.configure(with: imageData[indexPath.row]["large"] ?? "")
            cell = imageCell
        }
        
        return cell
    }
}

/*
    this extension allows us to create a grid-based layout
 */
extension ViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        /*
            here we se the columns dynamically to be 1/3 the size of our collectionView.
            we can do this because our collectionView has constraints binding it to the left
            and right edges of the screen.
         */
        let numColumns: CGFloat = 3
        let width = collectionView.frame.size.width
        let insets: CGFloat = 5
        let spacing: CGFloat = 5
        return CGSize(width: (width / numColumns) - (insets + spacing), height: (width / numColumns) - (insets + spacing))
    }
}

