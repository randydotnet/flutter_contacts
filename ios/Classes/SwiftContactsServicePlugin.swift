import Flutter
import UIKit
import Contacts

@available(iOS 9.0, *)
public class SwiftContactsServicePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "github.com/clovisnicolas/flutter_contacts", binaryMessenger: registrar.messenger())
        let instance = SwiftContactsServicePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getContacts":
            result(getContacts(query: (call.arguments as! String?)))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getContacts(query : String?) -> [[String:Any]]{
        var contacts : [CNContact] = []
        //Create the store, keys & fetch request
        let store = CNContactStore()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                    CNContactEmailAddressesKey,
                    CNContactPhoneNumbersKey,
                    CNContactFamilyNameKey,
                    CNContactGivenNameKey,
                    CNContactMiddleNameKey,
                    CNContactPostalAddressesKey,
                    CNContactOrganizationNameKey,
                    CNContactJobTitleKey] as [Any]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        // Set the predicate if there is a query
        if let query = query{
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: query)
        }
        // Fetch contacts
        do{
            try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
                contacts.append(contact)
            })
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return []
        }
        // Transform the CNContacts into dictionaries
        var result = [[String:Any]]()
        for contact : CNContact in contacts{
            result.append(contactToDictionary(contact: contact))
        }
        return result
    }
    
    func contactToDictionary(contact: CNContact) -> [String:Any]{
        
        var result = [String:Any]()
        
        //Simple fields
        result["displayName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
        result["givenName"] = contact.givenName
        result["familyName"] = contact.familyName
        result["middleName"] = contact.middleName
        result["company"] = contact.organizationName
        result["jobTitle"] = contact.jobTitle
        
        //Phone numbers
        var phoneNumbers = [[String:String]]()
        for phone in contact.phoneNumbers{
            var phoneDictionary = [String:String]()
            phoneDictionary["value"] = phone.value.stringValue
            phoneDictionary["label"] = "other"
            if let label = phone.label{
                phoneDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
            }
            phoneNumbers.append(phoneDictionary)
        }
        result["phones"] = phoneNumbers
        
        //Emails
        var emailAddresses = [[String:String]]()
        for email in contact.emailAddresses{
            var emailDictionary = [String:String]()
            emailDictionary["value"] = String(email.value)
            emailDictionary["label"] = "other"
            if let label = email.label{
                emailDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
            }
            emailAddresses.append(emailDictionary)
        }
        result["emails"] = emailAddresses
        
        //Postal addresses
        var postalAddresses = [[String:String]]()
        for address in contact.postalAddresses{
            var addressDictionary = [String:String]()
            addressDictionary["label"] = ""
            if let label = address.label{
                addressDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
            }
            addressDictionary["street"] = address.value.street
            addressDictionary["city"] = address.value.city
            addressDictionary["postcode"] = address.value.postalCode
            addressDictionary["region"] = address.value.state
            addressDictionary["country"] = address.value.country
            
            postalAddresses.append(addressDictionary)
        }
        result["postalAddresses"] = postalAddresses
        
        return result
    }
    
}