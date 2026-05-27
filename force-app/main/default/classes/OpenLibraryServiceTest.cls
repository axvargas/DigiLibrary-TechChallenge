@IsTest
private class OpenLibraryServiceTest {

    private class OpenLibraryMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        OpenLibraryMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            Assert.areEqual(
                'GET',
                request.getMethod(),
                'The request method should be GET.'
            );

            Assert.areEqual(
                'application/json',
                request.getHeader('Accept'),
                'The Accept header should request JSON.'
            );

            Assert.areEqual(
                'DigiLibrary/1.0 (andresxavier99@gmail.com)',
                request.getHeader('User-Agent'),
                'The User-Agent header should be set.'
            );

            Assert.isTrue(
                request.getEndpoint().startsWith('callout:Open_Library/search.json?q='),
                'The request should use the Open_Library named credential.'
            );

            Assert.isTrue(
                request.getEndpoint().contains('&page=1'),
                'The request should include page=1.'
            );

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);

            return response;
        }
    }

    @IsTest
    static void searchBooksShouldReturnEmptyListWhenSearchTermIsBlank() {
        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('   ');

        Test.stopTest();

        Assert.areEqual(
            0,
            results.size(),
            'Blank search term should return an empty list.'
        );
    }

    @IsTest
    static void searchBooksShouldReturnBooksWhenApiReturnsValidResponse() {
        String responseBody =
            '{' +
                '"docs":[' +
                    '{' +
                        '"title":"Clean Code",' +
                        '"author_name":["Robert C. Martin"]' +
                    '}' +
                ']' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(200, responseBody)
        );

        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('Clean Code');

        Test.stopTest();

        Assert.areEqual(
            1,
            results.size(),
            'One book should be returned.'
        );

        Assert.areEqual(
            'Clean Code',
            results[0].title,
            'The book title should match the API response.'
        );

        Assert.areEqual(
            'Robert C. Martin',
            results[0].author,
            'The author should be the first author from the API response.'
        );
    }

    @IsTest
    static void searchBooksShouldUseUnknownAuthorWhenAuthorNameIsMissing() {
        String responseBody =
            '{' +
                '"docs":[' +
                    '{' +
                        '"title":"Unknown Book"' +
                    '}' +
                ']' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(200, responseBody)
        );

        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('Unknown Book');

        Test.stopTest();

        Assert.areEqual(
            1,
            results.size(),
            'One book should be returned.'
        );

        Assert.areEqual(
            'Unknown Author',
            results[0].author,
            'Missing author_name should return Unknown Author.'
        );
    }

    @IsTest
    static void searchBooksShouldUseUnknownAuthorWhenAuthorNameIsEmpty() {
        String responseBody =
            '{' +
                '"docs":[' +
                    '{' +
                        '"title":"Book Without Author",' +
                        '"author_name":[]' +
                    '}' +
                ']' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(200, responseBody)
        );

        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('Book Without Author');

        Test.stopTest();

        Assert.areEqual(
            1,
            results.size(),
            'One book should be returned.'
        );

        Assert.areEqual(
            'Unknown Author',
            results[0].author,
            'Empty author_name should return Unknown Author.'
        );
    }

    @IsTest
    static void searchBooksShouldSkipBooksWithoutTitle() {
        String responseBody =
            '{' +
                '"docs":[' +
                    '{' +
                        '"title":"",' +
                        '"author_name":["No Title Author"]' +
                    '},' +
                    '{' +
                        '"title":"Valid Book",' +
                        '"author_name":["Valid Author"]' +
                    '}' +
                ']' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(200, responseBody)
        );

        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('Valid Book');

        Test.stopTest();

        Assert.areEqual(
            1,
            results.size(),
            'Books with blank titles should be skipped.'
        );

        Assert.areEqual(
            'Valid Book',
            results[0].title,
            'Only the valid book should be returned.'
        );

        Assert.areEqual(
            'Valid Author',
            results[0].author,
            'The valid book author should match.'
        );
    }

    @IsTest
    static void searchBooksShouldReturnEmptyListWhenDocsIsMissing() {
        String responseBody = '{}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(200, responseBody)
        );

        Test.startTest();

        List<OpenLibraryService.OpenLibraryBookResult> results =
            OpenLibraryService.searchBooks('Anything');

        Test.stopTest();

        Assert.areEqual(
            0,
            results.size(),
            'Missing docs should return an empty list.'
        );
    }

    @IsTest
    static void searchBooksShouldThrowCalloutExceptionWhenApiFails() {
        String responseBody =
            '{' +
                '"error":"Internal Server Error"' +
            '}';

        Test.setMock(
            HttpCalloutMock.class,
            new OpenLibraryMock(500, responseBody)
        );

        try {
            Test.startTest();

            OpenLibraryService.searchBooks('Clean Code');

            Test.stopTest();

            Assert.fail(
                'The method should throw a CalloutException.'
            );

        } catch (CalloutException excp) {
            Assert.areEqual(
                'Open Library API request failed.',
                excp.getMessage(),
                'The excp message should match.'
            );
        }
    }

    @IsTest
    static void openLibraryBookResultConstructorShouldAssignValues() {
        Test.startTest();

        OpenLibraryService.OpenLibraryBookResult result =
            new OpenLibraryService.OpenLibraryBookResult(
                'Clean Code',
                'Robert C. Martin'
            );

        Test.stopTest();

        Assert.areEqual(
            'Clean Code',
            result.title,
            'The title should be assigned.'
        );

        Assert.areEqual(
            'Robert C. Martin',
            result.author,
            'The author should be assigned.'
        );
    }
}