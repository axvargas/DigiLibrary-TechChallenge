public with sharing class OpenLibraryService {

    private static final String SEARCH_ENDPOINT =
        'callout:Open_Library/search.json?q=';

    public static List<OpenLibraryBookResult> searchBooks(
        String searchTerm
    ) {
        if (String.isBlank(searchTerm)) {
            return new List<OpenLibraryBookResult>();
        }

        HttpRequest request = new HttpRequest();

        request.setEndpoint(
            SEARCH_ENDPOINT +
            EncodingUtil.urlEncode(searchTerm.trim(), 'UTF-8') +
            '&page=1'
        );
        request.setHeader('Accept', 'application/json');
        request.setHeader('User-Agent', 'DigiLibrary/1.0 (andresxavier99@gmail.com)');

        request.setMethod('GET');
        request.setTimeout(100000);

        Http http = new Http();

        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            throw new CalloutException(
                'Open Library API request failed.'
            );
        }

        OpenLibrarySearchResponse apiResponse =
            (OpenLibrarySearchResponse) JSON.deserialize(
                response.getBody(),
                OpenLibrarySearchResponse.class
            );

        List<OpenLibraryBookResult> books =
            new List<OpenLibraryBookResult>();

        if (apiResponse == null || apiResponse.docs == null) {
            return books;
        }

        for (OpenLibrarySearchResponse.OpenLibraryBook apiBook : apiResponse.docs) {

            if (String.isBlank(apiBook.title)) {
                continue;
            }

            books.add(new OpenLibraryBookResult(
                apiBook.title,
                getPrimaryAuthor(apiBook)
            ));
        }

        return books;
    }

    private static String getPrimaryAuthor(
        OpenLibrarySearchResponse.OpenLibraryBook book
    ) {
        if (
            book.author_name == null ||
            book.author_name.isEmpty()
        ) {
            return 'Unknown Author';
        }

        return book.author_name[0];
    }

    public class OpenLibraryBookResult {

        @AuraEnabled
        public String title;

        @AuraEnabled
        public String author;

        public OpenLibraryBookResult(
            String title,
            String author
        ) {
            this.title = title;
            this.author = author;
        }
    }
}