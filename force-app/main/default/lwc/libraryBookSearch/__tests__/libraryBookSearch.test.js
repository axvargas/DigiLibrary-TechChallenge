import { createElement } from '@lwc/engine-dom';
import LibraryBookSearch from 'c/libraryBookSearch';

import searchBooks from '@salesforce/apex/LibraryService.searchBooks';
import loanBook from '@salesforce/apex/LibraryService.loanBook';
import importBook from '@salesforce/apex/LibraryService.importBook';

jest.mock(
    '@salesforce/apex/LibraryService.searchBooks',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LibraryService.loanBook',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LibraryService.importBook',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe('c-library-book-search', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        jest.clearAllMocks();
    });

    function createComponent() {
        const element = createElement('c-library-book-search', {
            is: LibraryBookSearch
        });

        document.body.appendChild(element);
        return element;
    }

    it('searches books and renders results', async () => {
        searchBooks.mockResolvedValue([
            {
                bookId: 'a001',
                title: 'Clean Code',
                author: 'Robert C. Martin',
                availableCopies: 3,
                totalCopies: 5,
                source: 'Salesforce',
                existsInSalesforce: true
            }
        ]);

        const element = createComponent();

        const input = element.shadowRoot.querySelector('lightning-input');
        input.value = 'Clean';
        input.dispatchEvent(new CustomEvent('change'));

        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        await flushPromises();
        await flushPromises();

        expect(searchBooks).toHaveBeenCalledWith({
            searchTerm: 'Clean'
        });

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].title).toBe('Clean Code');
        expect(datatable.data[0].actionLabel).toBe('Request Loan');
    });

    it('imports an external book', async () => {
        searchBooks.mockResolvedValue([
            {
                bookId: null,
                title: 'External Book',
                author: 'External Author',
                availableCopies: null,
                totalCopies: null,
                source: 'Open Library',
                existsInSalesforce: false
            }
        ]);

        importBook.mockResolvedValue({
            bookId: 'a002',
            title: 'External Book',
            author: 'External Author',
            availableCopies: 1,
            totalCopies: 1,
            source: 'Salesforce',
            existsInSalesforce: true
        });

        const element = createComponent();

        const input = element.shadowRoot.querySelector('lightning-input');
        input.value = 'External';
        input.dispatchEvent(new CustomEvent('change'));

        element.shadowRoot.querySelector('lightning-button').click();

        await flushPromises();
        await flushPromises();

        let datatable = element.shadowRoot.querySelector('lightning-datatable');

        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    row: datatable.data[0],
                    action: { name: 'book_action' }
                }
            })
        );

        await flushPromises();
        await flushPromises();

        expect(importBook).toHaveBeenCalledWith({
            title: 'External Book',
            author: 'External Author'
        });

        datatable = element.shadowRoot.querySelector('lightning-datatable');

        expect(datatable.data[0].existsInSalesforce).toBe(true);
        expect(datatable.data[0].availableCopies).toBe(1);
        expect(datatable.data[0].actionLabel).toBe('Request Loan');
    });

    it('creates a loan for an existing Salesforce book', async () => {
        searchBooks.mockResolvedValue([
            {
                bookId: 'a001',
                title: 'Clean Code',
                author: 'Robert C. Martin',
                availableCopies: 3,
                totalCopies: 5,
                source: 'Salesforce',
                existsInSalesforce: true
            }
        ]);

        loanBook.mockResolvedValue();

        const element = createComponent();

        const borrowerPicker = element.shadowRoot.querySelector(
            'lightning-record-picker'
        );

        borrowerPicker.dispatchEvent(
            new CustomEvent('change', {
                detail: {
                    recordId: '003000000000001AAA'
                }
            })
        );

        const input = element.shadowRoot.querySelector('lightning-input');
        input.value = 'Clean';
        input.dispatchEvent(new CustomEvent('change'));

        element.shadowRoot.querySelector('lightning-button').click();

        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    row: datatable.data[0],
                    action: { name: 'book_action' }
                }
            })
        );

        await flushPromises();
        await flushPromises();

        expect(loanBook).toHaveBeenCalledWith({
            bookId: 'a001',
            borrowerId: '003000000000001AAA'
        });
    });

    it('does not search when search term is blank', async () => {
        const element = createComponent();

        element.shadowRoot.querySelector('lightning-button').click();

        await flushPromises();
        await flushPromises();

        expect(searchBooks).not.toHaveBeenCalled();
    });
});