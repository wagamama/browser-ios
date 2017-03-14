/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Shared
import XCGLogger
import Eureka
import Storage

private let log = Logger.browserLogger

// MARK: - UX constants.

struct BookmarksPanelUX {
    private static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    private static let BookmarkFolderChevronSize: CGFloat = 20
    private static let BookmarkFolderChevronLineWidth: CGFloat = 4.0
    private static let BookmarkFolderTextColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
    private static let WelcomeScreenPadding: CGFloat = 15
    private static let WelcomeScreenItemTextColor = UIColor.grayColor()
    private static let WelcomeScreenItemWidth = 170
    private static let SeparatorRowHeight: CGFloat = 0.5
}

public extension UIBarButtonItem {
    
    public class func createImageButtonItem(image:UIImage, action:Selector) -> UIBarButtonItem {
        let button = UIButton(type: .Custom)
        button.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.setImage(image, forState: .Normal)
        
        return UIBarButtonItem(customView: button)
    }
    
    public class func createFixedSpaceItem(width:CGFloat) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        item.width = width
        return item
    }
}

class BkPopoverControllerDelegate : NSObject, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None;
    }
}

class BorderedButton: UIButton {
    let buttonBorderColor = UIColor.lightGrayColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderColor = buttonBorderColor.CGColor
        layer.borderWidth = 0.5
        
        contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override var highlighted: Bool {
        didSet {
            let fadedColor = buttonBorderColor.colorWithAlphaComponent(0.2).CGColor
            
            if highlighted {
                layer.borderColor = fadedColor
            } else {
                layer.borderColor = buttonBorderColor.CGColor
                
                let animation = CABasicAnimation(keyPath: "borderColor")
                animation.fromValue = fadedColor
                animation.toValue = buttonBorderColor.CGColor
                animation.duration = 0.4
                layer.addAnimation(animation, forKey: "")
            }
        }
    }
}

struct FolderPickerRow : Equatable {
    var folder: Bookmark?
}
func ==(lhs: FolderPickerRow, rhs: FolderPickerRow) -> Bool {
    return lhs.folder === rhs.folder
}

class BookmarkEditingViewController: FormViewController {
    var completionBlock:((controller:BookmarkEditingViewController) -> Void)?

    var folders = [Bookmark]()
    
    var bookmarksPanel:BookmarksPanel!
    var bookmark:Bookmark!
    var bookmarkIndexPath:NSIndexPath!

    let BOOKMARK_TITLE_ROW_TAG:String = "BOOKMARK_TITLE_ROW_TAG"
    let BOOKMARK_URL_ROW_TAG:String = "BOOKMARK_URL_ROW_TAG"
    let BOOKMARK_FOLDER_ROW_TAG:String = "BOOKMARK_FOLDER_ROW_TAG"

    var titleRow:TextRow!
    var urlRow:LabelRow!
    
    init(bookmarksPanel: BookmarksPanel, indexPath: NSIndexPath, bookmark: Bookmark) {
        super.init(nibName: nil, bundle: nil)

        self.bookmark = bookmark
        self.bookmarksPanel = bookmarksPanel
        self.bookmarkIndexPath = indexPath

        // get top-level folders
        folders = Bookmark.getFolders(nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //called when we're about to be popped, so use this for callback
        if let block = self.completionBlock {
            block(controller: self)
        }
    }
    
    var isEditingFolder:Bool {
        return bookmark.isFolder
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstSectionName = !isEditingFolder ?  Strings.Bookmark_Info : Strings.Bookmark_Folder

        let nameSection = Section(firstSectionName)
            
        nameSection <<< TextRow() { row in
            row.tag = BOOKMARK_TITLE_ROW_TAG
            row.title = Strings.Name
            row.value = bookmark.title
            self.titleRow = row
        }.onChange { row in
            self.bookmark.title = row.value
            DataController.saveContext()
        }

        form +++ nameSection
        
        if !isEditingFolder {
            nameSection <<< LabelRow() { row in
                row.tag = BOOKMARK_URL_ROW_TAG
                row.title = Strings.URL
                row.value = bookmark.url
                self.urlRow = row
            }.onChange { row in
                self.bookmark.url = row.value
                DataController.saveContext()
            }

            form +++ Section(Strings.Location)
            <<< PickerInlineRow<FolderPickerRow>() { (row : PickerInlineRow<FolderPickerRow>) -> Void in
                row.tag = BOOKMARK_FOLDER_ROW_TAG
                row.title = Strings.Folder
                row.displayValueFor = { (rowValue: FolderPickerRow?) in
                    return (rowValue?.folder?.title) ?? "Root Folder"
                }

                row.options = [FolderPickerRow()] + folders.map { (item) -> FolderPickerRow in
                    var fpr = FolderPickerRow()
                    fpr.folder = item
                    return fpr
                }

                var initial = FolderPickerRow()
                initial.folder = bookmark.parentFolder
                row.value = initial
            }.onChange { row in
                let r = row.value! as FolderPickerRow
                self.bookmark.parentFolder = r.folder
                DataController.saveContext()
            }
        }
    }
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var frc: NSFetchedResultsController? = nil

    private let BookmarkFolderCellIdentifier = "BookmarkFolderIdentifier"
    //private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorIdentifier"
    private let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"

    var editBookmarksToolbar:UIToolbar!
    var editBookmarksButton:UIBarButtonItem!
    var addRemoveFolderButton:UIBarButtonItem!
    var removeFolderButton:UIBarButtonItem!
    var addFolderButton:UIBarButtonItem!
    weak var addBookmarksFolderOkAction: UIAlertAction?
  
    var isEditingIndividualBookmark:Bool = false

    var currentFolder: Bookmark? = nil

    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = Strings.Bookmarks
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BookmarksPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)

        //self.tableView.registerClass(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
        self.tableView.registerClass(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        frc = Bookmark.frc(parentFolder: currentFolder)
        frc!.delegate = self

        tableView.allowsSelectionDuringEditing = true
        
        let navBar = self.navigationController?.navigationBar
        navBar?.barTintColor = BraveUX.BackgroundColorForSideToolbars
        navBar?.translucent = false
        navBar?.titleTextAttributes = [NSFontAttributeName : UIFont.systemFontOfSize(18, weight: UIFontWeightMedium), NSForegroundColorAttributeName : UIColor.blackColor()]
        navBar?.clipsToBounds = true
        
        let width = self.view.bounds.size.width
        let toolbarHeight = CGFloat(44)
        editBookmarksToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: width, height: toolbarHeight))
        createEditBookmarksToolbar()
        editBookmarksToolbar.barTintColor = BraveUX.BackgroundColorForSideToolbars
        editBookmarksToolbar.translucent = false
        
        self.view.addSubview(editBookmarksToolbar)
        
        editBookmarksToolbar.snp_makeConstraints { make in
            make.height.equalTo(toolbarHeight)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        tableView.snp_makeConstraints { make in
            make.bottom.equalTo(self.view).inset(UIEdgeInsetsMake(0, 0, toolbarHeight, 0))
        }

        reloadData()
    }

    override func reloadData() {
        DataController.saveContext()

        do {
            try self.frc?.performFetch()
        } catch let error as NSError {
            print(error.description)
        }

        self.tableView.reloadData()
    }
    
    func disableTableEditingMode() {
        switchTableEditingMode(true)
    }

    
    func switchTableEditingMode(forceOff:Bool = false) {
        let editMode:Bool = forceOff ? false : !tableView.editing
        tableView.setEditing(editMode, animated: forceOff ? false : true)
        
        //only when the 'edit' button has been pressed
        updateAddRemoveFolderButton(editMode)
        updateEditBookmarksButton(editMode)
        resetCellLongpressGesture(tableView.editing)
    }
    
    func updateEditBookmarksButton(tableIsEditing:Bool) {
        self.editBookmarksButton.title = tableIsEditing ? Strings.Done : Strings.Edit
        self.editBookmarksButton.style = tableIsEditing ? .Done : .Plain
    }
    
    func resetCellLongpressGesture(editing: Bool) {
        for cell in self.tableView.visibleCells {
            cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
            if editing == false {
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnCell))
                cell.addGestureRecognizer(lp)
            }
        }
    }
    
    /*
     * Subfolders can only be added to the root folder, and only subfolders can be deleted/removed, so we use
     * this button (on the left side of the bookmarks toolbar) for both functions depending on where we are.
     * Therefore when we enter edit mode on the root we show 'new folder'
     * the button disappears when not in edit mode in both cases. When a subfolder is not empty,
     * pressing the remove folder button will show an error message explaining why (suboptimal, but allows to expose this functionality)
     */
    func updateAddRemoveFolderButton(tableIsEditing:Bool) {
        
        if !tableIsEditing {
            addRemoveFolderButton.enabled = false
            addRemoveFolderButton.title = nil
            return
        }

        addRemoveFolderButton.enabled = true

        var targetButton:UIBarButtonItem!
        
        if currentFolder == nil { //on root, this button allows adding subfolders
            targetButton = addFolderButton
        } else { //on a subfolder, this button allows removing the current folder (if empty)
            targetButton = removeFolderButton
        }
        
        addRemoveFolderButton.title = targetButton.title
        addRemoveFolderButton.style = targetButton.style
        addRemoveFolderButton.target = targetButton.target
        addRemoveFolderButton.action = targetButton.action
    }
    
    func createEditBookmarksToolbar() {
        var items = [UIBarButtonItem]()
        
        items.append(UIBarButtonItem.createFixedSpaceItem(5))

        //these two buttons are created as placeholders for the data/actions in each case. see #updateAddRemoveFolderButton and
        //#switchTableEditingMode
        addFolderButton = UIBarButtonItem(title: Strings.NewFolder,
                                          style: .Plain, target: self, action: #selector(onAddBookmarksFolderButton))
        removeFolderButton = UIBarButtonItem(title: Strings.DeleteFolder,
                                             style: .Plain, target: self, action: #selector(onDeleteBookmarksFolderButton))
        
        //this is the button that actually lives in the toolbar
        addRemoveFolderButton = UIBarButtonItem()
        items.append(addRemoveFolderButton)

        updateAddRemoveFolderButton(false)
        
        items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil))

        editBookmarksButton = UIBarButtonItem(title: Strings.Edit,
                                              style: .Plain, target: self, action: #selector(onEditBookmarksButton))
        items.append(editBookmarksButton)
        items.append(UIBarButtonItem.createFixedSpaceItem(5))
        
        items.forEach { $0.tintColor = BraveUX.DefaultBlue }
        
        editBookmarksToolbar.items = items
        
        // This removes the small top border from the toolbar
        editBookmarksToolbar.clipsToBounds = true
    }
    
    func onDeleteBookmarksFolderButton() {
        guard let currentFolder = currentFolder else {
            NSLog("Delete folder button pressed but no folder object exists (probably at root), ignoring.")
            return
        }

        DataController.moc.deleteObject(currentFolder)
        DataController.saveContext()

        self.navigationController?.popViewControllerAnimated(true)
    }

    func onAddBookmarksFolderButton() {
        
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: UIAlertControllerStyle.Alert)
        
        let removeTextFieldObserver = {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alert.textFields!.first)
        }

        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (alertA: UIAlertAction!) in
            postAsyncToMain {
                self.addFolder(alertA, alertController:alert)
            }
            removeTextFieldObserver()
        }
        
        okAction.enabled = false
        
        addBookmarksFolderOkAction = okAction
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertA: UIAlertAction!) in
            removeTextFieldObserver()
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)

        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "<folder name>"
            textField.secureTextEntry = false
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.notificationReceived(_:)), name: UITextFieldTextDidChangeNotification, object: textField)
        })
        
        self.presentViewController(alert, animated: true) {}
    }

    func addFolder(alert: UIAlertAction!, alertController: UIAlertController) {
        guard let folderName = alertController.textFields?[0].text else { return }
        Bookmark.add(url:nil, title: folderName, customTitle: nil, parentFolder: currentFolder?.objectID, isFolder: true)
    }
    
    func onEditBookmarksButton() {
        switchTableEditingMode()
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {

        let dest = frc?.objectAtIndexPath(destinationIndexPath) as! Bookmark
        let src = frc?.objectAtIndexPath(sourceIndexPath) as! Bookmark

        if dest === src {
            return
        }

        // Warning, this could be a bottleneck, grabs ALL the bookmarks in the current folder
        // But realistically, with a batch size of 20, and most reads around 1ms, a bottleneck here is an edge case.
        // Optionally: grab the parent folder, and the on a bg thread iterate the bms and update their order. Seems like overkill.
        var bms = self.frc?.fetchedObjects as! [Bookmark]
        bms.removeAtIndex(bms.indexOf(src)!)
        if sourceIndexPath.row > destinationIndexPath.row {
            // insert before
            bms.insert(src, atIndex: bms.indexOf(dest)!)
        } else {
            let end = bms.indexOf(dest)! + 1
            bms.insert(src, atIndex: end)
        }

        for i in 0..<bms.count {
            bms[i].order = Int16(i)
        }

        // I am stumped, I can't find the notification that animation is complete for moving.
        // If I save while the animation is happening, the rows look screwed up (draw on top of each other).
        // Adding a delay to let animation complete avoids this problem
        postAsyncToMain(0.25) {
            DataController.saveContext()
        }
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            self.reloadData()
            break
        case UITextFieldTextDidChangeNotification:
            if let okAction = addBookmarksFolderOkAction, let textField = notification.object as? UITextField {
                okAction.enabled = (textField.text?.characters.count > 0)
            }
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

//    private func hasRowAtIndexPath(tableView: UITableView, indexPath: NSIndexPath) -> Bool {
//        return indexPath.section < tableView.numberOfSections && indexPath.row < tableView.numberOfRowsInSection(indexPath.section)
//    }


    func currentBookmarksPanel() -> BookmarksPanel {
        guard let controllers = navigationController?.viewControllers.filter({ $0 as? BookmarksPanel != nil }) else {
            return self
        }
        return controllers.last as? BookmarksPanel ?? self
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc?.fetchedObjects?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func getLongPressUrl(forIndexPath indexPath: NSIndexPath) -> NSURL? {
        guard let obj = frc?.objectAtIndexPath(indexPath) as? Bookmark else { return nil }
        return obj.url != nil ? NSURL(string: obj.url!) : nil
    }

    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {

        guard let item = frc?.objectAtIndexPath(indexPath) as? Bookmark else { return }
        cell.tag = item.objectID.hashValue

        func configCell(image image: UIImage? = nil, icon: FaviconMO? = nil, longPressForContextMenu: Bool = false) {
            if longPressForContextMenu && !tableView.editing {
                cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnCell))
                cell.addGestureRecognizer(lp)
            }

            func restrictImageSize() {
                if cell.imageView?.image == nil {
                    return
                }
                let itemSize = CGSizeMake(25, 25)
                UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.mainScreen().scale)
                let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
                cell.imageView?.image!.drawInRect(imageRect)
                guard let context = UIGraphicsGetImageFromCurrentImageContext() else { return }
                cell.imageView?.image! = context
                UIGraphicsEndImageContext()
            }

            if let faviconMO = item.domain?.favicon, let url = faviconMO.url {
                let favicon = Favicon(url: url, type: IconType(rawValue: Int(faviconMO.type)) ?? IconType.Guess)
                postAsyncToBackground {
                    let best = getBestFavicon([favicon])
                    postAsyncToMain {
                        let hasImage = cell.imageView?.image != nil
                        cell.imageView!.setIcon(best, withPlaceholder: FaviconFetcher.defaultFavicon) {
                            if !hasImage {
                                // TODO: why will it not draw the image the first time without this?
                                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            }
                        }
                    }
                }
            } else if let image = image {
                cell.imageView?.image = image
                restrictImageSize()
            }
        }

        if !item.isFolder {
            configCell(icon: item.domain?.favicon, longPressForContextMenu: true)

            cell.textLabel?.font = UIFont.systemFontOfSize(14)
            if let title = item.title where !title.isEmpty {
                cell.textLabel?.text = item.title
            } else {
                cell.textLabel?.text = item.url
            }

            cell.accessoryType = .None
        } else {
            configCell(image: UIImage(named: "bookmarks_folder_hollow"))
            cell.textLabel?.font = UIFont.boldSystemFontOfSize(14)
            cell.textLabel?.text = item.title
            cell.accessoryType = .DisclosureIndicator
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? BookmarkFolderTableViewCell {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        guard let bookmark = frc?.objectAtIndexPath(indexPath) as? Bookmark else { return }

        if !bookmark.isFolder {
            if tableView.editing {
                //show editing view for bookmark item
                self.showEditBookmarkController(tableView, indexPath: indexPath)
            }
            else {
                if let url = NSURL(string: bookmark.url ?? "") {
                    homePanelDelegate?.homePanel(self, didSelectURL: url)
                }
            }
        } else {
            if tableView.editing {
                //show editing view for bookmark item
                self.showEditBookmarkController(tableView, indexPath: indexPath)
            }
            else {
                print("Selected folder")
                let nextController = BookmarksPanel()
                nextController.currentFolder = bookmark
                nextController.homePanelDelegate = self.homePanelDelegate
                
                //on subfolders, the folderpicker is the same as the root
                let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self.navigationController, action: nil)
                self.navigationItem.leftBarButtonItem = backButton
                self.navigationController?.pushViewController(nextController, animated: true)
            }
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        guard let source = source else {
//            return .None
//        }
//
//        if source.current[indexPath.row] is BookmarkSeparator {
//            // Because the deletion block is too big.
//            return .None
//        }
//
//        if source.current.itemIsEditableAtIndex(indexPath.row) ?? false {
//            return .Delete
//        }

        return .Delete
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        guard let item = frc?.objectAtIndexPath(indexPath) as? Bookmark else { return nil }

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: Strings.Delete, handler: { (action, indexPath) in

            DataController.moc.deleteObject(item)
            DataController.saveContext()

            // updates the bookmark state
            getApp().browserViewController.updateURLBarDisplayURL(tab: nil)
        })

        let edit = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: Strings.Edit, handler: { (action, indexPath) in
            self.showEditBookmarkController(tableView, indexPath: indexPath)
        })

        return [delete, edit]
    }
    
    private func showEditBookmarkController(tableView: UITableView, indexPath:NSIndexPath) {
        guard let item = frc?.objectAtIndexPath(indexPath) as? Bookmark else { return }
        let nextController = BookmarkEditingViewController(bookmarksPanel: self, indexPath: indexPath, bookmark: item)

        nextController.completionBlock = { controller in
            self.isEditingIndividualBookmark = false
        }
        self.isEditingIndividualBookmark = true
        self.navigationController?.pushViewController(nextController, animated: true)
    }

}

private protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    private func didSelectHeader() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class BookmarkFolderTableViewCell: TwoLineTableViewCell {
    private let ImageMargin: CGFloat = 12

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.backgroundColor = UIColor.clearColor()
        textLabel?.tintColor = BookmarksPanelUX.BookmarkFolderTextColor

        imageView?.image = UIImage(named: "bookmarkFolder")

        self.editingAccessoryType = .DisclosureIndicator

        separatorInset = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class BookmarkFolderTableViewHeader : UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .Left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    lazy var bottomBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        userInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookmarkFolderTableViewHeader.viewWasTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp_makeConstraints { make in
            make.left.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(chevron.snp_right).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.right.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func viewWasTapped(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }
}

extension BookmarksPanel : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
       tableView.endUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Update:
            if let indexPath = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath) {
                configureCell(cell, atIndexPath: indexPath)
            }
       case .Insert:
            if let path = newIndexPath {
                print("try insert row \((anObject as! Bookmark).url)")
                let objectIdHash = tableView.cellForRowAtIndexPath(path)?.tag ?? 0
                if objectIdHash != anObject.objectID.hashValue {
                    tableView.insertRowsAtIndexPaths([path], withRowAnimation: .Automatic)
                }
            }

        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }


        case .Move:
            break
        }
    }
}
