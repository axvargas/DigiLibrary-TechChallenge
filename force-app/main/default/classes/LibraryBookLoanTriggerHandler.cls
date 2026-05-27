public with sharing class LibraryBookLoanTriggerHandler {

    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_RETURNED = 'Returned';
    private static final String STATUS_CANCELLED = 'Cancelled';

    public static void run(
        TriggerOperation operationType,
        List<Library_Book_Loan__c> newLoans,
        List<Library_Book_Loan__c> oldLoans,
        Map<Id, Library_Book_Loan__c> oldLoansById
    ) {
        switch on operationType {
            when BEFORE_INSERT {
                validateAvailableCopies(newLoans);
            }
            when BEFORE_UPDATE {
                setLoanEndDateWhenReturned(newLoans, oldLoansById);
            }
            when AFTER_INSERT {
                decreaseAvailableCopiesForActiveLoans(newLoans);
            }
            when AFTER_UPDATE {
                restoreCopiesForCompletedLoans(newLoans, oldLoansById);
            }
            when AFTER_DELETE {
                restoreCopiesForDeletedActiveLoans(oldLoans);
            }
        }
    }


    private static void validateAvailableCopies(List<Library_Book_Loan__c> loans) {
        Map<Id, Integer> requestedLoansByBookId = new Map<Id, Integer>();

        for (Library_Book_Loan__c loan : loans) {
            if (loan.Book__c == null || loan.Status__c != STATUS_ACTIVE) {
                continue;
            }

            requestedLoansByBookId.put(
                loan.Book__c,
                requestedLoansByBookId.containsKey(loan.Book__c)
                    ? requestedLoansByBookId.get(loan.Book__c) + 1
                    : 1
            );
        }

        if (requestedLoansByBookId.isEmpty()) {
            return;
        }

        Map<Id, Library_Book__c> booksById =
            LibraryBookSelector.getBooksByIds(requestedLoansByBookId.keySet());

        for (Library_Book_Loan__c loan : loans) {
            if (loan.Book__c == null || loan.Status__c != STATUS_ACTIVE) {
                continue;
            }

            Library_Book__c book = booksById.get(loan.Book__c);

            if (book == null) {
                loan.addError('The selected book does not exist.');
                continue;
            }

            Integer availableCopies = toInteger(book.Available_Copies__c);
            Integer requestedCopies = requestedLoansByBookId.get(loan.Book__c);

            if (availableCopies < requestedCopies) {
                loan.addError('No available copies for "' + book.Title__c + '".');
            }
        }
    }

    private static void decreaseAvailableCopiesForActiveLoans(
        List<Library_Book_Loan__c> loans
    ) {
        updateAvailableCopies(loans, -1, STATUS_ACTIVE);
    }

    private static void restoreCopiesForCompletedLoans(
        List<Library_Book_Loan__c> newLoans,
        Map<Id, Library_Book_Loan__c> oldLoansById
    ) {
        List<Library_Book_Loan__c> loansToRestore = new List<Library_Book_Loan__c>();

        for (Library_Book_Loan__c newLoan : newLoans) {
            Library_Book_Loan__c oldLoan = oldLoansById.get(newLoan.Id);

            Boolean wasActive = oldLoan.Status__c == STATUS_ACTIVE;
            Boolean isNowCompleted =
                newLoan.Status__c == STATUS_RETURNED ||
                newLoan.Status__c == STATUS_CANCELLED;

            if (wasActive && isNowCompleted) {
                loansToRestore.add(newLoan);
            }
        }

        updateAvailableCopies(loansToRestore, 1, null);
    }

    private static void restoreCopiesForDeletedActiveLoans(
        List<Library_Book_Loan__c> deletedLoans
    ) {
        List<Library_Book_Loan__c> activeDeletedLoans = new List<Library_Book_Loan__c>();

        for (Library_Book_Loan__c loan : deletedLoans) {
            if (loan.Status__c == STATUS_ACTIVE) {
                activeDeletedLoans.add(loan);
            }
        }

        updateAvailableCopies(activeDeletedLoans, 1, null);
    }

    private static void updateAvailableCopies(
        List<Library_Book_Loan__c> loans,
        Integer quantityChange,
        String requiredStatus
    ) {
        Map<Id, Integer> loanCountByBookId = new Map<Id, Integer>();

        for (Library_Book_Loan__c loan : loans) {
            if (loan.Book__c == null) {
                continue;
            }

            if (requiredStatus != null && loan.Status__c != requiredStatus) {
                continue;
            }

            loanCountByBookId.put(
                loan.Book__c,
                loanCountByBookId.containsKey(loan.Book__c)
                    ? loanCountByBookId.get(loan.Book__c) + 1
                    : 1
            );
        }

        if (loanCountByBookId.isEmpty()) {
            return;
        }

        Map<Id, Library_Book__c> booksById =
            LibraryBookSelector.getBooksByIds(loanCountByBookId.keySet());

        List<Library_Book__c> booksToUpdate = new List<Library_Book__c>();

        for (Id bookId : loanCountByBookId.keySet()) {
            Library_Book__c book = booksById.get(bookId);

            if (book == null) {
                continue;
            }

            Integer currentAvailableCopies = toInteger(book.Available_Copies__c);
            Integer loanQuantity = loanCountByBookId.get(bookId);

            book.Available_Copies__c =
                currentAvailableCopies + (loanQuantity * quantityChange);

            booksToUpdate.add(book);
        }

        if (!booksToUpdate.isEmpty()) {
            Database.update(booksToUpdate, AccessLevel.USER_MODE);
        }
    }

    private static void setLoanEndDateWhenReturned(
        List<Library_Book_Loan__c> newLoans,
        Map<Id, Library_Book_Loan__c> oldLoansById
    ) {
        for (Library_Book_Loan__c newLoan : newLoans) {
            Library_Book_Loan__c oldLoan = oldLoansById.get(newLoan.Id);

            if (
                oldLoan.Status__c == STATUS_ACTIVE &&
                newLoan.Status__c == STATUS_RETURNED &&
                newLoan.Loan_End_Date__c == null
            ) {
                newLoan.Loan_End_Date__c = Date.today();
            }
        }
    }

    private static Integer toInteger(Decimal value) {
        return value == null ? 0 : Integer.valueOf(value);
    }
}