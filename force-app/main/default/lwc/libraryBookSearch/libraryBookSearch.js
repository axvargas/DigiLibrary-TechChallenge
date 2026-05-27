import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import searchBooks from '@salesforce/apex/LibraryService.searchBooks';
import loanBook from '@salesforce/apex/LibraryService.loanBook';
import importBook from '@salesforce/apex/LibraryService.importBook';
import getBooksByIds from '@salesforce/apex/LibraryService.getBooksByIds';

const COLUMNS = [
    {
        label: 'Title',
        fieldName: 'title',
        type: 'text'
    },
    {
        label: 'Author',
        fieldName: 'author',
        type: 'text'
    },
    {
        label: 'Available Copies',
        fieldName: 'availableCopies',
        type: 'number'
    },
    {
        label: 'Source',
        fieldName: 'source',
        type: 'text'
    },
    {
        type: 'button',
        typeAttributes: {
            label: { fieldName: 'actionLabel' },
            name: 'book_action',
            variant: { fieldName: 'actionVariant' },
            disabled: { fieldName: 'disableActionButton' }
        }
    }
];

export default class LibraryBookSearch extends LightningElement {
    searchTerm = '';
    selectedBorrowerId;
    books = [];
    isLoading = false;
    hasSearched = false;

    columns = COLUMNS;

    get hasBooks() {
        return this.books.length > 0;
    }

    get showNoResults() {
        return this.hasSearched && !this.isLoading && !this.hasBooks;
    }

    handleBorrowerChange(event) {
        this.selectedBorrowerId = event.detail.recordId;
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
    }

    handleSearchKeyUp(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    async handleSearch() {
        if (!this.searchTerm || !this.searchTerm.trim()) {
            this.showToast(
                'Search term required',
                'Please enter a title or author to search.',
                'warning'
            );
            return;
        }

        this.isLoading = true;
        this.hasSearched = true;

        try {
            const results = await searchBooks({
                searchTerm: this.searchTerm.trim()
            });

            this.books = results.map((book) => this.prepareBookRow(book));
        } catch (error) {
            this.books = [];
            this.showToast(
                'Error searching books',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleRowAction(event) {
        const row = event.detail.row;

        if (row.existsInSalesforce) {
            this.handleLoanRequest(row);
            return;
        }

        this.handleImportBook(row);
    }

    async handleLoanRequest(book) {
        if (!this.selectedBorrowerId) {
            this.showToast(
                'Borrower required',
                'Please select a borrower before requesting a loan.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        try {
            await loanBook({
                bookId: book.bookId,
                borrowerId: this.selectedBorrowerId
            });

            this.showToast(
                'Loan registered',
                `"${book.title}" was successfully loaned.`,
                'success'
            );

            await this.refreshLocalBooksOnly();
        } catch (error) {
            this.showToast(
                'Unable to register loan',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    async handleImportBook(book) {
        console.log('Import book:', book);
        this.isLoading = true;

        try {
            const importedBook = await importBook({
                title: book.title,
                author: book.author
            });

            this.showToast(
                'Book imported',
                `"${book.title}" was successfully imported.`,
                'success'
            );

            this.books = this.books.map((row) => {
                if (row.rowKey !== book.rowKey) {
                    return row;
                }

                return this.prepareBookRow(importedBook);
            });
        } catch (error) {
            this.showToast(
                'Unable to import book',
                this.getErrorMessage(error),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    async refreshLocalBooksOnly() {
        const bookIds = this.books
            .filter((book) => book.existsInSalesforce && book.bookId)
            .map((book) => book.bookId);

        if (!bookIds.length) {
            return;
        }

        const refreshedBooks = await getBooksByIds({ bookIds });

        const refreshedBooksById = new Map(
            refreshedBooks.map((book) => [book.bookId, book])
        );

        this.books = this.books.map((book) => {
            const refreshedBook = refreshedBooksById.get(book.bookId);

            if (!refreshedBook) {
                return book;
            }

            return this.prepareBookRow({
                ...book,
                ...refreshedBook
            });
        });
    }

    prepareBookRow(book) {
        const existsInSalesforce = book.existsInSalesforce;
        const availableCopies = book.availableCopies || 0;

        return {
            ...book,
            rowKey: book.bookId || `${book.title}-${book.author}`,
            actionLabel: existsInSalesforce ? 'Request Loan' : 'Register/Import Book',
            actionVariant: existsInSalesforce ? 'brand' : 'neutral',
            disableActionButton: existsInSalesforce && availableCopies <= 0
        };
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        return 'An unexpected error occurred.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}