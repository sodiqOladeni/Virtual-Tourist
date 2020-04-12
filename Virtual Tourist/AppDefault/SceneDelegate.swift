//
//  SceneDelegate.swift
//  Virtual Tourist
//
//  Created by sodiqOladeni on 09/04/2020.
//  Copyright © 2020 NotZero Technologies. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var dataController = DataController(modelName: "Virtual_Tourist")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationMapViewController = navigationController.topViewController as! TravelLocationMapViewController
        travelLocationMapViewController.dataController = dataController
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        saveViewContext()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        saveViewContext()
    }
    
    func saveViewContext(){
        try? dataController.viewContext.save()
    }
}

