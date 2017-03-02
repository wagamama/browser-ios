/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let BarcodeSize: CGFloat = 200.0

class SyncBarcodeView: UIImageView {
    
    convenience init(data: String) {
        self.init(frame: CGRectZero)
        
        contentMode = .ScaleAspectFill
        
        if let img = createQRFromString(data) {
            let scaleX = BarcodeSize / img.extent.size.width
            let scaleY = BarcodeSize / img.extent.size.height
            
            let resultQrImage = img.imageByApplyingTransform(CGAffineTransformMakeScale(scaleX, scaleY))
            let barcode = UIImage(CIImage: resultQrImage, scale: UIScreen.mainScreen().scale, orientation: UIImageOrientation.Down)
            image = barcode
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createQRFromString(str: String) -> CIImage? {
        let stringData = str.dataUsingEncoding(NSUTF8StringEncoding)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(stringData, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        return filter?.outputImage
    }
}
