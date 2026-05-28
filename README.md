# DigiLibrary - Salesforce Development Challenge

DigiLibrary is a Salesforce application for managing a corporate digital library. It allows users to search books, request loans, return books, and import new books from Open Library.

## Objects

### Library_Book__c

Stores the library book inventory.

Fields:

- Title__c: Book title.
- Author__c: Book author.
- Available_Copies__c: Number of copies currently available.
- Total_Copies__c: Total number of copies owned by the library.

### Library_Book_Loan__c

Stores book loan records.

Fields:

- Borrower__c: Contact who borrowed the book.
- Book__c: Related Library_Book__c record.
- Loan_Start_Date__c: Date when the loan started.
- Loan_End_Date__c: Date when the book was returned.
- Status__c: Loan status. Values: Active, Returned, Cancelled.

## Apex Classes

### LibraryService

Main service class used by the LWC.

Responsibilities:

- Searches local books and Open Library books.
- Returns unified search results.
- Imports external books into Salesforce.
- Creates book loans.
- Validates loan requests.

### LibraryBookSelector

Centralized data access class for Library_Book__c.

Responsibilities:

- Query books by Id.
- Query books by title.
- Search books using SOSL.
- Retrieve books for update using `FOR UPDATE` (To lock the row and avoid race conditions).

### LibraryBookLoanTriggerHandler

Handles all trigger logic for Library_Book_Loan__c.

Responsibilities:

- Validates available copies before loan creation.
- Decreases available copies when an active loan is created.
- Increases available copies when a loan is returned or cancelled.
- Restores copies when an active loan is deleted.
- Sets Loan_End_Date__c when a loan is returned.

### OpenLibraryService

Handles the integration with Open Library API.

Responsibilities:

- Makes HTTP callouts to Open Library.
- Parses external book results.
- Extracts title and first author.
- Returns simplified external book data.

### OpenLibrarySearchResponse

DTO class used to deserialize Open Library API responses.

### LibraryBookSearchResult

Wrapper class used by the LWC to display both Salesforce and Open Library books in one table.

### NoAvailableCopiesException

Custom exception thrown when a user tries to borrow a book with no available copies.

### LibraryServiceException

Custom exception used for general service validation errors.

### TestDataFactory

Reusable test utility class for creating test data such as books, contacts, and loans.

## Trigger

### LibraryBookLoanTrigger

Trigger on Library_Book_Loan__c.

Events:

- before insert
- before update
- after insert
- after update
- after delete

The trigger delegates all logic to LibraryBookLoanTriggerHandler.

## Lightning Web Component

### libraryBookSearch

Main user interface for DigiLibrary.

Features:

- Select a borrower using Contact record picker.
- Search books by title or author.
- Display both local Salesforce books and Open Library results.
- Request a loan for existing Salesforce books.
- Import external books from Open Library.
- Refresh local inventory after loan creation.

## External Integration

### Open Library API

The app integrates with Open Library Search API:

```text
https://openlibrary.org/search.json?q={searchTerm}
````

A Named Credential is used:

```text
Open_Library
```

The service sends the following headers:

```text
Accept: application/json
User-Agent: DigiLibrary/1.0
```

## How the App Works

1. The user opens the DigiLibrary app.
2. The user selects a borrower from Contact records.
3. The user enters a book title or author in the search field.
4. The LWC calls LibraryService.searchBooks.
5. The service searches:

   * Local Library_Book__c records using SOSL.
   * External books using Open Library API.
6. Results are displayed in one unified table.

## Search Result Behavior

### If the book exists in Salesforce

The row displays:

* Title
* Author
* Available copies
* Source: Salesforce
* Button: Request Loan

When the user clicks Request Loan:

* A Library_Book_Loan__c record is created.
* Available_Copies__c is decreased by one.
* The UI refreshes the local Salesforce book data.

### If the book comes only from Open Library

The row displays:

* Title
* Author
* Source: Open Library
* Button: Register/Import Book

When the user clicks Register/Import Book:

* A new Library_Book__c record is created.
* Available_Copies__c is set to 1.
* Total_Copies__c is set to 1.
* The row changes to a Salesforce book.
* The user can then request a loan.

## Loan Lifecycle

### Active Loan

When a loan is created with Status__c = Active:

* Available_Copies__c decreases by one.

### Returned Loan

When Status__c changes from Active to Returned:

* Available_Copies__c increases by one.
* Loan_End_Date__c is set to today.

### Cancelled Loan

When Status__c changes from Active to Cancelled:

* Available_Copies__c increases by one.

### Deleted Loan

If an active loan is deleted:

* Available_Copies__c increases by one.

This delete behavior is included to satisfy the original requirement, but the recommended business flow is to return or cancel loans instead of deleting them.

## How to Use

1. Open the DigiLibrary app.
2. Go to the Home page.
3. Select a borrower.
4. Search for a book by title or author.
5. Review the results.
6. Click Request Loan if the book already exists in Salesforce.
7. Click Register/Import Book if the book comes from Open Library.
8. After importing, click Request Loan to borrow the book.
9. To return a book, open the loan record from a Contacts Record Page and change Status__c to Returned.

## Testing

The project includes Apex tests for:

* LibraryBookSelector
* LibraryBookLoanTriggerHandler
* LibraryBookSearchResult
* LibraryService
* OpenLibraryService
* OpenLibrarySearchResponse
* NoAvailableCopiesException

The project also includes Jest tests for:

* libraryBookSearch LWC

## Notes

* Open Library callouts are tested using HttpCalloutMock.
* The trigger is bulkified.
* Business logic is separated into service, selector, trigger handler, and integration layers.
* The application preserves loan history by using statuses instead of relying only on delete behavior.
