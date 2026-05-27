public with sharing class LibraryBookSelector {

    public static Map<Id, Library_Book__c> getBooksByIds(
        Set<Id> bookIds
    ) {
        if (bookIds == null || bookIds.isEmpty()) {
            return new Map<Id, Library_Book__c>();
        }

        return new Map<Id, Library_Book__c>([
            SELECT
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
            FROM Library_Book__c
            WHERE Id IN :bookIds
        ]);
    }

    public static Library_Book__c getBookByIdForUpdate(
        Id bookId
    ) {
        if (bookId == null) {
            return null;
        }

        List<Library_Book__c> books = [
            SELECT
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
            FROM Library_Book__c
            WHERE Id = :bookId
            LIMIT 1
            FOR UPDATE
        ];

        return books.isEmpty()
            ? null
            : books[0];
    }

    public static List<Library_Book__c> searchBooks(
        String searchTerm
    ) {
        if (String.isBlank(searchTerm)) {
            return new List<Library_Book__c>();
        }

        String formattedSearchTerm =
            '*' + String.escapeSingleQuotes(searchTerm.trim()) + '*';

        List<List<SObject>> searchResults = [
            FIND :formattedSearchTerm
            IN ALL FIELDS
            RETURNING Library_Book__c(
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
                ORDER BY Title__c
                LIMIT 50
            )
        ];

        return searchResults.isEmpty()
            ? new List<Library_Book__c>()
            : (List<Library_Book__c>) searchResults[0];
    }

    public static Library_Book__c getBookByExactTitle(String title) {
        if (String.isBlank(title)) {
            return null;
        }

        List<Library_Book__c> books = [
            SELECT
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
            FROM Library_Book__c
            WHERE Title__c = :title
            LIMIT 1
        ];

        return books.isEmpty() ? null : books[0];
    }

    public static List<Library_Book__c> getBooksByIdsAsList(
        Set<Id> bookIds
    ) {
        if (bookIds == null || bookIds.isEmpty()) {
            return new List<Library_Book__c>();
        }

        return [
            SELECT
                Id,
                Title__c,
                Author__c,
                Available_Copies__c,
                Total_Copies__c
            FROM Library_Book__c
            WHERE Id IN :bookIds
        ];
    }
}