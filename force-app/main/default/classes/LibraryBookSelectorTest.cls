@IsTest
private class LibraryBookSelectorTest {
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
            'Effective Apex',
            'Salesforce Architect',
            2,
            2,
            true
        );
    }

    @IsTest
    static void getBooksByIdsShouldReturnBooks() {
        List<Library_Book__c> books = [
            SELECT Id
            FROM Library_Book__c
        ];

        Set<Id> bookIds = new Map<Id, Library_Book__c>(books).keySet();

        Test.startTest();
        Map<Id, Library_Book__c> result =
            LibraryBookSelector.getBooksByIds(bookIds);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Expected to retrieve 2 books');
    }

    @IsTest
    static void getBooksByIdsShouldReturnEmptyMapWhenInputIsEmpty() {
        Test.startTest();
        Map<Id, Library_Book__c> result =
            LibraryBookSelector.getBooksByIds(new Set<Id>());
        Test.stopTest();

        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void getBookByIdForUpdateShouldReturnBook() {
        Library_Book__c book = [
            SELECT Id
            FROM Library_Book__c
            WHERE Title__c = 'Clean Code'
            LIMIT 1
        ];

        Test.startTest();
        Library_Book__c result =
            LibraryBookSelector.getBookByIdForUpdate(book.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Expected to retrieve a book');
        Assert.areEqual(book.Id, result.Id, 'Expected to retrieve the correct book');
        Assert.areEqual('Clean Code', result.Title__c, 'Expected the title to match');
    }

    @IsTest
    static void getBookByIdForUpdateShouldReturnNullWhenIdIsNull() {
        Test.startTest();
        Library_Book__c result =
            LibraryBookSelector.getBookByIdForUpdate(null);
        Test.stopTest();

        Assert.isNull(result, 'Expected to return null when Id is null');
    }

    @IsTest
    static void searchBooksShouldReturnResults() {
        Library_Book__c book = [
            SELECT Id
            FROM Library_Book__c
            WHERE Title__c = 'Clean Code'
            LIMIT 1
        ];

        Test.setFixedSearchResults(new List<Id>{ book.Id });

        Test.startTest();
        List<Library_Book__c> result =
            LibraryBookSelector.searchBooks('Clean');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected to retrieve 1 book');
        Assert.areEqual(book.Id, result[0].Id, 'Expected to retrieve the correct book');
    }

    @IsTest
    static void searchBooksShouldReturnEmptyListWhenSearchTermIsBlank() {
        Test.startTest();
        List<Library_Book__c> result =
            LibraryBookSelector.searchBooks('   ');
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Expected to retrieve 0 books');
    }

    @IsTest
    static void getBookByExactTitleShouldReturnBook() {
        Test.startTest();
        Library_Book__c result =
            LibraryBookSelector.getBookByExactTitle('Clean Code');
        Test.stopTest();

        Assert.isNotNull(result, 'Expected to retrieve a book');
        Assert.areEqual('Clean Code', result.Title__c, 'Expected the title to match');
        Assert.areEqual('Robert C. Martin', result.Author__c, 'Expected the author to match');
    }

    @IsTest
    static void getBookByExactTitleShouldReturnNullWhenTitleDoesNotExist() {
        Test.startTest();
        Library_Book__c result =
            LibraryBookSelector.getBookByExactTitle('Unknown Book');
        Test.stopTest();

        Assert.isNull(result, 'Expected to return null when title does not exist');
    }

    @IsTest
    static void getBookByExactTitleShouldReturnNullWhenTitleIsBlank() {
        Test.startTest();
        Library_Book__c result =
            LibraryBookSelector.getBookByExactTitle('');
        Test.stopTest();

        Assert.isNull(result, 'Expected to return null when title is blank');
    }

    @IsTest
    static void getBooksByIdsAsListShouldReturnBooks() {
        List<Library_Book__c> books = [
            SELECT Id
            FROM Library_Book__c
        ];

        Set<Id> bookIds = new Map<Id, Library_Book__c>(books).keySet();

        Test.startTest();
        List<Library_Book__c> result =
            LibraryBookSelector.getBooksByIdsAsList(bookIds);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Expected to retrieve 2 books');
    }

    @IsTest
    static void getBooksByIdsAsListShouldReturnEmptyListWhenInputIsEmpty() {
        Test.startTest();
        List<Library_Book__c> result =
            LibraryBookSelector.getBooksByIdsAsList(new Set<Id>());
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Expected to retrieve 0 books');
    }
}