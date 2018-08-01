import Foundation

class BonjourService {
    let name: String
    let ipaddress: String?
    let port: Int
    
    init(name: String, ipaddress: String?, port: Int) {
        self.name = name
        self.ipaddress = ipaddress
        self.port = port
    }
}

extension BonjourService {
    func getHost() -> String? {
        if(ipaddress == nil) {
            return nil
        }
        return String(format: "%@:%d", ipaddress!, port)
    }
}

private extension NetService {
    func toDomainModel() -> BonjourService {
        return BonjourService(name: self.name, ipaddress: self.getIpV4(), port: self.port)
    }
    
    func getIpV4() -> String? {
        if let ipData = self.addresses?.first {
            return (ipData as NSData).getIpV4()
        }
        return nil
    }
}

private extension NSData {
    func getIpV4(port: Int? = nil) -> String {
        var ip1 = UInt8(0)
        getBytes(&ip1, range: NSMakeRange(4, 1))
        
        var ip2 = UInt8(0)
        getBytes(&ip2, range: NSMakeRange(5, 1))
        
        var ip3 = UInt8(0)
        getBytes(&ip3, range: NSMakeRange(6, 1))
        
        var ip4 = UInt8(0)
        getBytes(&ip4, range: NSMakeRange(7, 1))
                
        if port != nil {
            return String(format: "%d.%d.%d.%d:%d", ip1, ip2, ip3, ip4, port!)
        } else {
            return String(format: "%d.%d.%d.%d", ip1, ip2, ip3, ip4)
        }
    }
}

class Bonjour: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    struct Services {
        static let printer: String = "_printer._tcp."
        static let http: String = "_http._tcp."
    }
    static let LocalDomain: String = "local."
    
    private let serviceBrowser: NetServiceBrowser = NetServiceBrowser()
    
    private var serviceResolvedClosure: ((BonjourService) -> Void)!
    var noServicesFoundClosure: (() -> Void)?
    var serviceDiscoveryFinishedClosure: (([NetService]) -> Void)?
    var serviceResolvingFinishedClosure: (([NetService]) -> Void)?
    var serviceToResolveTestClosure: ((NetService) -> Bool)?
    
    private var services = [NetService]()
    private var servicesBeingResolved = [NetService]()
    private var serviceTimeout: Timer = Timer()
    
    let timeout: TimeInterval = 10.0
    var isSearching: Bool = false
    
    func findService(type: String,
                     domain: String,
                     _ onResolved: @escaping (BonjourService) -> Void) -> Bool {
        if !isSearching {
            isSearching = true
            services.removeAll()
            
            serviceBrowser.delegate = self
            serviceResolvedClosure = onResolved
            
            serviceTimeout = Timer.scheduledTimer(
                timeInterval: self.timeout,
                target: self,
                selector: #selector(noServicesFound),
                userInfo: nil,
                repeats: false)
            
            serviceBrowser.searchForServices(ofType: type, inDomain: domain)
            return true
        }
        return false
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didFind service: NetService,
                           moreComing: Bool) {
        serviceTimeout.invalidate()
        service.delegate = self
        services.append(service)

        // Resolve only the ones we are interested in *IF* test closure was set
        let testClosure = serviceToResolveTestClosure
        if testClosure != nil {
            if (testClosure!(service)) {
                service.resolve(withTimeout: timeout)
            }
        } else {
            service.resolve(withTimeout: timeout)
        }

        print("Found: \(String(describing: service)). More to come? \(moreComing)")
        
        if !moreComing {
            serviceDiscoveryFinishedClosure?(services)
            serviceBrowser.stop()
            isSearching = false
        }
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("To resolve \(String(describing: sender))")
        servicesBeingResolved.append(sender)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Service resolved: \(sender)")
        serviceResolvedClosure(sender.toDomainModel())
        removeServiceFromResolveQueue(service: sender)
    }
    
    func removeServiceFromResolveQueue(service: NetService) {
        if let serviceIndex = servicesBeingResolved.index(of: service) {
            servicesBeingResolved.remove(at: serviceIndex)
        }
        
        if servicesBeingResolved.count == 0 {
            serviceResolvingFinishedClosure?(services)
        } else {
            print("[\(servicesBeingResolved.count)] services to resolve left")
        }
    }
    
    func isResolvingServices() -> Bool {
        return servicesBeingResolved.count > 0
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser,
                           didNotSearch errorDict: [String : NSNumber]) {
        print(errorDict)
    }
    
    func netService(_ sender: NetService,
                    didUpdateTXTRecord data: Data) {
        print(data)
    }
    
    func netService(_ sender: NetService,
                    didNotResolve errorDict: [String : NSNumber]) {
        removeServiceFromResolveQueue(service: sender)
        print(errorDict)
    }
    
    func stop() {
        serviceBrowser.stop()
        isSearching = false
    }
    
    @objc
    func noServicesFound() {
        noServicesFoundClosure?()
        stop()
    }
    
    func dispose() {
        stop()
        services.removeAll()
    }
}
