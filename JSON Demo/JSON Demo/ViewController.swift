//
//  ViewController.swift
//  JSON Demo
//
//  Created by Yogesh Bharate on 14/08/15.
//  Copyright (c) 2015 Yogesh Bharate. All rights reserved.
//

import UIKit

public class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate {
    
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
    var searchBar : UISearchBar!
    var searchActive : Bool = false
    var filteredTableData = [String]()
    
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
                        self.items.addObject(nameKey)
                        self.names.addObject(nameKey)
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
        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 70, width: self.view.frame.width, height: 40))
        self.searchBar.placeholder = "Search the Item from List"
        var leftNavBarButton = UIBarButtonItem(customView:self.searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        self.searchBar?.delegate = self
//        searchBar.showsCancelButton = true
        self.tableView?.addSubview(refreshControl)
        
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
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            println(self.filteredTableData.count)
            return self.filteredTableData.count
        } else {
            return self.items.count;
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL") as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "CELL")
        }
        
        if isNetworkAvailable && !searchActive{
            
            let user:JSON =  JSON(self.items[indexPath.row])
            
            let picURL = user["avatar_image"]["url"].string
            
            var path = createDirectory()
            var imageName = path.stringByAppendingPathComponent(user["username"].string!)
            
            cell!.textLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
            cell!.detailTextLabel?.font = UIFont(name: "HelveticaNeue", size: 12)
            cell!.detailTextLabel?.text = "Details are not available !!!"
            
            var userName = user["username"].string
            imageName = imageName.stringByAppendingString(".jpg")
            
            cell!.textLabel?.text = user["username"].string
            if let subTitle = user["description"]["text"].string {
                cell!.detailTextLabel?.text = subTitle
            }
            else {
                for name in nameAndIcon {
                    cell!.textLabel?.text = name.key as? String
                }
            }
        
            let url = NSURL(string: picURL!)
            var image : UIImage = UIImage(named: "icons/loading.jpg")!
            var imageDirectory : String = "Images"
            var imageN : String = (user["username"].string!).stringByAppendingString(".jpg")
            var imageAbsolutePath : String = imageDirectory.stringByAppendingPathComponent(imageN)
            cell?.imageView?.image = image
            
            // Download image async
            if (nameAndIcon[userName!] == nil){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                    if let imageDataFromURL = NSData(contentsOfURL: url!){
                        if imageDataFromURL.writeToFile(imageName, atomically: true){
                            self.nameAndIcon.setValue(imageAbsolutePath, forKey: userName!)
                            cell?.imageView?.image = UIImage(named: imageName)
                        }
                    }
                }
            } else { // Use the already downloaded image
                var imagePath: String = nameAndIcon.valueForKey(userName!) as! NSString as String
                var imageExactPath = getDocumentsDirectoryPath()
                imageExactPath = imageExactPath.stringByAppendingPathComponent(imagePath)
                var image : UIImage = UIImage(named: imageExactPath)!
                cell?.imageView?.image = image
            }
            
            cell?.accessoryView = nil
            appDelegate?.nameAndAvatar = nameAndIcon
        } else if searchActive {
            cell?.textLabel?.text = filteredTableData[indexPath.row]
        } else {
            // Code for offline data
            var nameAndIcon_ = nameAndIcon.allKeys as! [String]
            var arr: () = nameAndIcon_.sort({ $0 > $1 })
            let key = nameAndIcon_[indexPath.row]
            println(key)
            cell?.textLabel?.text = key// nameAndIcon.valueForKey(key as! String) as! String
            var imageExactPath = getDocumentsDirectoryPath()
            var str: String = nameAndIcon.valueForKey(key as String) as! String
            imageExactPath = imageExactPath.stringByAppendingPathComponent(str)
            cell?.imageView?.image = UIImage(named: imageExactPath)
        }
        return cell!
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
                let username : AnyObject = subJson["user"]["username"].object
               
                if self.refreshControl.refreshing {
                    self.refreshControl.endRefreshing()
                    self.items.removeAllObjects()
                }
                self.items.addObject(user)
                self.names.addObject(username)
                dispatch_async(dispatch_get_main_queue(),{
                    self.tableView?.reloadData()
                })
                println("\n\n\n names => \(self.names)")
            }
        }
    }
    
// MARK: Search bar functions
    public func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTableData.removeAll(keepCapacity: false)
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchBar.text)
        let array = (names as NSArray).filteredArrayUsingPredicate(searchPredicate)
        filteredTableData = array as! [String]
        println(filteredTableData)
        if searchText == "" || searchText.isEmpty{
            searchActive = false
        } else {
            searchActive = true
        }
        
        self.tableView!.reloadData()
    }
    
// MARK: Directory related functions.
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



