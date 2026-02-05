import {
	CompleteStatus,
	type RecurringPaymentRequest,
	type RecurringPaymentRequestInput,
	type BillingContact,
	type BillingContactField,
	type FullPaymentData,
	MerchantCapability,
	PaymentNetwork,
} from "./ExpoApplePay.types";
import ExpoApplePayModule from "./ExpoApplePayModule";

export default {
	show: (data: {
		merchantIdentifier: string;
		countryCode: string;
		currencyCode: string;
		merchantCapabilities: MerchantCapability[];
		supportedNetworks: PaymentNetwork[];
		requiredBillingContactFields?: BillingContactField[];
		recurringPayment?: RecurringPaymentRequest;
		paymentSummaryItems: {
			label: string;
			amount: number;
		}[];
	}): Promise<FullPaymentData> => {
		const recurringPayment: RecurringPaymentRequestInput | undefined =
			data.recurringPayment
				? {
						...data.recurringPayment,
						regularBilling: {
							...data.recurringPayment.regularBilling,
							amount: data.recurringPayment.regularBilling.amount.toString(),
						},
				  }
				: undefined;

		return ExpoApplePayModule.show({
			...data,
			recurringPayment,
			paymentSummaryItems: data.paymentSummaryItems.map((item) => ({
				label: item.label,
				amount: item.amount.toString(),
			})),
		});
	},

	dismiss: () => {
		ExpoApplePayModule.dismiss();
	},
	complete: (status: CompleteStatus) => {
		ExpoApplePayModule.complete(status);
	},
};

export {
	MerchantCapability,
	PaymentNetwork,
	CompleteStatus,
	type RecurringPaymentRequest,
	type BillingContact,
	type BillingContactField,
	type FullPaymentData,
};
