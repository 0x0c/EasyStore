//
//  EasyStore.swift
//  EasyStore
//
//  Created by Akira Matsuda on 2018/04/24.
//  Copyright © 2018 Akira Matsuda. All rights reserved.
//

import RealmSwift

class EasyStore<T: Object> {
	enum UpdateType : String {
		case add = "add"
		case update = "update"
		case delete = "delete"
	}
	
	func notificationName() -> String {
		return "EasyStoreUpdateNotification"
	}
	
	func updateTypeKey() -> String {
		return "updateType"
	}
	
	func transaction(_ handler: (_ realm: Realm) -> Void) throws {
		do {
			let realm = try Realm()
			try realm.write {
				handler(realm)
			}
		} catch {
			throw error
		}
	}
	
	func postNotification(withUpdateType type: UpdateType) {
		NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: self.notificationName()), object: nil, userInfo: [self.updateTypeKey() : type]))
	}
	
	func write(_ handler: @escaping (_ realm: Realm) -> Void) throws {
		do {
			try transaction { (realm) in
				handler(realm)
				postNotification(withUpdateType: .add)
			}
		} catch {
			throw error
		}
	}
	
	func create(_ obj: T) throws {
		try self.add(obj, update: false)
	}
	
	func add(_ obj: T, update: Bool = true) throws {
		do {
			try transaction { (realm) in
				realm.add(obj, update: update)
				postNotification(withUpdateType: .add)
			}
		} catch {
			throw error
		}
	}
	
	func update(_ handler: @escaping () -> Void, silentUpdate: Bool = false) throws {
		do {
			try transaction { (realm) in
				handler()
				if silentUpdate == false {
					postNotification(withUpdateType: .update)
				}
			}
		} catch {
			throw error
		}
	}
	
	func delete(_ obj: T) throws {
		let realm = try Realm()
		try realm.write {
			realm.delete(obj)
			postNotification(withUpdateType: .delete)
		}
	}
	
	func observe(_ handler: @escaping (UpdateType) -> Void) -> NSObjectProtocol {
		return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.notificationName()), object: nil, queue: nil) {
			if let userInfo = $0.userInfo {
				let type = userInfo[self.updateTypeKey()] as! UpdateType
				handler(type)
			}
		}
	}
	
	func removeObserver(_ observer: NSObjectProtocol) {
		NotificationCenter.default.removeObserver(observer)
	}
}
