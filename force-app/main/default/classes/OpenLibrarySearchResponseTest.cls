@IsTest
private class OpenLibrarySearchResponseTest {

    @IsTest
    static void shouldDeserializeOpenLibraryResponse() {
        String responseBody =
            '{' +
                '"docs":[' +
                    '{' +
                        '"title":"Clean Code",' +
                        '"author_name":["Robert C. Martin"]' +
                    '},' +
                    '{' +
                        '"title":"Effective Apex",' +
                        '"author_name":["Salesforce Architect"]' +
                    '}' +
                ']' +
            '}';

        Test.startTest();

        OpenLibrarySearchResponse response =
            (OpenLibrarySearchResponse) JSON.deserialize(
                responseBody,
                OpenLibrarySearchResponse.class
            );

        Test.stopTest();

        Assert.isNotNull(
            response,
            'The response should be deserialized.'
        );

        Assert.isNotNull(
            response.docs,
            'The docs collection should not be null.'
        );

        Assert.areEqual(
            2,
            response.docs.size(),
            'The response should contain two books.'
        );

        Assert.areEqual(
            'Clean Code',
            response.docs[0].title,
            'The first book title should match.'
        );

        Assert.areEqual(
            'Robert C. Martin',
            response.docs[0].author_name[0],
            'The first book author should match.'
        );

        Assert.areEqual(
            'Effective Apex',
            response.docs[1].title,
            'The second book title should match.'
        );

        Assert.areEqual(
            'Salesforce Architect',
            response.docs[1].author_name[0],
            'The second book author should match.'
        );
    }

    @IsTest
    static void shouldHandleEmptyDocsCollection() {
        String responseBody =
            '{' +
                '"docs":[]' +
            '}';

        Test.startTest();

        OpenLibrarySearchResponse response =
            (OpenLibrarySearchResponse) JSON.deserialize(
                responseBody,
                OpenLibrarySearchResponse.class
            );

        Test.stopTest();

        Assert.isNotNull(
            response,
            'The response should be deserialized.'
        );

        Assert.isNotNull(
            response.docs,
            'The docs collection should not be null.'
        );

        Assert.areEqual(
            0,
            response.docs.size(),
            'The docs collection should be empty.'
        );
    }
}