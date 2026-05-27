public with sharing class LibraryService {

    private static final String SOURCE_SALESFORCE = 'Salesforce';
    private static final String SOURCE_OPEN_LIBRARY = 'Open Library';

    @AuraEnabled
    public static List<LibraryBookSearchResult> searchBooks(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<LibraryBookSearchResult>();
        }

        List<Library_Book__c> localBooks =
            LibraryBookSelector.searchBooks(searchTerm);

        List<OpenLibraryService.OpenLibraryBookResult> externalBooks =
            OpenLibraryService.searchBooks(searchTerm);

        Map<String, Library_Book__c> localBooksByNormalizedTitle =
            getLocalBooksByNormalizedTitle(localBooks);

        List<LibraryBookSearchResult> results =
            new List<LibraryBookSearchResult>();

        for (Library_Book__c localBook : localBooks) {
            results.add(buildLocalResult(localBook));
        }

        for (OpenLibraryService.OpenLibraryBookResult externalBook : externalBooks) {
            String normalizedTitle = normalizeTitle(externalBook.title);

            if (localBooksByNormalizedTitle.containsKey(normalizedTitle)) {
                continue;
            }

            results.add(
                new LibraryBookSearchResult(
                    null,
                    externalBook.title,
                    externalBook.author,
                    null,
                    null,
                    SOURCE_OPEN_LIBRARY,
                    false
                )
            );
        }

        return results;
    }

    @AuraEnabled
    public static List<LibraryBookSearchResult> getBooksByIds(
        List<Id> bookIds
    ) {
        List<Library_Book__c> books =
            LibraryBookSelector.getBooksByIdsAsList(
                new Set<Id>(bookIds)
            );

        List<LibraryBookSearchResult> results =
            new List<LibraryBookSearchResult>();

        for (Library_Book__c book : books) {
            results.add(buildLocalResult(book));
        }

        return results;
    }

    @AuraEnabled
    public static LibraryBookSearchResult importBook(String title, String author) {
        if (String.isBlank(title)) {
            AuraHandledException excp = new AuraHandledException(
                'Book title is required.'
            );
            excp.setMessage('Book title is required.');
            throw excp;
        }

        if (String.isBlank(author)) {
            author = 'Unknown Author';
        }

        Library_Book__c existingBook =
            LibraryBookSelector.getBookByExactTitle(title.trim());

        if (existingBook != null) {
            return buildLocalResult(existingBook);
        }

        Library_Book__c book = new Library_Book__c(
            Title__c = title.trim(),
            Author__c = author.trim(),
            Available_Copies__c = 1,
            Total_Copies__c = 1
        );

        Database.insert(book, AccessLevel.USER_MODE);

        return buildLocalResult(book);
    }

    @AuraEnabled
    public static void loanBook(Id bookId, Id borrowerId) {
        validateLoanRequest(bookId, borrowerId);

        Library_Book__c book = LibraryBookSelector.getBookByIdForUpdate(bookId);

        if (book == null) {
            AuraHandledException excp = new AuraHandledException('Book not found.');
            excp.setMessage('Book not found.');
            throw excp;
        }

        Integer availableCopies = toInteger(book.Available_Copies__c);

        if (availableCopies <= 0) {
            throw new NoAvailableCopiesException(
                'No available copies for "' + book.Title__c + '".'
            );
        }

        Library_Book_Loan__c loan = new Library_Book_Loan__c(
            Book__c = bookId,
            Borrower__c = borrowerId,
            Loan_Start_Date__c = Date.today(),
            Status__c = 'Active'
        );

        Database.insert(loan, AccessLevel.USER_MODE);
    }

    private static Map<String, Library_Book__c> getLocalBooksByNormalizedTitle(
        List<Library_Book__c> localBooks
    ) {
        Map<String, Library_Book__c> booksByTitle = new Map<String, Library_Book__c>();

        for (Library_Book__c book : localBooks) {
            booksByTitle.put(normalizeTitle(book.Title__c), book);
        }

        return booksByTitle;
    }

    private static LibraryBookSearchResult buildLocalResult(Library_Book__c book) {
        return new LibraryBookSearchResult(
            book.Id,
            book.Title__c,
            book.Author__c,
            book.Available_Copies__c,
            book.Total_Copies__c,
            SOURCE_SALESFORCE,
            true
        );
    }

    private static String normalizeTitle(String title) {
        return String.isBlank(title)
            ? ''
            : title.trim().toLowerCase();
    }

    private static void validateLoanRequest(Id bookId, Id borrowerId) {
        if (bookId == null) {
            AuraHandledException excp = new AuraHandledException('Book Id is required.');
            excp.setMessage('Book Id is required.');
            throw excp;
        }

        if (borrowerId == null) {
            AuraHandledException excp = new AuraHandledException('Borrower Id is required.');
            excp.setMessage('Borrower Id is required.');
            throw excp;
        }
    }

    private static Integer toInteger(Decimal value) {
        return value == null ? 0 : Integer.valueOf(value);
    }
}