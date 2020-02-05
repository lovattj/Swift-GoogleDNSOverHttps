import Foundation
import PlaygroundSupport

class GoogleDNSResponse: Decodable {
    var Status: Int
    var TC: Bool
    var RD: Bool
    var RA: Bool
    var AD: Bool
    var CD: Bool
    var Question: [GoogleDNSQuestion]
    var Answer: [GoogleDNSAnswer]
    var Comment: String?
}

class GoogleDNSQuestion: Decodable {
    var name: String
    var type: Int
}

class GoogleDNSAnswer: Decodable {
    var name: String
    var type: Int
    var TTL: Int
    var data: String
}

enum DNSRecordType: String {
    case A = "a"
    case AAAA = "aaaa"
}

class DNSOverHTTPSManager {
    class func getDNSRecords(recordType: DNSRecordType, forDomain: String, completionHandler: @escaping(_ errorMessage:Error?,_ response: GoogleDNSResponse?) -> Void) {
        let googleBaseURI: String = "https://dns.google.com/resolve?"
        let requestString: String = "\(googleBaseURI)name=\(forDomain)&type=\(recordType.rawValue)"
        let requestURI: URL = URL(string: requestString)!
        
        let session = URLSession.shared.dataTask(with: requestURI) { (d, r, e) in
            if let responseError = e {
                completionHandler(responseError, nil)
            } // responseError
            
            if let responseData = d {
                do {
                    let decoded = try JSONDecoder().decode(GoogleDNSResponse.self, from: responseData)
                    completionHandler(nil, decoded)
                } catch let decodeError {
                    completionHandler(decodeError, nil)
                }
            } // responseData
        } // closure
        session.resume()
    }
    
    class func getARecord(forDomain: String, completionHandler: @escaping(_ erorrMessage:Error?,_ response: String?) -> Void) {
        DNSOverHTTPSManager.getDNSRecords(recordType: DNSRecordType.A, forDomain: forDomain) { (e, r) in
            if let e = e {
                completionHandler(e, nil)
            }
            if let r = r {
                completionHandler(nil, r.Answer[0].data)
            }
        }
    }
}
// Required (I think) because the closures won't be called otherwise

PlaygroundPage.current.needsIndefiniteExecution = true
let domain = "bbc.co.uk"

// Easy way of getting an A Record (the first one in the list if there's more than one) there's a utility function.
DNSOverHTTPSManager.getARecord(forDomain: domain) { (responseError, response) in
    if let e = responseError {
        print(e)
        return
    }

    if let r = response {
        print(r)
    }
}

// If you want all the records or the other info coming from Google. For example this gets all the AAAA records for the domain.
DNSOverHTTPSManager.getDNSRecords(recordType: DNSRecordType.AAAA, forDomain: domain) { (responseError, response) in
    if let e = responseError {
        print(e)
        return
    }
    
    if let r = response {
        for record in r.Answer {
            print(record.data)
        }
    }
}
