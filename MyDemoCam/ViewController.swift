//
//  ViewController.swift
//  MyDemoCam
//
//  Created by Prasanth Podalakur on 15/04/19.
//  Copyright © 2019 Prasanth Podalakur. All rights reserved.
//

import UIKit
import MyCameraSDK


struct PagedCharacters: Codable {
    let info: Info
    let results: [Results]
    
}
struct Info: Codable {
    let count: Int
    let pages: Int
    let next: String
    let prev: String
}

struct Results: Codable {
    let name: String
    let status: String
    let species: String
}
class ViewController: UIViewController,MyCameraSDKDelegate {
  
    
   
    
    
    
   
    var aryDownloadedData:[Results]?
    var nextPageUrl:String!

    var pagingArray = [String]()
    var myCamVC = MyCameraVC()
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var mainTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getIntitalRickAndMortyData()
        self.mainTableView.dataSource = self
        self.mainTableView.delegate = self
       
    }

    
    
    func getIntitalRickAndMortyData(){
        aryDownloadedData = []
        //here first page is next page
        nextPageUrl = "https://rickandmortyapi.com/api/character/"
        getRickAndMortyData()
    }
    
    func getRickAndMortyData() {
        
        //construct the url, use guard to avoid nonoptional
        guard let urlObj = URL(string: nextPageUrl) else
        { return }
        
        //fetch data
        URLSession.shared.dataTask(with: urlObj) {[weak self](data, response, error) in
            
            //to avoid non optional in JSONDecoder
            guard let data = data else { return }
            
            do {
                //decode object
                let downloadedRickAndMorty = try JSONDecoder().decode(PagedCharacters.self, from: data)
                self?.aryDownloadedData?.append(contentsOf: downloadedRickAndMorty.results)
                self?.nextPageUrl = downloadedRickAndMorty.info.next
                
                DispatchQueue.main.async {
                    self?.mainTableView.reloadData()
                }
                print(self?.aryDownloadedData as Any)
                
            } catch {
                print(error)
                
            }
            
            }.resume()
        
    }
    
    
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
       
        CommonUtil.openCameraView(self, delegate: self)
    }
    
    func didFinishCapture(capturePhoto: UIImage?) {
        if capturePhoto != nil {
            print("get images")
            self.previewImageView.image = capturePhoto
        }else{
           print("no images")
        }

    }

    func didFinishVideoCapture(outputFileURL: URL?, isError: Error?) {
        if isError != nil {

        }else{
             print("video URL ->>>\(outputFileURL)")
        }

    }
}
//MARK:- Paging for tableview
extension ViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.aryDownloadedData?.count ?? 0
    }
    
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let count = aryDownloadedData?.count, count>1{
            let lastElement = count - 1
            if indexPath.row == lastElement {
                getRickAndMortyData()
            }
        }
         let cell = self.mainTableView.dequeueReusableCell(withIdentifier: "pagingTVC") as! pagingTVC
         cell.itemTitleLabel.text = "Name: " + (self.aryDownloadedData?[indexPath.row].name ?? "default")
         return cell
    }
}
