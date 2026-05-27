@IsTest
private class LibraryBookSearchResultTest {

    @IsTest
    static void constructorShouldAssignAllProperties() {
        Id bookId = Id.valueOf('a00000000000001AAA');

        Test.startTest();

        LibraryBookSearchResult result = new LibraryBookSearchResult(
            bookId,
            'Clean Code',
            'Robert C. Martin',
            3,
            5,
            'Salesforce',
            true
        );

        Test.stopTest();

        Assert.areEqual(
            bookId,
            result.bookId,
            'Book Id should be assigned.'
        );

        Assert.areEqual(
            'Clean Code',
            result.title,
            'Title should be assigned.'
        );

        Assert.areEqual(
            'Robert C. Martin',
            result.author,
            'Author should be assigned.'
        );

        Assert.areEqual(
            3,
            result.availableCopies,
            'Available copies should be assigned.'
        );

        Assert.areEqual(
            5,
            result.totalCopies,
            'Total copies should be assigned.'
        );

        Assert.areEqual(
            'Salesforce',
            result.source,
            'Source should be assigned.'
        );

        Assert.areEqual(
            true,
            result.existsInSalesforce,
            'Exists in Salesforce should be assigned.'
        );
    }

    @IsTest
    static void constructorShouldAllowNullValuesForExternalBooks() {
        Test.startTest();

        LibraryBookSearchResult result = new LibraryBookSearchResult(
            null,
            'External Book',
            'External Author',
            null,
            null,
            'Open Library',
            false
        );

        Test.stopTest();

        Assert.isNull(
            result.bookId,
            'Book Id should be null for external books.'
        );

        Assert.areEqual(
            'External Book',
            result.title,
            'Title should be assigned for external books.'
        );

        Assert.areEqual(
            'External Author',
            result.author,
            'Author should be assigned for external books.'
        );

        Assert.isNull(
            result.availableCopies,
            'Available copies should be null for external books.'
        );

        Assert.isNull(
            result.totalCopies,
            'Total copies should be null for external books.'
        );

        Assert.areEqual(
            'Open Library',
            result.source,
            'Source should be Open Library.'
        );

        Assert.areEqual(
            false,
            result.existsInSalesforce,
            'External books should not exist in Salesforce yet.'
        );
    }
}