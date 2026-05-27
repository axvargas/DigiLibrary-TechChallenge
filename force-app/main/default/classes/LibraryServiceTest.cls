@IsTest
private class LibraryServiceTest {

    private class OpenLibraryServiceMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();

            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);

            response.setBody(
                '{"docs":[' +
                    '{"title":"External Book","author_name":["External Author"]},' +
                    '{"title":"Clean Code","author_name":["Robert C. Martin"]}' +
                ']}'
            );

            return response;
        }
    }

    @TestSetup
    static void makeData() {
        TestDataFactory.createBook(
            'Clean Code',
            'Robert C. Martin',
            3,
            5,
            true
        );

        TestDataFactory.createBook(
            'Unavailable Book',
            'Unknown Author',
            0,
            1,
            true
        );

        TestDataFactory.createContact(true);
    }

    @IsTest
    static void searchBooksShouldReturnLocalAndExternalBooks() {
        Library_Book__c localBook = [
            SELECT Id
            FROM Library_Book__c
            WHERE Title__c = 'Clean Code'
            LIMIT 1
        ];

        Test.setFixedSearchResults(new List<Id>{ localBook.Id });

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryServiceMock()
        );

        Test.startTest();

        List<LibraryBookSearchResult> results =
            LibraryService.searchBooks('Clean');

        Test.stopTest();

        Assert.areEqual(
            2,
            results.size(),
            'The search should return one local and one external book.'
        );

        Integer localBookCount = 0;
        Integer externalBookCount = 0;

        for (LibraryBookSearchResult result : results) {

            if (result.existsInSalesforce) {
                localBookCount++;

                Assert.areEqual(
                    'Clean Code',
                    result.title,
                    'Local book title should match.'
                );

                Assert.areEqual(
                    3,
                    result.availableCopies,
                    'Local book available copies should match.'
                );
            } else {
                externalBookCount++;

                Assert.areEqual(
                    'External Book',
                    result.title,
                    'External book title should match.'
                );

                Assert.areEqual(
                    'External Author',
                    result.author,
                    'External book author should match.'
                );
            }
        }

        Assert.areEqual(
            1,
            localBookCount,
            'One local book should be returned.'
        );

        Assert.areEqual(
            1,
            externalBookCount,
            'One external book should be returned.'
        );
    }

    @IsTest
    static void searchBooksShouldReturnEmptyListWhenSearchTermIsBlank() {
        Test.startTest();

        List<LibraryBookSearchResult> results =
            LibraryService.searchBooks(' ');

        Test.stopTest();

        Assert.areEqual(
            0,
            results.size(),
            'Blank search term should return an empty list.'
        );
    }

    @IsTest
    static void getBooksByIdsShouldReturnBooks() {
        List<Library_Book__c> books = [
            SELECT Id
            FROM Library_Book__c
        ];

        List<Id> bookIds = new List<Id>();

        for (Library_Book__c book : books) {
            bookIds.add(book.Id);
        }

        Test.startTest();

        List<LibraryBookSearchResult> results =
            LibraryService.getBooksByIds(bookIds);

        Test.stopTest();

        Assert.areEqual(
            2,
            results.size(),
            'The method should return two books.'
        );
    }

    @IsTest
    static void importBookShouldCreateBookWhenBookDoesNotExist() {
        Test.startTest();

        LibraryBookSearchResult result =
            LibraryService.importBook(
                'New Imported Book',
                'New Author'
            );

        Test.stopTest();

        Library_Book__c insertedBook = [
            SELECT
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
            FROM Library_Book__c
            WHERE Id = :result.bookId
            LIMIT 1
        ];

        Assert.areEqual(
            'New Imported Book',
            insertedBook.Title__c,
            'Imported book title should match.'
        );

        Assert.areEqual(
            'New Author',
            insertedBook.Author__c,
            'Imported book author should match.'
        );

        Assert.areEqual(
            1,
            insertedBook.Available_Copies__c,
            'Imported book should start with one available copy.'
        );

        Assert.areEqual(
            true,
            result.existsInSalesforce,
            'Imported book should exist in Salesforce.'
        );
    }

    @IsTest
    static void importBookShouldReturnExistingBookWhenBookAlreadyExists() {
        Test.startTest();

        LibraryBookSearchResult result =
            LibraryService.importBook(
                'Clean Code',
                'Different Author'
            );

        Test.stopTest();

        Assert.areEqual(
            'Clean Code',
            result.title,
            'Existing book title should match.'
        );

        Assert.areEqual(
            'Robert C. Martin',
            result.author,
            'Existing book author should be preserved.'
        );

        Assert.areEqual(
            3,
            result.availableCopies,
            'Existing book available copies should match.'
        );
    }

    @IsTest
    static void importBookShouldThrowExceptionWhenTitleIsBlank() {
        try {
            LibraryService.importBook(
                '',
                'Author'
            );
        } catch (AuraHandledException excp) {
            Assert.isTrue(
                excp.getMessage().contains('Book title is required'),
                'The excp message should mention the missing title.'
            );
        }
    }

    @IsTest
    static void loanBookShouldCreateLoan() {
        Library_Book__c book = [
            SELECT Id, Available_Copies__c
            FROM Library_Book__c
            WHERE Title__c = 'Clean Code'
            LIMIT 1
        ];

        Contact borrower = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Test.startTest();

        LibraryService.loanBook(
            book.Id,
            borrower.Id
        );

        Test.stopTest();

        List<Library_Book_Loan__c> loans = [
            SELECT Id, Status__c
            FROM Library_Book_Loan__c
            WHERE Book__c = :book.Id
        ];

        Assert.areEqual(
            1,
            loans.size(),
            'One loan should be created.'
        );

        Assert.areEqual(
            'Active',
            loans[0].Status__c,
            'Loan status should be Active.'
        );

        Library_Book__c updatedBook = [
            SELECT Available_Copies__c
            FROM Library_Book__c
            WHERE Id = :book.Id
            LIMIT 1
        ];

        Assert.areEqual(
            2,
            updatedBook.Available_Copies__c,
            'Available copies should decrease after loan creation.'
        );
    }

    @IsTest
    static void loanBookShouldThrowExceptionWhenBookIdIsNull() {
        Contact borrower = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        try {
            Test.startTest();
            LibraryService.loanBook(
                null,
                borrower.Id
            );
            Test.stopTest();
            Assert.fail(
                'The method should throw an AuraHandledException when bookId is null.'
            );
        } catch (AuraHandledException excp) {
            Assert.areEqual(
                'Book Id is required.', 
                excp.getMessage(),
                'The excp message should match.'
            );
        }
    }

    @IsTest
    static void loanBookShouldThrowExceptionWhenBorrowerIdIsNull() {
        Library_Book__c book = [
            SELECT Id
            FROM Library_Book__c
            LIMIT 1
        ];

        try {
            Test.startTest();
            LibraryService.loanBook(
                book.Id,
                null
            );
            Test.stopTest();
            Assert.fail(
                'The method should throw an AuraHandledException when borrowerId is null.'
            );
        } catch (AuraHandledException excp) {
            Assert.areEqual(
                'Borrower Id is required.', 
                excp.getMessage(),
                'The excp message should match.'
            );
        }
    }

    @IsTest
    static void loanBookShouldThrowExceptionWhenNoCopiesAreAvailable() {
        Library_Book__c book = [
            SELECT Id
            FROM Library_Book__c
            WHERE Title__c = 'Unavailable Book'
            LIMIT 1
        ];

        Contact borrower = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        try {
            Test.startTest();

            LibraryService.loanBook(
                book.Id,
                borrower.Id
            );
            Test.stopTest();

            Assert.fail(
                'The method should throw a NoAvailableCopiesException.'
            );

        } catch (NoAvailableCopiesException excp) {

            Assert.isTrue(
                excp.getMessage().contains('No available copies'),
                'The excp message should mention unavailable copies.'
            );
        }
    }
}