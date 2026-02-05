import {
  MerchantCapability,
  PaymentNetwork,
  CompleteStatus,
  type RecurringPaymentRequestInput,
} from "./ExpoApplePay.types";

export default {
  show: async (_: {
    merchantIdentifier: string;
    countryCode: string;
    currencyCode: string;
    merchantCapabilities: MerchantCapability[];
    supportedNetworks: PaymentNetwork[];
    requiredBillingContactFields?: (
      | "name"
      | "emailAddress"
      | "phoneNumber"
      | "postalAddress"
    )[];
    recurringPayment?: RecurringPaymentRequestInput;
    paymentSummaryItems: {
      label: string;
      amount: string;
    }[];
  }) => {
    console.log("noop");
    return Promise.reject("noop");
  },
  dismiss: () => {
    console.log("noop");
  },
  complete: (_: CompleteStatus) => {
    console.log("noop");
  },
};
