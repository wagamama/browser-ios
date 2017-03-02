//
//  SyncCodewordsView.swift
//  Client
//
//  Created by James Mudgett on 2/26/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

class SyncCodewordsView: UIView, UITextFieldDelegate {
    var fields: [UITextField] = []
    
    let DefaultBackgroundColor = UIColor(rgb: 0xcccccc)
    let SelectedBackgroundColor = UIColor.whiteColor()
    
    let DefaultBorderWidth: CGFloat = 0.0
    let SelectedBorderWidth: CGFloat = 0.5
    
    let DefaultBorderColor = UIColor(rgb: 0x696969).CGColor
    
    var previousFirstResponder: UITextField?
    
    var doneKeyCallback: (() -> Void)?
    
    convenience init(data: [String]) {
        self.init(frame: CGRectZero)
        
        for i in 0...15 {
            let field = UITextField()
            field.delegate = self
            field.tag = i
            field.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
            field.textAlignment = .Center
            field.textColor = UIColor.blackColor()
            field.keyboardAppearance = .Dark
            field.autocapitalizationType = .None
            field.autocorrectionType = .Yes
            field.returnKeyType = i < 15 ? .Continue : .Done
            field.text = data.count > i ? data[i] : ""
            field.backgroundColor = DefaultBackgroundColor
            field.layer.cornerRadius = 4
            field.layer.masksToBounds = true
            field.layer.borderWidth = DefaultBorderWidth
            field.layer.borderColor = DefaultBorderColor
            addSubview(field)
            fields.append(field)
        }
        
        // Read-only if data passed.
        if data.count != 0 {
            for field: UITextField in fields {
                field.enabled = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let spaceX: CGFloat = 18
        let spaceY: CGFloat = 7
        var x: CGFloat = 0
        var y: CGFloat = 0
        let w: CGFloat = (UIScreen.mainScreen().bounds.width - spaceX * 4) / 3
        let h: CGFloat = 26
        for i in 0..<fields.count {
            x = x + spaceX
            if x + w > UIScreen.mainScreen().bounds.width {
                x = spaceX
                y = y + h + spaceY
            }
            if i == fields.count - 1 {
                // Center last.
                x = (UIScreen.mainScreen().bounds.width - w) / 2
            }
            // debugPrint("w \(w) x \(x) y\(y)")
            
            let field = fields[i]
            var fieldFrame = field.frame
            fieldFrame.origin.x = x
            fieldFrame.origin.y = y
            fieldFrame.size.width = w
            fieldFrame.size.height = h
            field.frame = fieldFrame
            
            x = x + w
        }
    }
    
    override func sizeToFit() {
        let field = fields[fields.count - 1]
        var f = frame
        f.size.width = UIScreen.mainScreen().bounds.width
        f.size.height = CGRectGetMaxY(field.frame)
        frame = f
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if let wasResponder = previousFirstResponder {
            wasResponder.layer.borderWidth = DefaultBorderWidth
            wasResponder.backgroundColor = DefaultBackgroundColor
        }
        
        textField.layer.borderWidth = SelectedBorderWidth
        textField.backgroundColor = SelectedBackgroundColor
        
        // Keep.
        previousFirstResponder = textField
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.tag < fields.count - 1 {
            let field = fields[textField.tag + 1]
            field.layer.borderWidth = SelectedBorderWidth
            field.backgroundColor = SelectedBackgroundColor
            field.becomeFirstResponder()
        }
        else if let callback = doneKeyCallback {
            callback()
        }
        return true
    }
}
