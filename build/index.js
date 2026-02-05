import { CompleteStatus, MerchantCapability, PaymentNetwork, } from "./ExpoApplePay.types";
import ExpoApplePayModule from "./ExpoApplePayModule";
export default {
    show: (data) => {
        const recurringPayment = data.recurringPayment
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
    complete: (status) => {
        ExpoApplePayModule.complete(status);
    },
};
export { MerchantCapability, PaymentNetwork, CompleteStatus, };
//# sourceMappingURL=index.js.map