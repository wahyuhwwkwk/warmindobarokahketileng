declare module 'midtrans-client' {
    interface SnapConfig {
        isProduction: boolean;
        serverKey: string;
        clientKey: string;
    }

    interface TransactionDetails {
        order_id: string;
        gross_amount: number;
    }

    interface CustomerDetails {
        first_name?: string;
        last_name?: string;
        email?: string;
        phone?: string;
    }

    interface ItemDetail {
        id: string;
        price: number;
        quantity: number;
        name: string;
    }

    interface SnapParameter {
        transaction_details: TransactionDetails;
        customer_details?: CustomerDetails;
        item_details?: ItemDetail[];
        enabled_payments?: string[];
    }

    interface SnapResponse {
        token: string;
        redirect_url: string;
    }

    interface TransactionStatus {
        transaction_status: string;
        fraud_status?: string;
        transaction_id?: string;
        order_id: string;
        gross_amount: string;
        payment_type: string;
        status_code: string;
    }

    class Snap {
        constructor(config: SnapConfig);
        createTransaction(parameter: SnapParameter): Promise<SnapResponse>;
        transaction: {
            status(orderId: string): Promise<TransactionStatus>;
            cancel(orderId: string): Promise<any>;
        };
    }

    export { Snap, SnapConfig, SnapParameter, SnapResponse, TransactionStatus };
}
