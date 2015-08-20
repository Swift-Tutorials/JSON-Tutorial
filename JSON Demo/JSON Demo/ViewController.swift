//
//  ViewController.swift
//  JSON Demo
//
//  Created by Yogesh Bharate on 14/08/15.
//  Copyright (c) 2015 Yogesh Bharate. All rights reserved.
//

import UIKit

public class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    var tableView:UITableView?
    var items = NSMutableArray()
    var names = NSMutableArray()
    var nameAndIcon = NSMutableDictionary()
    var avtar = NSMutableArray()
    var downloadedImages = NSMutableArray()
    var refreshControl : UIRefreshControl!
    var plist : String?
    var isNetworkAvailable : Bool = false
    var appDelegate : AppDelegate?

    
    override public func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        
        plist = appDelegate!.plist
        
        if Reachability.isConnectedToNetwork() == true{
            print("Network is available")
            isNetworkAvailable = true
        } else {
            print("Network is not available")
            isNetworkAvailable = false
            
            if ((appDelegate!.nameAndAvatar) != nil){
                nameAndIcon = appDelegate!.nameAndAvatar!
                
                if items.count == 0 {
                    for nameKey in nameAndIcon.allKeys {
//                        print("\n\n\n names = > \(nameKey)")
                        items.addObject(nameKey)
                        
                    }
                }
            }
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        let frame:CGRect = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height-100)
        self.tableView = UITableView(frame: frame)
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        self.tableView?.rowHeight = 80
        self.refreshControl = UIRefreshControl()
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action:"refreshView:", forControlEvents: UIControlEvents.ValueChanged)
        
//        var searchBar:UISearchBar = UISearchBar(frame: CGRectMake(0, 0, self.view.frame.width, 30))
        var searchBar : UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 70, width: self.view.frame.width, height: 40))
        searchBar.placeholder = "Search"
        var leftNavBarButton = UIBarButtonItem(customView:searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        
        self.tableView?.addSubview(refreshControl)
//        self.tableView?.addSubview(searchBar)
        
        
        let btn = UIButton(frame: CGRect(x: 0, y: 25, width: self.view.frame.width, height: 45))
        btn.backgroundColor = UIColor.orangeColor()
        btn.setTitle("Item List", forState: UIControlState.Normal)

        self.view.addSubview(self.tableView!)
        self.view.addSubview(btn)
        self.view.addSubview(searchBar)
        
        if isNetworkAvailable {
            self.addDummyData()
        }
    }

// MARK: - refreshView
    func refreshView(sender: AnyObject){
        
        if isNetworkAvailable {
        self.addDummyData()
        self.tableView?.reloadData()
        } else {
            self.refreshControl.endRefreshing()
            let alertController = UIAlertController(title: "Warning", message:"Network unavailable !!!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
// MARK: addDummyData
    func addDummyData() {
        RestApiManager.sharedInstance.getRandomUser { (json: JSON) in
            let results = json["data"]
            for (index: String, subJson: JSON) in results {
                let user: AnyObject = subJson["user"].object
               
                if self.refreshControl.refreshing {
                    self.refreshControl.endRefreshing()
                    self.items.removeAllObjects()
                }
                self.items.addObject(user)
                dispatch_async(dispatch_get_main_queue(),{
                    self.tableView?.reloadData()
                })
            }
        }
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print(self.items.count)
        return self.items.count;
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "CELL")
        }
        
        if isNetworkAvailable {
        
        let user:JSON =  JSON(self.items[indexPath.row])
        
        let picURL = user["avatar_image"]["url"].string

        var path = createDirectory()
        var imageName = path.stringByAppendingPathComponent(user["username"].string!)
        
        cell!.textLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        cell!.detailTextLabel?.font = UIFont(name: "HelveticaNeue", size: 12)
        cell!.detailTextLabel?.text = "Details are not available !!!"
  
        var userName = user["username"].string
        imageName = imageName.stringByAppendingString(".jpg")
        names.addObject(userName!)
        
        if  isNetworkAvailable {
            cell!.textLabel?.text = user["username"].string
            if let subTitle = user["description"]["text"].string {
                cell!.detailTextLabel?.text = subTitle
                }
        } else {
            for name in nameAndIcon {
            cell!.textLabel?.text = name.key as? String
//            print(name.key)
            }
        }
        
        let url = NSURL(string: picURL!)
        var image : UIImage = UIImage(named: "icons/loading.jpg")!
        var imageDirectory : String = "Images"
        var imageN : String = (user["username"].string!).stringByAppendingString(".jpg")
        var imageAbsolutePath : String = imageDirectory.stringByAppendingPathComponent(imageN)
        cell?.imageView?.image = image
        
        if (nameAndIcon[userName!] == nil){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                if let imageDataFromURL = NSData(contentsOfURL: url!){
                    if imageDataFromURL.writeToFile(imageName, atomically: true){
                        self.nameAndIcon.setValue(imageAbsolutePath, forKey: userName!)
                        cell?.imageView?.image = UIImage(named: imageName)
                    }
                }
            }
        } else {
            var imagePath: String = nameAndIcon.valueForKey(userName!) as! NSString as String
            var imageExactPath = getDocumentsDirectoryPath()
            imageExactPath = imageExactPath.stringByAppendingPathComponent(imagePath)
            var image : UIImage = UIImage(named: imageExactPath)!
            cell?.imageView?.image = image
        }
        
        cell?.accessoryView = nil
        appDelegate?.nameAndAvatar = nameAndIcon
        } else {
            // TODO : Add code for offline
            var nameAndIcon_ = nameAndIcon.allKeys as! [String]
            var arr: () = nameAndIcon_.sort({ $0 > $1 })
            let key = nameAndIcon_[indexPath.row]
            cell?.textLabel?.text = key// nameAndIcon.valueForKey(key as! String) as! String
           // var imagePath : String = nameAndIcon.valueForKey(key as! String) as! String
      //      var image : UIImage = UIImage(named: imagePath)!
            var imageExactPath = getDocumentsDirectoryPath()
            println("\n\n\n imagePath : \(imageExactPath)")
            var str: String = nameAndIcon.valueForKey(key as String) as! String
            imageExactPath = imageExactPath.stringByAppendingPathComponent(str)
//            println("\n\n\n \(str)")
            cell?.imageView?.image = UIImage(named: imageExactPath)
        }
        return cell!
    }
    
    func createDirectory()->String{
        var error : NSError
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask,true)
        let documentDirectory : AnyObject = paths[0]
        let dataPath = documentDirectory.stringByAppendingPathComponent("Images")
        
        if(!NSFileManager.defaultManager().fileExistsAtPath(dataPath)){
            NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
//        print(dataPath)
        return dataPath
    }
    
    func getDocumentsDirectoryPath()-> String{
        var error : NSError
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask,true)
        let documentDirectory : AnyObject = paths[0]
        return documentDirectory as! String
    }
    
}



