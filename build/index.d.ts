import { CompleteStatus, type BillingContact, type BillingContactField, type FullPaymentData, MerchantCapability, PaymentNetwork } from "./ExpoApplePay.types";
declare const _default: {
    show: (data: {
        merchantIdentifier: string;
        countryCode: string;
        currencyCode: string;
        merchantCapabilities: MerchantCapability[];
        supportedNetworks: PaymentNetwork[];
        requiredBillingContactFields?: BillingContactField[];
        paymentSummaryItems: {
            label: string;
            amount: number;
        }[];
    }) => Promise<FullPaymentData>;
    dismiss: () => void;
    complete: (status: CompleteStatus) => void;
};
export default _default;
export { MerchantCapability, PaymentNetwork, CompleteStatus, type BillingContact, type BillingContactField, type FullPaymentData, };
//# sourceMappingURL=index.d.ts.map