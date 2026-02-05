import {
  MerchantCapability,
  PaymentNetwork,
  CompleteStatus,
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
    recurringPayment?: {
      paymentDescription: string;
      managementURL: string;
      billingAgreement?: string;
      regularBilling: {
        label: string;
        amount: string;
        intervalUnit: "day" | "week" | "month" | "year";
        intervalCount?: number;
        startDate?: string;
        endDate?: string;
      };
    };
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
