package contoso.example;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Transaction {
    public Long user_id;
    public String user_name;
    public String user_surname;
    public String user_middle_name;
    public String user_phone_number;
    public String user_mail_address;
    public Boolean user_suspicious_activity;
    public BigDecimal  transaction_amount;
    public String transaction_currency;
    public String transaction_type;
    public String transaction_country;
    public String  transaction_timestamp;

    public Transaction() {
    }

    public Transaction(Long user_id, String user_name, String user_surname, String user_middle_name, String user_phone_number, String user_mail_address, Boolean user_suspicious_activity, String transaction_amount, String transaction_currency, String transaction_type, String transaction_country, String transaction_timestamp) {
        this.user_id = user_id;
        this.user_name = user_name;
        this.user_surname = user_surname;
        this.user_middle_name = user_middle_name;
        this.user_phone_number = user_phone_number;
        this.user_mail_address = user_mail_address;
        this.user_suspicious_activity = user_suspicious_activity;
        this.transaction_amount = new BigDecimal(transaction_amount);
        this.transaction_currency = transaction_currency;
        this.transaction_type = transaction_type;
        this.transaction_country = transaction_country;
        this.transaction_timestamp = transaction_timestamp;
    }

    // getters and setters

    // getters
    public Long getUserId() {
        return user_id;
    }

    public String getUserName() {
        return user_name;
    }

    public String getUserSurname() {
        return user_surname;
    }

    public String getUserMiddleName() {
        return user_middle_name;
    }

    public String getUserPhoneNumber() {
        return user_phone_number;
    }

    public String getUserMailAddress() {
        return user_mail_address;
    }

    public Boolean getUserSuspiciousActivity() {
        return user_suspicious_activity;
    }

    public BigDecimal getTransactionAmount() {
        return transaction_amount;
    }

    public String getTransactionCurrency() {
        return transaction_currency;
    }

    public String getTransactionType() {
        return transaction_type;
    }

    public String getTransactionCountry() {
        return transaction_country;
    }

    public String getTransactionTimestamp() {
        return transaction_timestamp;
    }

    // setters
    public void setUserId(Long user_id) {
        this.user_id = user_id;
    }

    public void setUserName(String user_name) {
        this.user_name = user_name;
    }

    public void setUserSurname(String user_surname) {
        this.user_surname = user_surname;
    }

    public void setUserMiddleName(String user_middle_name) {
        this.user_middle_name = user_middle_name;
    }

    public void setUserPhoneNumber(String user_phone_number) {
        this.user_phone_number = user_phone_number;
    }

    public void setUserMailAddress(String user_mail_address) {
        this.user_mail_address = user_mail_address;
    }

    public void setUserSuspiciousActivity(Boolean user_suspicious_activity) {
        this.user_suspicious_activity = user_suspicious_activity;
    }

    public void setTransactionAmount(String transaction_amount) {
        this.transaction_amount = new BigDecimal(transaction_amount);
    }

    public void setTransactionCurrency(String transaction_currency) {
        this.transaction_currency = transaction_currency;
    }

    public void setTransactionType(String transaction_type) {
        this.transaction_type = transaction_type;
    }

    public void setTransactionCountry(String transaction_country) {
        this.transaction_country = transaction_country;
    }

    public void setTransactionTimestamp(String transaction_timestamp) {
        this.transaction_timestamp = transaction_timestamp;
    }
}

