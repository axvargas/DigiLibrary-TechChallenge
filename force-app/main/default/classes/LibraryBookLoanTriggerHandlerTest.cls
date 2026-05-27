@IsTest
private class LibraryBookLoanTriggerHandlerTest {

    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_RETURNED = 'Returned';
    private static final String STATUS_CANCELLED = 'Cancelled';

    @TestSetup
    static void makeData() {
        TestDataFactory.createBook(
            'Clean Code',
            'Robert C. Martin',
            3,
            3,
            true
        );

        TestDataFactory.createBook(
            'No Copies Book',
            'Unknown Author',
            0,
            1,
            true
        );

        TestDataFactory.createContact(true);
    }

    @IsTest
    static void insertActiveLoanShouldDecreaseAvailableCopies() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        Test.startTest();
        insert new Library_Book_Loan__c(
            Book__c = book.Id,
            Borrower__c = borrower.Id,
            Loan_Start_Date__c = Date.today(),
            Status__c = STATUS_ACTIVE
        );
        Test.stopTest();

        Library_Book__c updatedBook = getBookByTitle('Clean Code');

        Assert.areEqual(
            2,
            updatedBook.Available_Copies__c,
            'Available copies should decrease by one.'
        );
    }

    @IsTest
    static void insertLoanShouldFailWhenNoCopiesAvailable() {
        Library_Book__c book = getBookByTitle('No Copies Book');
        Contact borrower = getBorrower();

        Library_Book_Loan__c loan = new Library_Book_Loan__c(
            Book__c = book.Id,
            Borrower__c = borrower.Id,
            Loan_Start_Date__c = Date.today(),
            Status__c = STATUS_ACTIVE
        );

        Test.startTest();

        Database.SaveResult result = Database.insert(loan, false);

        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Loan insert should fail.');
        Assert.isTrue(
            result.getErrors()[0].getMessage().contains('No available copies'),
            'Error should mention no available copies.'
        );
    }

    @IsTest
    static void bulkInsertLoansShouldDecreaseCopiesCorrectly() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        List<Library_Book_Loan__c> loans = new List<Library_Book_Loan__c>();

        for (Integer i = 0; i < 3; i++) {
            loans.add(new Library_Book_Loan__c(
                Book__c = book.Id,
                Borrower__c = borrower.Id,
                Loan_Start_Date__c = Date.today(),
                Status__c = STATUS_ACTIVE
            ));
        }

        Test.startTest();
        insert loans;
        Test.stopTest();

        Library_Book__c updatedBook = getBookByTitle('Clean Code');

        Assert.areEqual(
            0,
            updatedBook.Available_Copies__c,
            'Available copies should decrease by three.'
        );
    }

    @IsTest
    static void bulkInsertLoansShouldFailWhenRequestedCopiesExceedAvailableCopies() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        List<Library_Book_Loan__c> loans = new List<Library_Book_Loan__c>();

        for (Integer i = 0; i < 4; i++) {
            loans.add(new Library_Book_Loan__c(
                Book__c = book.Id,
                Borrower__c = borrower.Id,
                Loan_Start_Date__c = Date.today(),
                Status__c = STATUS_ACTIVE
            ));
        }

        Test.startTest();

        Database.SaveResult[] results = Database.insert(loans, false);

        Test.stopTest();

        for (Database.SaveResult result : results) {
            Assert.isFalse(
                result.isSuccess(),
                'Each loan should fail because requested copies exceed availability.'
            );
        }
    }

    @IsTest
    static void updateLoanToReturnedShouldRestoreCopyAndSetEndDate() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        Library_Book_Loan__c loan = TestDataFactory.createLoan(
            book.Id,
            borrower.Id,
            STATUS_ACTIVE,
            true
        );

        Library_Book__c bookAfterLoan = getBookByTitle('Clean Code');
        Assert.areEqual(2, bookAfterLoan.Available_Copies__c);

        Test.startTest();

        loan.Status__c = STATUS_RETURNED;
        update loan;

        Test.stopTest();

        Library_Book__c bookAfterReturn = getBookByTitle('Clean Code');

        Library_Book_Loan__c returnedLoan = [
            SELECT Id, Status__c, Loan_End_Date__c
            FROM Library_Book_Loan__c
            WHERE Id = :loan.Id
            LIMIT 1
        ];

        Assert.areEqual(
            3,
            bookAfterReturn.Available_Copies__c,
            'Available copies should be restored when loan is returned.'
        );

        Assert.areEqual(
            Date.today(),
            returnedLoan.Loan_End_Date__c,
            'Loan end date should be set when loan is returned.'
        );
    }

    @IsTest
    static void updateLoanToCancelledShouldRestoreCopy() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        Library_Book_Loan__c loan = TestDataFactory.createLoan(
            book.Id,
            borrower.Id,
            STATUS_ACTIVE,
            true
        );

        Test.startTest();

        loan.Status__c = STATUS_CANCELLED;
        update loan;

        Test.stopTest();

        Library_Book__c updatedBook = getBookByTitle('Clean Code');

        Assert.areEqual(
            3,
            updatedBook.Available_Copies__c,
            'Available copies should be restored when loan is cancelled.'
        );
    }

    @IsTest
    static void deleteActiveLoanShouldRestoreCopy() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        Library_Book_Loan__c loan = TestDataFactory.createLoan(
            book.Id,
            borrower.Id,
            STATUS_ACTIVE,
            true
        );

        Library_Book__c bookAfterLoan = getBookByTitle('Clean Code');
        Assert.areEqual(2, bookAfterLoan.Available_Copies__c);

        Test.startTest();

        delete loan;

        Test.stopTest();

        Library_Book__c bookAfterDelete = getBookByTitle('Clean Code');

        Assert.areEqual(
            3,
            bookAfterDelete.Available_Copies__c,
            'Deleting an active loan should restore the copy.'
        );
    }

    @IsTest
    static void deleteReturnedLoanShouldNotRestoreCopyAgain() {
        Library_Book__c book = getBookByTitle('Clean Code');
        Contact borrower = getBorrower();

        Library_Book_Loan__c loan = TestDataFactory.createLoan(
            book.Id,
            borrower.Id,
            STATUS_ACTIVE,
            true
        );

        loan.Status__c = STATUS_RETURNED;
        update loan;

        Library_Book__c bookAfterReturn = getBookByTitle('Clean Code');
        Assert.areEqual(3, bookAfterReturn.Available_Copies__c);

        Test.startTest();

        delete loan;

        Test.stopTest();

        Library_Book__c bookAfterDelete = getBookByTitle('Clean Code');

        Assert.areEqual(
            3,
            bookAfterDelete.Available_Copies__c,
            'Deleting a returned loan should not restore copies again.'
        );
    }

    private static Library_Book__c getBookByTitle(String title) {
        return [
            SELECT Id, Title__c, Available_Copies__c, Total_Copies__c
            FROM Library_Book__c
            WHERE Title__c = :title
            LIMIT 1
        ];
    }

    private static Contact getBorrower() {
        return [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];
    }
}