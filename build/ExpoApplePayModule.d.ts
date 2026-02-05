import { MerchantCapability, PaymentNetwork, CompleteStatus, type RecurringPaymentRequestInput } from "./ExpoApplePay.types";
declare const _default: {
    show: (_: {
        merchantIdentifier: string;
        countryCode: string;
        currencyCode: string;
        merchantCapabilities: MerchantCapability[];
        supportedNetworks: PaymentNetwork[];
        requiredBillingContactFields?: ("name" | "emailAddress" | "phoneNumber" | "postalAddress")[];
        recurringPayment?: RecurringPaymentRequestInput;
        paymentSummaryItems: {
            label: string;
            amount: string;
        }[];
    }) => Promise<never>;
    dismiss: () => void;
    complete: (_: CompleteStatus) => void;
};
export default _default;
//# sourceMappingURL=ExpoApplePayModule.d.ts.map