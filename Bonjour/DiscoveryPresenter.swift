import UIKit

protocol DiscoveryView {
    func showMessage(value: String)
    func hideMessage()
    func showLoading(isLoading: Bool)
}

class DiscoveryPresenter : NSObject {
    private let view: DiscoveryView
    private let bonjour: Bonjour = Bonjour()
    
    init(view: DiscoveryView) {
        self.view = view
        super.init()
        
        bonjour.noServicesFoundClosure = {
            view.showLoading(isLoading: false)
            view.showMessage(value: "No services were found on the network")
        }
        
        bonjour.serviceDiscoveryFinishedClosure = { (services) in
            print("Found services: \(services)")
            view.showMessage(value: "Found \(services.count) services")
//            view.showLoading(isLoading: false)
        }

//        bonjour.serviceToResolveTestClosure = { (service) in
//            return service.name == ???
//        }
        
        bonjour.serviceResolvingFinishedClosure = { (services) in
            view.showLoading(isLoading: false)
        }
    }
    
    func startDiscovery() {
        view.showLoading(isLoading: true)
        view.showMessage(value: "Discovering..")
        
        // Start discovery
        _ = bonjour.findService(type: Bonjour.Services.http,
                            domain: Bonjour.LocalDomain) { (service) in
                                print("Service \(service.name) - \(String(describing: service.getHost()))")
        }
    }

    func stopDiscovering() {
        bonjour.stop()
        view.showLoading(isLoading: false)
        view.showMessage(value: "Discovery has been cancelled")
    }

    func isDiscovering() -> Bool {
        return bonjour.isSearching
    }
    
    func teardown() {
        bonjour.dispose()
    }
}
