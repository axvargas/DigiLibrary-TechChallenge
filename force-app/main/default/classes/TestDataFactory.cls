@IsTest
public with sharing class TestDataFactory {
    public static Library_Book__c createBook(
        String title,
        String author,
        Decimal availableCopies,
        Decimal totalCopies,
        Boolean doInsert
    ) {
        Library_Book__c book = new Library_Book__c(
            Title__c = title,
            Author__c = author,
            Available_Copies__c = availableCopies,
            Total_Copies__c = totalCopies
        );

        if (doInsert) {
            insert book;
        }

        return book;
    }

    public static Contact createContact(Boolean doInsert) {
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = 'test.borrower@example.com'
        );

        if (doInsert) {
            insert contact;
        }

        return contact;
    }

    public static Library_Book_Loan__c createLoan(
        Id bookId,
        Id borrowerId,
        String status,
        Boolean doInsert
    ) {
        Library_Book_Loan__c loan = new Library_Book_Loan__c(
            Book__c = bookId,
            Borrower__c = borrowerId,
            Loan_Start_Date__c = Date.today(),
            Status__c = status
        );

        if (doInsert) {
            insert loan;
        }

        return loan;
    }
}