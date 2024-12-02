import AppKit

extension NSResponder {
    func printResponderChain() {
        var responder: NSResponder? = self
        while responder != nil {
            print(responder as Any)
            responder = responder?.nextResponder
        }
    }
}
