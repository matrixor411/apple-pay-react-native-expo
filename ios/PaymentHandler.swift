import ExpoModulesCore
import PassKit
import Contacts

struct PaymentRequestItemData: Record {
    @Field
    var label: String
    
    @Field
    var amount: String
}

struct RecurringBillingData: Record {
    @Field
    var label: String

    @Field
    var amount: String

    @Field
    var intervalUnit: String

    @Field
    var intervalCount: Int? = nil

    @Field
    var startDate: String? = nil

    @Field
    var endDate: String? = nil
}

struct RecurringPaymentRequestData: Record {
    @Field
    var paymentDescription: String

    @Field
    var managementURL: String

    @Field
    var billingAgreement: String? = nil

    @Field
    var regularBilling: RecurringBillingData
}

struct PaymentRequestData: Record {
    @Field
    var merchantIdentifier: String
    
    @Field
    var countryCode: String
    
    @Field
    var currencyCode: String
    
    @Field
    var merchantCapabilities: [String] = ["supports3DS"]
    
    @Field
    var supportedNetworks: [String]

    @Field
    var paymentSummaryItems: [PaymentRequestItemData]

    @Field
    var requiredBillingContactFields: [String]? = nil

    @Field
    var recurringPayment: RecurringPaymentRequestData? = nil
}

typealias PaymentCompletionHandler = (PKPaymentAuthorizationResult) -> Void

class PaymentHandler: NSObject  {
    var paymentController: PKPaymentAuthorizationController?
    var promise: Promise!
    var handleCompletion: PaymentCompletionHandler?
    
    public func show(data: PaymentRequestData, promise: Promise) {
        self.promise = promise;
        
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = data.paymentSummaryItems.map {
            PKPaymentSummaryItem(label: $0.label, amount: NSDecimalNumber(string: $0.amount), type: .final)
        }
        
        paymentRequest.merchantIdentifier = data.merchantIdentifier
        paymentRequest.merchantCapabilities = getMerchantCapabilitiesFromData(jsMerchantCapabilities: data.merchantCapabilities)
        paymentRequest.countryCode = data.countryCode
        paymentRequest.currencyCode = data.currencyCode
        paymentRequest.supportedNetworks = getSupportedNetworksFromData(jsSupportedNetworks: data.supportedNetworks)
        if let fields = data.requiredBillingContactFields, !fields.isEmpty {
            paymentRequest.requiredBillingContactFields = getContactFieldsFromData(jsContactFields: fields)
        }

        if let recurring = data.recurringPayment {
            if #available(iOS 16.0, *) {
                guard let managementURL = URL(string: recurring.managementURL) else {
                    self.promise.reject("invalid_recurring_management_url", "Management URL is invalid")
                    self.promise = nil
                    return
                }

                let regularBilling = PKRecurringPaymentSummaryItem(
                    label: recurring.regularBilling.label,
                    amount: NSDecimalNumber(string: recurring.regularBilling.amount)
                )

                if let intervalUnit = getRecurringIntervalUnitFromData(jsIntervalUnit: recurring.regularBilling.intervalUnit) {
                    regularBilling.intervalUnit = intervalUnit
                }

                if let intervalCount = recurring.regularBilling.intervalCount, intervalCount > 0 {
                    regularBilling.intervalCount = intervalCount
                }

                if let startDate = parseISO8601Date(recurring.regularBilling.startDate) {
                    regularBilling.startDate = startDate
                }

                if let endDate = parseISO8601Date(recurring.regularBilling.endDate) {
                    regularBilling.endDate = endDate
                }

                let recurringRequest = PKRecurringPaymentRequest(
                    paymentDescription: recurring.paymentDescription,
                    regularBilling: regularBilling,
                    managementURL: managementURL
                )

                if let billingAgreement = recurring.billingAgreement, !billingAgreement.isEmpty {
                    recurringRequest.billingAgreement = billingAgreement
                }

                paymentRequest.recurringPaymentRequest = recurringRequest

                if data.paymentSummaryItems.isEmpty {
                    paymentRequest.paymentSummaryItems = [regularBilling]
                } else {
                    let additionalItems = data.paymentSummaryItems.dropFirst().map {
                        PKPaymentSummaryItem(label: $0.label, amount: NSDecimalNumber(string: $0.amount), type: .final)
                    }
                    paymentRequest.paymentSummaryItems = [regularBilling] + additionalItems
                }
            } else {
                self.promise.reject("recurring_requires_ios16", "Recurring payments require iOS 16 or later")
                self.promise = nil
                return
            }
        }
        
        //        paymentRequest.shippingType = .delivery
        //        paymentRequest.shippingMethods = shippingMethodCalculator()
        //        paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
        
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController!.delegate = self
        paymentController!.present(completion: { (presented: Bool) in
            if presented {
            } else {
                self.promise.reject("no_show", "Failed to present")
                self.promise = nil
            }
        })
    }
    
    public func complete(status: PKPaymentAuthorizationStatus) {
        handleCompletion?(PKPaymentAuthorizationResult(status: status, errors: [Error]()))
    }
    
    public func dismiss() {
        paymentController?.dismiss()
    }
    
    private func getMerchantCapabilitiesFromData(jsMerchantCapabilities: [String]) -> PKMerchantCapability {
        var PKMerchantCapabilityMap = [String: PKMerchantCapability]()
        
        PKMerchantCapabilityMap["supports3DS"] = PKMerchantCapability.threeDSecure
        PKMerchantCapabilityMap["supportsCredit"] = PKMerchantCapability.credit
        PKMerchantCapabilityMap["supportsDebit"] = PKMerchantCapability.debit
        PKMerchantCapabilityMap["supportsEMV"] = PKMerchantCapability.emv
        
        var merchantCapabilities: PKMerchantCapability = [];
        for jsMerchantCapability in jsMerchantCapabilities {
            if (PKMerchantCapabilityMap[jsMerchantCapability] != nil) {
                merchantCapabilities.insert(PKMerchantCapabilityMap[jsMerchantCapability]!)
            }
        }
        
        return merchantCapabilities;
    }
    
    private func getSupportedNetworksFromData(jsSupportedNetworks: [String]) -> [PKPaymentNetwork] {
        var PKPaymentNetworkMap = [String: PKPaymentNetwork]()
        
        PKPaymentNetworkMap["JCB"] = PKPaymentNetwork.JCB
        PKPaymentNetworkMap["amex"] = PKPaymentNetwork.amex
        PKPaymentNetworkMap["cartesBancaires"] = PKPaymentNetwork.cartesBancaires
        PKPaymentNetworkMap["chinaUnionPay"] = PKPaymentNetwork.chinaUnionPay
        PKPaymentNetworkMap["discover"] = PKPaymentNetwork.discover
        PKPaymentNetworkMap["eftpos"] = PKPaymentNetwork.eftpos
        PKPaymentNetworkMap["electron"] = PKPaymentNetwork.electron
        PKPaymentNetworkMap["elo"] = PKPaymentNetwork.elo
        PKPaymentNetworkMap["idCredit"] = PKPaymentNetwork.idCredit
        PKPaymentNetworkMap["interac"] = PKPaymentNetwork.interac
        PKPaymentNetworkMap["mada"] = PKPaymentNetwork.mada
        PKPaymentNetworkMap["maestro"] = PKPaymentNetwork.maestro
        PKPaymentNetworkMap["masterCard"] = PKPaymentNetwork.masterCard
        PKPaymentNetworkMap["privateLabel"] = PKPaymentNetwork.privateLabel
        PKPaymentNetworkMap["quicPay"] = PKPaymentNetwork.quicPay
        PKPaymentNetworkMap["suica"] = PKPaymentNetwork.suica
        PKPaymentNetworkMap["vPay"] = PKPaymentNetwork.vPay
        PKPaymentNetworkMap["visa"] = PKPaymentNetwork.visa
        
        if #available(iOS 14.0, *) {
            PKPaymentNetworkMap["barcode"] = PKPaymentNetwork.barcode
            PKPaymentNetworkMap["girocard"] = PKPaymentNetwork.girocard
        }
        if #available(iOS 14.5, *) {
            PKPaymentNetworkMap["mir"] = PKPaymentNetwork.mir
        }
        if #available(iOS 15.0, *) {
            PKPaymentNetworkMap["nanaco"] = PKPaymentNetwork.nanaco
            PKPaymentNetworkMap["waon"] = PKPaymentNetwork.waon
        }
        if #available(iOS 15.1, *) {
            PKPaymentNetworkMap["dankort"] = PKPaymentNetwork.dankort
        }
        if #available(iOS 16.0, *) {
            PKPaymentNetworkMap["bancomat"] = PKPaymentNetwork.bancomat
            PKPaymentNetworkMap["bancontact"] = PKPaymentNetwork.bancontact
        }
        if #available(iOS 16.4, *) {
            PKPaymentNetworkMap["postFinance"] = PKPaymentNetwork.postFinance
        }
        
        var supportedNetworks: [PKPaymentNetwork] = [];
        
        for supportedNetwork in jsSupportedNetworks {
            if (PKPaymentNetworkMap[supportedNetwork] != nil) {
                supportedNetworks.append(PKPaymentNetworkMap[supportedNetwork]!)
            }
        }
        
        return supportedNetworks;
    }

    @available(iOS 16.0, *)
    private func getRecurringIntervalUnitFromData(jsIntervalUnit: String) -> PKRecurringPaymentSummaryItemIntervalUnit? {
        switch jsIntervalUnit {
        case "day":
            return .day
        case "week":
            return .week
        case "month":
            return .month
        case "year":
            return .year
        default:
            return nil
        }
    }

    private func parseISO8601Date(_ value: String?) -> Date? {
        guard let value = value, !value.isEmpty else { return nil }
        let fullDateFormatter = ISO8601DateFormatter()
        fullDateFormatter.formatOptions = [.withFullDate]
        if let date = fullDateFormatter.date(from: value) {
            return date
        }

        let fullDateTimeFormatter = ISO8601DateFormatter()
        fullDateTimeFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fullDateTimeFormatter.date(from: value) {
            return date
        }

        let fullDateTimeNoFractionFormatter = ISO8601DateFormatter()
        fullDateTimeNoFractionFormatter.formatOptions = [.withInternetDateTime]
        return fullDateTimeNoFractionFormatter.date(from: value)
    }

    private func getContactFieldsFromData(jsContactFields: [String]) -> Set<PKContactField> {
        var fieldMap = [String: PKContactField]()
        fieldMap["name"] = PKContactField.name
        fieldMap["emailAddress"] = PKContactField.emailAddress
        fieldMap["phoneNumber"] = PKContactField.phoneNumber
        fieldMap["postalAddress"] = PKContactField.postalAddress

        var fields = Set<PKContactField>()
        for field in jsContactFields {
            if let contactField = fieldMap[field] {
                fields.insert(contactField)
            }
        }

        return fields
    }

    private func serializeBillingContact(_ contact: PKContact) -> [String: Any] {
        var contactDict: [String: Any] = [:]

        if let name = contact.name {
            var nameDict: [String: Any] = [:]
            if let namePrefix = name.namePrefix, !namePrefix.isEmpty {
                nameDict["namePrefix"] = namePrefix
            }
            if let givenName = name.givenName, !givenName.isEmpty {
                nameDict["givenName"] = givenName
            }
            if let middleName = name.middleName, !middleName.isEmpty {
                nameDict["middleName"] = middleName
            }
            if let familyName = name.familyName, !familyName.isEmpty {
                nameDict["familyName"] = familyName
            }
            if let nameSuffix = name.nameSuffix, !nameSuffix.isEmpty {
                nameDict["nameSuffix"] = nameSuffix
            }
            if let nickname = name.nickname, !nickname.isEmpty {
                nameDict["nickname"] = nickname
            }
            if !nameDict.isEmpty {
                contactDict["name"] = nameDict
            }
        }

        if let emailAddress = contact.emailAddress, !emailAddress.isEmpty {
            contactDict["emailAddress"] = emailAddress
        }

        if let phoneNumber = contact.phoneNumber?.stringValue, !phoneNumber.isEmpty {
            contactDict["phoneNumber"] = phoneNumber
        }

        if let postalAddress = contact.postalAddress {
            var postalDict: [String: Any] = [:]
            if !postalAddress.street.isEmpty {
                postalDict["street"] = postalAddress.street
            }
            if !postalAddress.city.isEmpty {
                postalDict["city"] = postalAddress.city
            }
            if !postalAddress.state.isEmpty {
                postalDict["state"] = postalAddress.state
            }
            if !postalAddress.postalCode.isEmpty {
                postalDict["postalCode"] = postalAddress.postalCode
            }
            if !postalAddress.country.isEmpty {
                postalDict["country"] = postalAddress.country
            }
            if !postalAddress.isoCountryCode.isEmpty {
                postalDict["isoCountryCode"] = postalAddress.isoCountryCode
            }
            if !postalAddress.subLocality.isEmpty {
                postalDict["subLocality"] = postalAddress.subLocality
            }
            if !postalAddress.subAdministrativeArea.isEmpty {
                postalDict["subAdministrativeArea"] = postalAddress.subAdministrativeArea
            }
            if !postalDict.isEmpty {
                contactDict["postalAddress"] = postalDict
            }
        }

        return contactDict
    }
}

extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        handleCompletion = completion
        do {
            // Parse the payment data
            let paymentData: [String : Any]? = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: []) as? [String: Any]
            
            // Build payment method object
            var paymentMethodDict: [String: Any] = [:]
            if let network = payment.token.paymentMethod.network?.rawValue {
                paymentMethodDict["network"] = network
            }
            if let displayName = payment.token.paymentMethod.displayName {
                paymentMethodDict["displayName"] = displayName
            }
            
            switch payment.token.paymentMethod.type {
            case .debit:
                paymentMethodDict["type"] = "debit"
            case .credit:
                paymentMethodDict["type"] = "credit"
            case .prepaid:
                paymentMethodDict["type"] = "prepaid"
            case .store:
                paymentMethodDict["type"] = "store"
            case .eMoney:
                paymentMethodDict["type"] = "eMoney"
            default:
                paymentMethodDict["type"] = "unknown"
            }
            
            // Build the full payment token structure
            let tokenData: [String: Any] = [
                "paymentData": paymentData as Any,
                "transactionIdentifier": payment.token.transactionIdentifier,
                "paymentMethod": paymentMethodDict
            ]
            
            let paymentObject: [String: Any] = [
                "payment": [
                    "token": tokenData
                ]
            ]

            if let billingContact = payment.billingContact {
                let billingContactDict = serializeBillingContact(billingContact)
                if !billingContactDict.isEmpty,
                   var paymentDict = paymentObject["payment"] as? [String: Any] {
                    paymentDict["billingContact"] = billingContactDict
                    let resolved: [String: Any] = ["payment": paymentDict]
                    promise?.resolve(resolved)
                    promise = nil
                    return
                }
            }

            promise?.resolve(paymentObject)
            promise = nil
        } catch {
            promise?.reject("payment_data_json", "failed to parse")
            promise = nil
        }
    }
    
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
        promise?.reject("dismiss", "closed")
        promise = nil
    }
}
