//
//  CommonUtil.swift
//  MyCameraSDK
//
//  Created by Prasanth Podalakur on 15/04/19.
//  Copyright © 2019 Prasanth Podalakur. All rights reserved.
//

import UIKit


open class CommonUtil: NSObject {
    
    open class func openCameraView(_ viewcontroller: UIViewController,delegate:MyCameraSDKDelegate) {
        let bundle = Bundle(identifier: "com.vsoft.MyCameraSDK")
        let myStoryboard = UIStoryboard(name: "MyCamSDK", bundle: bundle)
        let cam = myStoryboard.instantiateViewController(withIdentifier: "MyCameraVC") as! MyCameraVC
        cam.delegate = delegate
        let navVC = UINavigationController(rootViewController: cam)
        viewcontroller.present(navVC, animated: true, completion: nil)
        
    }
   
}
