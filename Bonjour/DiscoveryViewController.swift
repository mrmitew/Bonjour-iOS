import UIKit

class DiscoveryViewController: UIViewController, DiscoveryView {
    private var discoveryPresenter: DiscoveryPresenter!
    
    // UI
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var message: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        discoveryPresenter = DiscoveryPresenter(view: self)
        discoveryPresenter.startDiscovery()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!discoveryPresenter.isDiscovering()) {
            discoveryPresenter.startDiscovery()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if(discoveryPresenter.isDiscovering()) {
           discoveryPresenter.stopDiscovering()
        }
    }
    
    func showLoading(isLoading: Bool) {
        if(isLoading) {
            loading.isHidden = false
            loading.startAnimating()
        } else {
            loading.isHidden = true
            loading.stopAnimating()
        }
    }
    
    func showMessage(value: String) {
        print(value)
        self.message.text = value
        self.message.isHidden = false
    }
    
    func hideMessage() {
        self.message.isHidden = true
        self.message.text = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        discoveryPresenter.teardown()
    }
}
