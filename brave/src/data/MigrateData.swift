/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class MigrateData: NSObject {
    
    // TODO: WIP:
    // Detect old db type.
    // Migrate one object type at a time.
    // Save to coredata.
    // Remove old db.
    
    override init() {
        
    }
    
    private func hasOldDb() -> Bool {
        return true
    }
    
    private func migrateBookmarks(completed: (success: Bool) -> Void) {
        
    }
    
    private func migrateHistory(completed: (success: Bool) -> Void) {
        
    }
    
    private func migrateDomainData(completed: (success: Bool) -> Void) {
        
    }
    
    private func migrateFavicons(completed: (success: Bool) -> Void) {
        
    }
    
    private func migrateTabs(completed: (success: Bool) -> Void) {
        
    }
}
